import Foundation

// ============================================================
// MARK: - Protokoll 2: so sprechen die Apps mit dem Familien-Dienst
// ============================================================
//
// Beschrieben in cloud/PROTOKOLL-V2.md. Diese Datei braucht nur Foundation, damit sie sich
// ohne Oberfläche und ohne Gerät prüfen lässt (pruefen/linux-tests.sh). Der Schlüssel des Geräts
// und das Netz stecken hinter kleinen Schnittstellen und liegen in eigenen Dateien.

/// Base64 in der URL-sicheren Form ohne Füllzeichen, hex und die Gerätekennung.
nonisolated enum FamilienKrypto {
    static func base64url(_ bytes: [UInt8]) -> String {
        var s = Data(bytes).base64EncodedString()
        s = s.replacingOccurrences(of: "+", with: "-")
        s = s.replacingOccurrences(of: "/", with: "_")
        while s.hasSuffix("=") { s.removeLast() }
        return s
    }

    static func base64urlLesen(_ text: String) -> [UInt8]? {
        // Nur die Zeichen der URL-sicheren Form, keine Füllzeichen und keine Zeichen der normalen Form.
        if text.isEmpty { return [] }
        let erlaubt = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        guard text.allSatisfy({ erlaubt.contains($0) }), text.count % 4 != 1 else { return nil }
        var s = text.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s += "=" }
        guard let d = Data(base64Encoded: s) else { return nil }
        return [UInt8](d)
    }

    static func hex(_ bytes: [UInt8]) -> String { Sha256.hex(bytes) }

    static func hexLesen(_ text: String) -> [UInt8]? {
        let zeichen = Array(text.utf8)
        guard zeichen.count % 2 == 0 else { return nil }
        func wert(_ c: UInt8) -> UInt8? {
            switch c {
            case 48...57: return c - 48
            case 97...102: return c - 87
            case 65...70: return c - 55
            default: return nil
            }
        }
        var aus: [UInt8] = []
        var i = 0
        while i < zeichen.count {
            guard let hoch = wert(zeichen[i]), let tief = wert(zeichen[i + 1]) else { return nil }
            aus.append(hoch << 4 | tief)
            i += 2
        }
        return aus
    }

    static func sha256Hex(_ text: String) -> String { Sha256.hex(text) }

    /// Die ersten 24 Hex-Zeichen von SHA-256 über die 65 Bytes des öffentlichen Schlüssels.
    static func geraetId(pub: [UInt8]) -> String {
        String(Sha256.hex(Sha256.hash(pub)).prefix(24))
    }

    /// Der Text, den das Gerät unterschreibt: sieben Zeilen, getrennt durch Zeilenumbrüche.
    static func unterschriftText(methode: String, pfad: String, familie: String, geraet: String,
                                 zeit: Int64, bodyHash: String) -> String {
        ["YEM1N-V2", methode, pfad, familie, geraet, String(zeit), bodyHash].joined(separator: "\n")
    }
}

/// JSON schreiben und lesen. Beim Schreiben sind die Schlüssel sortiert, der Text ist immer derselbe.
nonisolated enum FamilienJson {
    static func schreibe(_ objekt: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(objekt),
              let d = try? JSONSerialization.data(withJSONObject: objekt,
                                                  options: [.sortedKeys, .withoutEscapingSlashes]) else { return "{}" }
        return String(decoding: d, as: UTF8.self)
    }

    static func lies(_ text: String) -> [String: Any]? {
        guard let d = text.data(using: .utf8),
              let o = try? JSONSerialization.jsonObject(with: d) else { return nil }
        return o as? [String: Any]
    }

    static func zahl(_ wert: Any?) -> Int64? {
        if let i = wert as? Int { return Int64(i) }
        if let i = wert as? Int64 { return i }
        if let d = wert as? Double { return Int64(d) }
        if let n = wert as? NSNumber { return n.int64Value }
        return nil
    }

    static func wort(_ wert: Any?) -> String? { wert as? String }
}

/// Was dieses Gerät über seine Familie weiß. Der private Schlüssel liegt nicht hier, sondern im Gerät (Secure Enclave).
nonisolated struct FamilienZugang: Codable, Equatable, Sendable {
    var familie: String
    var geraet: String
    var name: String
    /// "eltern" oder "kind", bestimmt durch die Einladung.
    var rolle: String
    /// "aktiv", "wartet" (auf die Freigabe der Eltern) oder "abgelehnt".
    var status: String

    var aktiv: Bool { status == "aktiv" }
    var wartet: Bool { status == "wartet" }
    var istEltern: Bool { rolle == "eltern" }

    /// Kurzer Prüfcode, den das neue Gerät und die Liste der Eltern gleich anzeigen, damit man das richtige Gerät erlaubt.
    var pruefcode: String { FamilienProtokoll.pruefcode(geraet) }
}

/// Ein Eintrag aus `/v2/lesen`. [id] ist die Kennung der Sache (Frage, Antwort ...), [von] das Gerät, das ihn angelegt hat.
nonisolated struct FamilienEintrag: @unchecked Sendable {
    var nr: Int64
    var typ: String
    var id: String
    var von: String
    var absender: String
    /// Millisekunden seit 1970
    var erstellt: Int64
    var daten: [String: Any]

    func text(_ k: String, ersatz: String = "") -> String { FamilienJson.wort(daten[k]) ?? ersatz }
    func zahl(_ k: String) -> Int64 { FamilienJson.zahl(daten[k]) ?? 0 }
    var erstelltDatum: Date { Date(timeIntervalSince1970: Double(erstellt) / 1000) }
}

/// Ein Gerät in der Liste der Eltern (`/v2/geraete`).
nonisolated struct FamilienGeraet: Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var rolle: String
    var status: String
    var erstellt: Int64
    var zuletzt: Int64
    var ich: Bool

    var pruefcode: String { FamilienProtokoll.pruefcode(id) }
}

/// Eine frische Einladung, die als QR-Code gezeigt wird. [bis] ist die Ablaufzeit in Millisekunden.
nonisolated struct FamilienEinladung: Equatable, Sendable {
    var familie: String
    var rolle: String
    var token: String
    var bis: Int64

    var qr: String { FamilienProtokoll.qrInhalt(familie: familie, token: token) }
}

/// Die Daten einer Runde, so wie der Dienst sie als Ergebnis nimmt.
nonisolated struct ErgebnisDaten: Sendable {
    var id: String
    var klasse: String
    var fach: String
    var arbeit: String
    var uebung: String
    var richtig: Int
    var gesamt: Int
    var angesehen: Int
    var sterne: Int
    var kind: String
    /// Millisekunden seit 1970
    var zeitpunkt: Int64
    var details: String
}

nonisolated enum FamilienProtokoll {
    static let pfadFamilie = "/v2/familie"
    static let pfadKoppeln = "/v2/koppeln"
    static let pfadStatus = "/v2/status"
    static let pfadPush = "/v2/push"
    static let pfadSenden = "/v2/senden"
    static let pfadLesen = "/v2/lesen"
    static let pfadEinladung = "/v2/einladung"
    static let pfadGeraete = "/v2/geraete"
    static let pfadErlauben = "/v2/geraet/erlauben"
    static let pfadAblehnen = "/v2/geraet/ablehnen"
    static let pfadEntfernen = "/v2/geraet/entfernen"
    static let pfadAustreten = "/v2/geraet/austreten"
    static let pfadLoeschen = "/v2/familie/loeschen"
    static let pfadPing = "/v2/ping"

    static let typFrage = "frage"
    static let typAntwort = "antwort"
    static let typDaumen = "daumen"
    static let typNachschub = "nachschub"
    static let typFreigabe = "freigabe"
    static let typErgebnis = "ergebnis"
    static let typDuell = "duell"
    static let typDuellAntwort = "duellantwort"
    static let typHaustier = "haustier"
    static let typPflege = "pflege"
    static let typPaket = "paket"

    // MARK: Prüfen von Texten

    private static func hexKlein(_ c: Character) -> Bool {
        ("0"..."9").contains(c) || ("a"..."f").contains(c)
    }

    private static func kennungZeichen(_ c: Character) -> Bool {
        ("0"..."9").contains(c) || ("a"..."z").contains(c) || ("A"..."Z").contains(c) || c == "_" || c == "-"
    }

    static func familieOk(_ t: String) -> Bool { t.count == 64 && t.allSatisfy(hexKlein) }
    static func tokenOk(_ t: String) -> Bool { (16...64).contains(t.count) && t.allSatisfy(kennungZeichen) }
    static func kennungOk(_ t: String) -> Bool { (6...64).contains(t.count) && t.allSatisfy(kennungZeichen) }

    // MARK: QR-Code zum Koppeln

    static func qrInhalt(familie: String, token: String) -> String {
        "yem1n://koppeln?f=\(familie)&t=\(token)"
    }

    /// Gibt Familie und Einmal-Schlüssel aus einem gescannten Text zurück, sonst nil.
    static func qrLesen(_ text: String) -> (familie: String, token: String)? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let vorsatz = "yem1n://koppeln?"
        guard t.lowercased().hasPrefix(vorsatz) else { return nil }
        var familie: String?
        var token: String?
        for teil in t.dropFirst(vorsatz.count).split(separator: "&", omittingEmptySubsequences: true) {
            guard let i = teil.firstIndex(of: "=") else { continue }
            let schluessel = String(teil[teil.startIndex..<i])
            let wert = String(teil[teil.index(after: i)...])
            if schluessel == "f" { familie = wert }
            if schluessel == "t" { token = wert }
        }
        guard let f = familie, let k = token, familieOk(f), tokenOk(k) else { return nil }
        return (f, k)
    }

    /// Sechs Zeichen aus der Gerätekennung, groß geschrieben. Beide Geräte zeigen dasselbe, damit die Eltern das richtige erlauben.
    static func pruefcode(_ geraet: String) -> String { String(geraet.prefix(6)).uppercased() }

    // MARK: Kennungen

    /// Neue Kennung für eine Frage, Antwort und so weiter. Der Dienst erlaubt 6 bis 64 Zeichen aus A-Z, a-z, 0-9, _ und -.
    static func neueKennung(_ vorsatz: String) -> String {
        let zufall = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return String((vorsatz + "-" + zufall).prefix(64))
    }

    // MARK: Körper der Anfragen

    private static func senden(_ typ: String, _ daten: [String: Any]) -> [String: Any] {
        ["typ": typ, "daten": daten]
    }

    private static func kurz(_ text: String, _ max: Int) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(max))
    }

    static func frage(id: String, kind: String, fach: String, uebung: String, text: String) -> [String: Any] {
        let name = kurz(kind, 40)
        return senden(typFrage, [
            "id": id,
            "kind": name.isEmpty ? "Kind" : name,
            "fach": String(fach.prefix(40)),
            "uebung": String(uebung.prefix(80)),
            "text": kurz(text, 500),
        ])
    }

    static func antwort(id: String, frageId: String, emoji: String, text: String) -> [String: Any] {
        senden(typAntwort, [
            "id": id,
            "frageId": frageId,
            "emoji": String(emoji.prefix(16)),
            "text": kurz(text, 500),
        ])
    }

    static func daumen(frageId: String, antwortId: String) -> [String: Any] {
        senden(typDaumen, ["frageId": frageId, "antwortId": antwortId])
    }

    static func nachschub(id: String, kind: String) -> [String: Any] {
        let name = kurz(kind, 40)
        return senden(typNachschub, ["id": id, "kind": name.isEmpty ? "Kind" : name])
    }

    static func freigabe(id: String, anzahl: Int = 3) -> [String: Any] {
        senden(typFreigabe, ["id": id, "anzahl": min(max(anzahl, 1), 10)])
    }

    static func ergebnis(_ e: ErgebnisDaten) -> [String: Any] {
        var d: [String: Any] = [
            "id": e.id,
            "klasse": String(e.klasse.prefix(40)),
            "fach": String(e.fach.prefix(40)),
            "arbeit": String(e.arbeit.prefix(120)),
            "uebung": String(e.uebung.prefix(120)),
            "richtig": min(max(e.richtig, 0), 1000),
            "gesamt": min(max(e.gesamt, 0), 1000),
            "angesehen": min(max(e.angesehen, 0), 1000),
            "sterne": min(max(e.sterne, 0), 3),
            "kind": kurz(e.kind, 40),
            "zeitpunkt": e.zeitpunkt,
        ]
        if !e.details.isEmpty && e.details.count <= 20000 { d["details"] = e.details }
        return senden(typErgebnis, d)
    }

    static func duell(id: String, json: String) -> [String: Any] {
        senden(typDuell, ["id": id, "json": json])
    }

    static func duellAntwort(duellId: String, json: String) -> [String: Any] {
        senden(typDuellAntwort, ["duellId": duellId, "json": json])
    }

    static func haustier(json: String) -> [String: Any] {
        senden(typHaustier, ["json": json])
    }

    /// [tag] im Format JJJJ-MM-TT, [art] "leckerli" oder "spielen".
    static func pflege(art: String, tag: String) -> [String: Any] {
        senden(typPflege, ["art": art, "tag": tag])
    }

    static func paket(id: String, json: String) -> [String: Any] {
        senden(typPaket, ["id": id, "json": json])
    }

    static func lesen(_ typ: String, seit: Int64 = 0, limit: Int = 100) -> [String: Any] {
        ["typ": typ, "seit": seit, "limit": min(max(limit, 1), 200)]
    }

    /// Meldet die Push-Kennung dieses Geräts an. [umgebung] ist "sandbox" oder "production".
    static func pushAnmelden(token: String, umgebung: String) -> [String: Any] {
        ["art": "apns", "token": token, "umgebung": umgebung]
    }

    static func pushAbmelden() -> [String: Any] { ["art": ""] }

    // MARK: Antworten lesen

    /// Die Einträge aus der Antwort von `/v2/lesen`. Kaputte Einträge werden übersprungen.
    static func eintraege(_ antwort: [String: Any]) -> [FamilienEintrag] {
        guard let liste = antwort["eintraege"] as? [Any] else { return [] }
        var aus: [FamilienEintrag] = []
        for el in liste {
            guard let o = el as? [String: Any],
                  let nr = FamilienJson.zahl(o["nr"]),
                  let typ = FamilienJson.wort(o["typ"]),
                  let id = FamilienJson.wort(o["id"]),
                  let daten = o["daten"] as? [String: Any] else { continue }
            aus.append(FamilienEintrag(nr: nr, typ: typ, id: id,
                                       von: FamilienJson.wort(o["von"]) ?? "",
                                       absender: FamilienJson.wort(o["absender"]) ?? "",
                                       erstellt: FamilienJson.zahl(o["erstellt"]) ?? 0,
                                       daten: daten))
        }
        return aus
    }

    /// Ab welcher Nummer noch mehr zu holen ist, oder nil, wenn alles geholt ist.
    static func weiterAb(_ antwort: [String: Any]) -> Int64? {
        guard (antwort["mehr"] as? Bool) == true else { return nil }
        return FamilienJson.zahl(antwort["letzte"])
    }

    static func geraete(_ antwort: [String: Any]) -> [FamilienGeraet] {
        guard let liste = antwort["geraete"] as? [Any] else { return [] }
        var aus: [FamilienGeraet] = []
        for el in liste {
            guard let o = el as? [String: Any], let id = FamilienJson.wort(o["id"]) else { continue }
            aus.append(FamilienGeraet(id: id,
                                      name: FamilienJson.wort(o["name"]) ?? "",
                                      rolle: FamilienJson.wort(o["rolle"]) ?? "kind",
                                      status: FamilienJson.wort(o["status"]) ?? "wartet",
                                      erstellt: FamilienJson.zahl(o["erstellt"]) ?? 0,
                                      zuletzt: FamilienJson.zahl(o["zuletzt"]) ?? 0,
                                      ich: (o["ich"] as? Bool) == true))
        }
        return aus
    }

    // MARK: Fehlertexte

    /// Ein Satz für Kinder und Eltern. [status] 0 heißt: keine Verbindung, -1: der Schlüssel fehlt, -3: keine Familie.
    static func fehlertext(_ status: Int) -> String {
        switch status {
        case 0: return "Keine Verbindung. Ist das Internet an?"
        case -1: return "Dieses Gerät kann keinen Schlüssel anlegen oder lesen."
        case -3: return "Dieses Gerät gehört noch nicht zu einer Familie."
        case 400: return "Das konnte nicht gesendet werden. Bitte den Text prüfen."
        case 401: return "Die Familie kennt dieses Gerät nicht (mehr). Bitte neu verbinden. Auch eine falsche Uhrzeit kann das auslösen."
        case 403: return "Das darf dieses Gerät nicht, oder die Einladung gilt nicht mehr."
        case 404: return "Diese Familie gibt es nicht (mehr)."
        case 409: return "Das geht gerade nicht. Vielleicht ist das Gerät schon in der Familie oder die Familie ist voll."
        case 429: return "Das ging zu schnell. Bitte kurz warten."
        default: return "Der Dienst hat nicht geantwortet (Code \(status))."
        }
    }
}
