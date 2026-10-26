import Foundation

// ============================================================
// MARK: - Protokoll 2: der Client
// ============================================================
//
// Unterschreibt jede Anfrage mit dem Schlüssel des Geräts und gleicht eine falsch gehende Uhr aus.
// Reine Logik ohne Oberfläche. Der Schlüssel (Secure Enclave) und das Netz (URLSession) stecken
// hinter zwei kleinen Schnittstellen und liegen in eigenen Dateien. So lässt sich alles ohne Gerät testen.

/// Die Antwort des Dienstes. [status] 0 heißt: keine Verbindung, -1: der Schlüssel dieses Geräts fehlt,
/// -3: das Gerät gehört zu keiner Familie.
nonisolated struct FamilienAntwort: @unchecked Sendable {
    var status: Int
    var json: [String: Any]?

    var ok: Bool { (200...299).contains(status) }
    var keineVerbindung: Bool { status == 0 }
    func text(_ k: String) -> String { FamilienJson.wort(json?[k]) ?? "" }
    func zahl(_ k: String) -> Int64 { FamilienJson.zahl(json?[k]) ?? 0 }
    var fehler: String { FamilienProtokoll.fehlertext(status) }
}

/// Ein Fehler vom Familien-Dienst, der als Text für Kinder und Eltern taugt.
nonisolated struct FamilienFehler: Error, LocalizedError, Sendable {
    let status: Int
    var text: String { FamilienProtokoll.fehlertext(status) }
    var errorDescription: String? { text }
}

extension FamilienAntwort {
    /// Wirft einen [FamilienFehler], wenn die Antwort nicht gut war.
    func pruefen() throws {
        if !ok { throw FamilienFehler(status: status) }
    }
}

/// Die Leitung zum Dienst. Liefert Status und Text der Antwort, Status 0 ohne Verbindung.
nonisolated protocol FamilienLeitung: Sendable {
    func post(pfad: String, kopf: [String: String], body: String) async -> (status: Int, text: String)
}

/// Der Schlüssel dieses Geräts. Auf dem iPhone liegt er in der Secure Enclave und verlässt das Gerät nie.
nonisolated protocol GeraetSignierer: Sendable {
    /// Die 65 Bytes des öffentlichen Schlüssels (`04 X Y`), oder nil, wenn es (noch) keinen gibt.
    func oeffentlich() -> [UInt8]?

    /// Unterschreibt mit ECDSA über SHA-256. Das Ergebnis sind die 64 Bytes `r` und `s` hintereinander,
    /// so wie CryptoKit sie liefert und der Dienst sie erwartet.
    func signieren(_ daten: [UInt8]) -> [UInt8]?
}

/// Spricht Protokoll 2 (`cloud/PROTOKOLL-V2.md`).
actor FamilienClient {
    private let leitung: FamilienLeitung
    private let signierer: GeraetSignierer
    private let jetzt: @Sendable () -> Int64

    /// Unterschied zwischen der Uhr des Dienstes und der dieses Geräts in Millisekunden.
    private(set) var versatz: Int64 = 0

    init(leitung: FamilienLeitung,
         signierer: GeraetSignierer,
         jetzt: @escaping @Sendable () -> Int64 = { Int64(Date().timeIntervalSince1970 * 1000) }) {
        self.leitung = leitung
        self.signierer = signierer
        self.jetzt = jetzt
    }

    /// Setzt den gemerkten Zeitunterschied, zum Beispiel aus dem letzten Start.
    func versatzSetzen(_ wert: Int64) { versatz = wert }

    private func roh(_ pfad: String, _ kopf: [String: String], _ body: String) async -> FamilienAntwort {
        var k = kopf
        k["Content-Type"] = "application/json"
        let (status, text) = await leitung.post(pfad: pfad, kopf: k, body: body)
        return FamilienAntwort(status: status, json: FamilienJson.lies(text))
    }

    /// Legt eine neue Familie an. Dieses Gerät wird das erste Eltern-Gerät.
    func anlegen(name: String) async -> FamilienAntwort {
        guard let pub = signierer.oeffentlich() else { return FamilienAntwort(status: -1, json: nil) }
        let body = FamilienJson.schreibe(["pub": FamilienKrypto.base64url(pub), "name": name])
        return await roh(FamilienProtokoll.pfadFamilie, [:], body)
    }

    /// Meldet dieses Gerät mit dem Einmal-Schlüssel aus dem QR-Code. Es wartet danach auf die Freigabe der Eltern.
    func koppeln(familie: String, token: String, name: String) async -> FamilienAntwort {
        guard let pub = signierer.oeffentlich() else { return FamilienAntwort(status: -1, json: nil) }
        let body = FamilienJson.schreibe(["token": token, "pub": FamilienKrypto.base64url(pub), "name": name])
        return await roh(FamilienProtokoll.pfadKoppeln, ["Y-Familie": familie], body)
    }

    /// Eine unterschriebene Anfrage. [body] ist schon fertiger JSON-Text, genau dieser Text wird gehasht und gesendet.
    /// Ist die Uhr des Geräts falsch, gleicht der Client sie aus und versucht es einmal neu.
    func signiert(_ zugang: FamilienZugang, pfad: String, body: String = "{}") async -> FamilienAntwort {
        let bodyHash = FamilienKrypto.sha256Hex(body)
        var antwort = FamilienAntwort(status: -1, json: nil)
        for versuch in 0...1 {
            let zeit = jetzt() + versatz
            let text = FamilienKrypto.unterschriftText(methode: "POST", pfad: pfad, familie: zugang.familie,
                                                       geraet: zugang.geraet, zeit: zeit, bodyHash: bodyHash)
            guard let sig = signierer.signieren(Array(text.utf8)), sig.count == 64 else {
                return FamilienAntwort(status: -1, json: nil)
            }
            antwort = await roh(pfad, [
                "Y-Familie": zugang.familie,
                "Y-Geraet": zugang.geraet,
                "Y-Zeit": String(zeit),
                "Y-Signatur": FamilienKrypto.base64url(sig),
            ], body)
            if antwort.status != 401 || versuch == 1 { break }
            guard let serverZeit = FamilienJson.zahl(antwort.json?["serverZeit"]) else { break }
            // Nur nachstellen, wenn die Uhr wirklich abweicht. Sonst liegt es an etwas anderem und ein zweiter Versuch hilft nicht.
            if abs(serverZeit - zeit) < 30_000 { break }
            versatz = serverZeit - jetzt()
        }
        return antwort
    }

    /// Wie [signiert], nimmt aber ein Wörterbuch, wie es `FamilienProtokoll` baut.
    func signiert(_ zugang: FamilienZugang, pfad: String, objekt: [String: Any]) async -> FamilienAntwort {
        await signiert(zugang, pfad: pfad, body: FamilienJson.schreibe(objekt))
    }
}
