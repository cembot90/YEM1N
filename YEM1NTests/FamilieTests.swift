import Foundation
import Testing
@testable import YEM1N

// Protokoll 2 ohne Gerät und ohne Netz: Rechnerei, Körper der Anfragen, Auswerten der Antworten,
// der Client mit einem falschen Dienst und die Eltern-PIN.
// Die Prüfwerte stammen aus cloud/testvektoren-v2.json, sie sind auch auf Android und im Worker geprüft.
// Dass der echte Schlüssel der Secure Enclave dieselben Unterschriften erzeugt, prüft FamilieKryptoTests.

// MARK: Hilfen für die Tests

/// Ein Schlüssel, der nur so tut: Die "Unterschrift" ist aus dem öffentlichen Teil und den Daten abgeleitet.
nonisolated struct FalscherSchluessel: GeraetSignierer {
    let pub: [UInt8]

    init(startwert: UInt8) { pub = [4] + (0..<64).map { UInt8(truncatingIfNeeded: Int($0) &* 7 &+ Int(startwert)) } }

    func oeffentlich() -> [UInt8]? { pub }
    func signieren(_ daten: [UInt8]) -> [UInt8]? { FalscherSchluessel.unterschrift(pub, daten) }

    static func unterschrift(_ pub: [UInt8], _ daten: [UInt8]) -> [UInt8] {
        Sha256.hash(pub + daten) + Sha256.hash(daten + pub)
    }
}

nonisolated struct OhneSchluessel: GeraetSignierer {
    func oeffentlich() -> [UInt8]? { nil }
    func signieren(_ daten: [UInt8]) -> [UInt8]? { nil }
}

/// Ein Dienst, der so prüft wie der Worker: Unterschrift, Gerät, Zeitfenster von 5 Minuten.
nonisolated final class FalscherDienst: FamilienLeitung, @unchecked Sendable {
    struct Aufruf: Sendable {
        var pfad: String
        var kopf: [String: String]
        var body: String
        var status: Int
    }

    private let schloss = NSLock()
    private var liste: [Aufruf] = []
    private var bekanntePub: [UInt8]?
    private var getrennt = false
    private let uhr: @Sendable () -> Int64

    init(uhr: @escaping @Sendable () -> Int64) { self.uhr = uhr }

    var aufrufe: [Aufruf] { schloss.lock(); defer { schloss.unlock() }; return liste }
    func offline(_ an: Bool) { schloss.lock(); getrennt = an; schloss.unlock() }

    func post(pfad: String, kopf: [String: String], body: String) async -> (status: Int, text: String) {
        bearbeite(pfad: pfad, kopf: kopf, body: body)
    }

    // Mit dem Schloss in einer gewöhnlichen Funktion, weil NSLock in async-Funktionen nicht erlaubt ist.
    private func bearbeite(pfad: String, kopf: [String: String], body: String) -> (status: Int, text: String) {
        schloss.lock(); defer { schloss.unlock() }
        if getrennt {
            liste.append(Aufruf(pfad: pfad, kopf: kopf, body: body, status: 0))
            return (0, "")
        }
        var status = 200
        var antwort = "{\"ok\":true}"
        if pfad == FamilienProtokoll.pfadFamilie || pfad == FamilienProtokoll.pfadKoppeln {
            if let o = FamilienJson.lies(body), let p = o["pub"] as? String {
                bekanntePub = FamilienKrypto.base64urlLesen(p)
            }
        } else {
            let zeit = Int64(kopf["Y-Zeit"] ?? "") ?? 0
            let pub = bekanntePub ?? []
            let text = FamilienKrypto.unterschriftText(methode: "POST", pfad: pfad,
                                                       familie: kopf["Y-Familie"] ?? "", geraet: kopf["Y-Geraet"] ?? "",
                                                       zeit: zeit, bodyHash: FamilienKrypto.sha256Hex(body))
            let sig = FamilienKrypto.base64urlLesen(kopf["Y-Signatur"] ?? "")
            let jetzt = uhr()
            if FamilienKrypto.geraetId(pub: pub) != kopf["Y-Geraet"] || sig != FalscherSchluessel.unterschrift(pub, Array(text.utf8)) {
                status = 401
                antwort = "{\"fehler\":\"Unterschrift passt nicht\"}"
            } else if abs(jetzt - zeit) > 5 * 60_000 {
                status = 401
                antwort = "{\"fehler\":\"Uhr\",\"serverZeit\":\(jetzt)}"
            }
        }
        liste.append(Aufruf(pfad: pfad, kopf: kopf, body: body, status: status))
        return (status, antwort)
    }
}

@MainActor
struct FamilieTests {
    let familie = String(repeating: "0123456789abcdef", count: 4)
    let token = "AbCdEfGhIjKlMnOpQrStUv"

    // MARK: SHA-256

    @Test func sha256StimmtMitDenBekanntenWerten() {
        #expect(Sha256.hex("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        #expect(Sha256.hex("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        // 56 Bytes: das Ende der Nachricht und die Länge brauchen einen zweiten Block
        #expect(Sha256.hex("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
                == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
        // 55, 63, 64 und 65 Bytes liegen genau an den Grenzen des Auffüllens
        for n in [55, 63, 64, 65, 119, 120] {
            #expect(Sha256.hash(String(repeating: "a", count: n)).count == 32)
        }
        #expect(Sha256.hex(String(repeating: "a", count: 64)) == "ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb")
    }

    // MARK: Rechnerei

    @Test func base64urlGehtHinUndZurueck() {
        #expect(FamilienKrypto.base64url([0xfb, 0xff]) == "-_8")
        #expect(FamilienKrypto.base64url([0x00, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff, 0x01, 0x02]) == "APr7_P3-_wEC")
        #expect(FamilienKrypto.base64urlLesen("-_8") == [0xfb, 0xff])
        #expect(FamilienKrypto.base64urlLesen("APr7_P3-_wEC") == [0x00, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff, 0x01, 0x02])
        #expect(FamilienKrypto.base64url([]) == "")
        #expect(FamilienKrypto.base64urlLesen("") == [])
        for n in 0..<40 {
            let bytes = (0..<n).map { UInt8(truncatingIfNeeded: $0 &* 37 &+ 11) }
            let text = FamilienKrypto.base64url(bytes)
            #expect(!text.contains("=") && !text.contains("+") && !text.contains("/"))
            #expect(FamilienKrypto.base64urlLesen(text) == bytes)
        }
    }

    @Test func base64urlLehntFalscheZeichenAb() {
        #expect(FamilienKrypto.base64urlLesen("a") == nil)
        #expect(FamilienKrypto.base64urlLesen("ab+/") == nil)
        #expect(FamilienKrypto.base64urlLesen("-_8=") == nil)
        #expect(FamilienKrypto.base64urlLesen("ab cd") == nil)
    }

    @Test func hexGehtHinUndZurueck() {
        #expect(FamilienKrypto.hex([0, 1, 254, 255]) == "0001feff")
        #expect(FamilienKrypto.hexLesen("0001FEff") == [0, 1, 254, 255])
        #expect(FamilienKrypto.hexLesen("abc") == nil)
        #expect(FamilienKrypto.hexLesen("zz") == nil)
    }

    // Die Werte stehen in cloud/testvektoren-v2.json
    let vektorPubHex = "040081857590c0c430c6f59614be4a0a63a07a1665292952113867b797678bd19bea560e16f31d4dd12a1fa2087995cd31ebeaf8ff3555795152cf4794d084628c"
    let vektorPub = "BACBhXWQwMQwxvWWFL5KCmOgehZlKSlSEThnt5dni9Gb6lYOFvMdTdEqH6IIeZXNMevq-P81VXlRUs9HlNCEYow"
    let vektorGeraet = "35880c633aaf87fd6ff9d04b"
    let vektorBody = "{\"typ\":\"frage\",\"daten\":{\"id\":\"frage-0001\",\"kind\":\"Yemin\",\"text\":\"Was ist 56 : 7?\"}}"
    let vektorHash = "99942f494cdb29c4ce98753fa2dffc82a1d40ea23b6311b29a23b0d10b2a7d1f"

    @Test func geraetKennungStimmtMitDemTestvektor() throws {
        let pub = try #require(FamilienKrypto.base64urlLesen(vektorPub))
        #expect(FamilienKrypto.hex(pub) == vektorPubHex)
        #expect(pub.count == 65 && pub[0] == 4)
        #expect(FamilienKrypto.geraetId(pub: pub) == vektorGeraet)
    }

    @Test func textZurUnterschriftStimmtMitDemTestvektor() {
        #expect(FamilienKrypto.sha256Hex(vektorBody) == vektorHash)
        let text = FamilienKrypto.unterschriftText(methode: "POST", pfad: "/v2/senden", familie: familie,
                                                   geraet: vektorGeraet, zeit: 1_800_000_000_000, bodyHash: vektorHash)
        #expect(text == "YEM1N-V2\nPOST\n/v2/senden\n\(familie)\n\(vektorGeraet)\n1800000000000\n\(vektorHash)")
        #expect(text.split(separator: "\n", omittingEmptySubsequences: false).count == 7)
    }

    // MARK: QR-Code

    @Test func qrCodeGehtHinUndZurueck() {
        let e = FamilienEinladung(familie: familie, rolle: "kind", token: token, bis: 1)
        #expect(e.qr == "yem1n://koppeln?f=\(familie)&t=\(token)")
        let gelesen = FamilienProtokoll.qrLesen(e.qr)
        #expect(gelesen?.familie == familie)
        #expect(gelesen?.token == token)
        let andereReihenfolge = FamilienProtokoll.qrLesen("  YEM1N://koppeln?t=\(token)&f=\(familie) \n")
        #expect(andereReihenfolge?.familie == familie)
        #expect(andereReihenfolge?.token == token)
    }

    @Test func kaputteQrCodesWerdenAbgelehnt() {
        #expect(FamilienProtokoll.qrLesen("yem1n://familie/ABCDE-FGHIJ") == nil)
        #expect(FamilienProtokoll.qrLesen("https://koppeln?f=\(familie)&t=\(token)") == nil)
        #expect(FamilienProtokoll.qrLesen("yem1n://koppeln?f=\(familie)") == nil)
        #expect(FamilienProtokoll.qrLesen("yem1n://koppeln?f=\(familie.prefix(63))&t=\(token)") == nil)
        #expect(FamilienProtokoll.qrLesen("yem1n://koppeln?f=\(familie.uppercased())&t=\(token)") == nil)
        #expect(FamilienProtokoll.qrLesen("yem1n://koppeln?f=\(familie)&t=kurz") == nil)
        #expect(FamilienProtokoll.qrLesen("yem1n://koppeln?f=\(familie)&t=\(token)%20x") == nil)
        #expect(FamilienProtokoll.qrLesen("") == nil)
    }

    @Test func pruefcodeIstDerAnfangDerKennung() {
        #expect(FamilienProtokoll.pruefcode(vektorGeraet) == "35880C")
        let z = FamilienZugang(familie: familie, geraet: vektorGeraet, name: "Yemin", rolle: "kind", status: "wartet")
        #expect(z.pruefcode == "35880C")
        #expect(z.wartet)
        #expect(!z.aktiv)
        #expect(!z.istEltern)
    }

    @Test func zugangBleibtBeimSpeichernGleich() throws {
        let z = FamilienZugang(familie: familie, geraet: vektorGeraet, name: "Mama", rolle: "eltern", status: "aktiv")
        let d = try JSONEncoder().encode(z)
        #expect(try JSONDecoder().decode(FamilienZugang.self, from: d) == z)
    }

    // MARK: Körper der Anfragen

    private func daten(_ o: [String: Any]) -> [String: Any] { o["daten"] as? [String: Any] ?? [:] }

    @Test func frageHatDasFormatDesDienstes() {
        let o = FamilienProtokoll.frage(id: "frage-0001", kind: " Yemin ", fach: "Mathe", uebung: "Geteilt", text: " Hilfe ")
        #expect(o["typ"] as? String == "frage")
        let d = daten(o)
        #expect(d["id"] as? String == "frage-0001")
        #expect(d["kind"] as? String == "Yemin")
        #expect(d["text"] as? String == "Hilfe")
        #expect(daten(FamilienProtokoll.frage(id: "frage-0002", kind: "", fach: "", uebung: "", text: "x"))["kind"] as? String == "Kind")
        let lang = daten(FamilienProtokoll.frage(id: "frage-0003", kind: "K", fach: "", uebung: "", text: String(repeating: "a", count: 900)))
        #expect((lang["text"] as? String)?.count == 500)
    }

    @Test func antwortDaumenNachschubFreigabe() {
        let a = daten(FamilienProtokoll.antwort(id: "antw-0001", frageId: "frage-0001", emoji: "👍", text: "Rechne 6 mal 7"))
        #expect(a["frageId"] as? String == "frage-0001")
        #expect(a["absender"] == nil) // den Namen setzt der Dienst
        let d = FamilienProtokoll.daumen(frageId: "frage-0001", antwortId: "antw-0001")
        #expect(d["typ"] as? String == "daumen")
        #expect(daten(d)["antwortId"] as? String == "antw-0001")
        #expect(FamilienProtokoll.nachschub(id: "nach-0001", kind: "Yemin")["typ"] as? String == "nachschub")
        #expect(daten(FamilienProtokoll.freigabe(id: "frei-0001", anzahl: 99))["anzahl"] as? Int == 10)
        #expect(daten(FamilienProtokoll.freigabe(id: "frei-0001", anzahl: 0))["anzahl"] as? Int == 1)
    }

    @Test func ergebnisWirdAufDieGrenzenDesDienstesGekuerzt() {
        let e = ErgebnisDaten(id: "erg-0001", klasse: String(repeating: "k", count: 60), fach: String(repeating: "f", count: 60),
                              arbeit: String(repeating: "a", count: 200), uebung: String(repeating: "u", count: 200),
                              richtig: 8, gesamt: 10, angesehen: 1, sterne: 7, kind: " Yemin ",
                              zeitpunkt: 1_800_000_000_000, details: String(repeating: "x", count: 25000))
        let d = daten(FamilienProtokoll.ergebnis(e))
        #expect((d["klasse"] as? String)?.count == 40)
        #expect((d["fach"] as? String)?.count == 40)
        #expect((d["arbeit"] as? String)?.count == 120)
        #expect((d["uebung"] as? String)?.count == 120)
        #expect(d["kind"] as? String == "Yemin")
        #expect(d["details"] == nil) // zu lang für den Dienst, lieber ohne Einzelheiten als gar nicht
        #expect(d["richtig"] as? Int == 8)
        #expect(d["sterne"] as? Int == 3)
        #expect(d["zeitpunkt"] as? Int64 == 1_800_000_000_000)
    }

    @Test func duellHaustierPflegePaketLesenPush() {
        #expect(daten(FamilienProtokoll.duell(id: "duell-0001", json: "{}"))["id"] as? String == "duell-0001")
        #expect(daten(FamilienProtokoll.duellAntwort(duellId: "duell-0001", json: "{}"))["duellId"] as? String == "duell-0001")
        #expect(daten(FamilienProtokoll.haustier(json: "{}"))["json"] as? String == "{}")
        #expect(daten(FamilienProtokoll.pflege(art: "leckerli", tag: "2026-10-26"))["tag"] as? String == "2026-10-26")
        #expect(daten(FamilienProtokoll.paket(id: "paket-0001", json: "{}"))["id"] as? String == "paket-0001")
        let l = FamilienProtokoll.lesen("frage", seit: 7, limit: 999)
        #expect(l["seit"] as? Int64 == 7)
        #expect(l["limit"] as? Int == 200)
        let p = FamilienProtokoll.pushAnmelden(token: "abcd", umgebung: "sandbox")
        #expect(p["art"] as? String == "apns")
        #expect(p["umgebung"] as? String == "sandbox")
        #expect(FamilienProtokoll.pushAbmelden()["art"] as? String == "")
    }

    @Test func textWirdSoGekuerztWieDerDienstZaehlt() {
        // Der Dienst zählt UTF-16-Einheiten: ein Emoji sind zwei.
        let emojis = String(repeating: "😀", count: 300)
        let k = FamilienProtokoll.kuerze(emojis, 500)
        #expect(k.utf16.count <= 500)
        #expect(k.count == 250)
        #expect(FamilienProtokoll.kuerze("Grüße aus Köln", 5) == "Grüße")
        // Steuerzeichen lehnt der Dienst ab, Zeilenumbruch und Tabulator nicht
        #expect(FamilienProtokoll.kuerze("a\u{0}b\u{7}c\nd\te", 20) == "abc\nd\te")
        let o = daten(FamilienProtokoll.frage(id: "frage-0004", kind: "K", fach: "", uebung: "", text: emojis))
        #expect((o["text"] as? String)?.utf16.count ?? 999 <= 500)
    }

    @Test func fehlerAusAntwortHatEinenFreundlichenText() throws {
        let gut = FamilienAntwort(status: 200, json: nil)
        try gut.pruefen()
        let schlecht = FamilienAntwort(status: 0, json: nil)
        #expect(throws: FamilienFehler.self) { try schlecht.pruefen() }
        let f = FamilienFehler(status: 429)
        #expect(f.text == FamilienProtokoll.fehlertext(429))
        #expect(f.localizedDescription == f.text)
    }

    @Test func kennungenSindFuerDenDienstGueltig() {
        for _ in 0..<20 { #expect(FamilienProtokoll.kennungOk(FamilienProtokoll.neueKennung("frage"))) }
        #expect(FamilienProtokoll.neueKennung(String(repeating: "x", count: 100)).count <= 64)
        #expect(!FamilienProtokoll.kennungOk("kurz"))
        #expect(!FamilienProtokoll.kennungOk("mit:Doppelpunkt"))
        #expect(FamilienProtokoll.neueKennung("a") != FamilienProtokoll.neueKennung("a"))
    }

    @Test func koerperSindGueltigesJsonUndImmerGleich() throws {
        let o = FamilienProtokoll.frage(id: "frage-0001", kind: "Yemin", fach: "Mathe", uebung: "Geteilt", text: "Was ist 56 : 7?")
        let t1 = FamilienJson.schreibe(o)
        let t2 = FamilienJson.schreibe(o)
        #expect(t1 == t2)
        #expect(!t1.contains("\\/"))
        let zurueck = try #require(FamilienJson.lies(t1))
        #expect(zurueck["typ"] as? String == "frage")
    }

    // MARK: Antworten auswerten

    let lesenAntwort = """
        {"ok":true,"letzte":9,"mehr":true,"eintraege":[
        {"nr":3,"typ":"frage","id":"frage-0001","von":"g1","absender":"Yemin","erstellt":1000,"daten":{"id":"frage-0001","kind":"Yemin","fach":"Mathe","uebung":"Geteilt","text":"Was ist 56 : 7?"}},
        {"nr":5,"typ":"frage","id":"frage-0002","von":"g1","absender":"Yemin","erstellt":3000,"daten":{"id":"frage-0002","kind":"Yemin","text":"Noch eine"}},
        {"nr":6,"typ":"antwort","id":"antw-0001","von":"g2","absender":"Mama","erstellt":2000,"daten":{"id":"antw-0001","frageId":"frage-0001","emoji":"😀","text":"8"}},
        {"nr":7,"typ":"daumen","id":"antw-0001","von":"g1","absender":"Yemin","erstellt":2500,"daten":{"frageId":"frage-0001","antwortId":"antw-0001"}},
        {"nr":8,"typ":"frage"},
        {"typ":"frage","id":"x","daten":{}}]}
        """

    @Test func eintraegeWerdenGelesenKaputteUebersprungen() throws {
        let antwort = try #require(FamilienJson.lies(lesenAntwort))
        let e = FamilienProtokoll.eintraege(antwort)
        #expect(e.count == 4)
        #expect(e[2].absender == "Mama")
        #expect(e[0].erstellt == 1000)
        #expect(e[0].text("fach") == "Mathe")
        #expect(e[0].text("gibtEsNicht", ersatz: "-") == "-")
        #expect(e[3].nr == 7)
        #expect(FamilienProtokoll.eintraege(["ok": true]).isEmpty)
    }

    @Test func weiterLesenNurWennNochMehrDa() throws {
        let antwort = try #require(FamilienJson.lies(lesenAntwort))
        #expect(FamilienProtokoll.weiterAb(antwort) == 9)
        let fertig = try #require(FamilienJson.lies("{\"ok\":true,\"letzte\":9,\"mehr\":false,\"eintraege\":[]}"))
        #expect(FamilienProtokoll.weiterAb(fertig) == nil)
    }

    @Test func geraeteListe() throws {
        let o = try #require(FamilienJson.lies("""
            {"ok":true,"geraete":[
            {"id":"aaaaaaaaaaaaaaaaaaaaaaaa","name":"Mama","rolle":"eltern","status":"aktiv","erstellt":1,"zuletzt":2,"ich":true},
            {"id":"bbbbbbbbbbbbbbbbbbbbbbbb","name":"Yemin","rolle":"kind","status":"wartet","erstellt":3,"zuletzt":3,"ich":false},
            {"name":"ohne id"}]}
            """))
        let l = FamilienProtokoll.geraete(o)
        #expect(l.count == 2)
        #expect(l[0].ich)
        #expect(l[1].pruefcode == "BBBBBB")
        #expect(l[1].status == "wartet")
    }

    @Test func fehlertexteSindFreundlichUndOhneGedankenstriche() {
        for s in [0, -1, -3, 400, 401, 403, 404, 409, 429, 500] {
            let t = FamilienProtokoll.fehlertext(s)
            #expect(!t.isEmpty)
            #expect(!t.contains("\u{2013}") && !t.contains("\u{2014}"))
        }
        #expect(FamilienProtokoll.fehlertext(500).contains("500"))
    }

    // MARK: Client mit falschem Dienst

    let jetzt: Int64 = 1_800_000_000_000

    private func zugang(_ pub: [UInt8]) -> FamilienZugang {
        FamilienZugang(familie: familie, geraet: FamilienKrypto.geraetId(pub: pub), name: "Mama", rolle: "eltern", status: "aktiv")
    }

    @Test func anlegenSendetSchluesselUndNameOhneUnterschrift() async throws {
        let schluessel = FalscherSchluessel(startwert: 3)
        let dienst = FalscherDienst(uhr: { 1_800_000_000_000 })
        let c = FamilienClient(leitung: dienst, signierer: schluessel, jetzt: { 1_800_000_000_000 })
        let a = await c.anlegen(name: "Mama")
        #expect(a.ok)
        let aufruf = try #require(dienst.aufrufe.first)
        #expect(aufruf.pfad == "/v2/familie")
        #expect(aufruf.kopf["Y-Signatur"] == nil)
        let o = try #require(FamilienJson.lies(aufruf.body))
        #expect(o["name"] as? String == "Mama")
        #expect(FamilienKrypto.base64urlLesen(o["pub"] as? String ?? "")?.count == 65)
    }

    @Test func koppelnSchicktDieFamilieImKopf() async throws {
        let dienst = FalscherDienst(uhr: { 1_800_000_000_000 })
        let c = FamilienClient(leitung: dienst, signierer: FalscherSchluessel(startwert: 5), jetzt: { 1_800_000_000_000 })
        _ = await c.koppeln(familie: familie, token: token, name: "Yemin")
        let aufruf = try #require(dienst.aufrufe.first)
        #expect(aufruf.kopf["Y-Familie"] == familie)
        #expect(FamilienJson.lies(aufruf.body)?["token"] as? String == token)
        #expect(FamilienJson.lies(aufruf.body)?["name"] as? String == "Yemin")
    }

    @Test func signierteAnfrageWirdVomDienstAkzeptiert() async throws {
        let schluessel = FalscherSchluessel(startwert: 9)
        let dienst = FalscherDienst(uhr: { 1_800_000_000_000 })
        let c = FamilienClient(leitung: dienst, signierer: schluessel, jetzt: { 1_800_000_000_000 })
        _ = await c.anlegen(name: "Mama")
        let z = zugang(schluessel.pub)
        let a = await c.signiert(z, pfad: FamilienProtokoll.pfadSenden,
                                 objekt: FamilienProtokoll.frage(id: "frage-0001", kind: "Yemin", fach: "Mathe", uebung: "Geteilt", text: "Was ist 56 : 7?"))
        #expect(a.ok)
        let k = try #require(dienst.aufrufe.last).kopf
        #expect(k["Y-Familie"] == familie)
        #expect(k["Y-Geraet"] == z.geraet)
        #expect(k["Y-Zeit"] == String(jetzt))
        #expect(k["Content-Type"] == "application/json")
        #expect(FamilienKrypto.base64urlLesen(k["Y-Signatur"] ?? "")?.count == 64)
    }

    @Test func leererKoerperIstEinLeeresObjekt() async throws {
        let schluessel = FalscherSchluessel(startwert: 9)
        let dienst = FalscherDienst(uhr: { 1_800_000_000_000 })
        let c = FamilienClient(leitung: dienst, signierer: schluessel, jetzt: { 1_800_000_000_000 })
        _ = await c.anlegen(name: "Mama")
        let a = await c.signiert(zugang(schluessel.pub), pfad: FamilienProtokoll.pfadGeraete)
        #expect(a.ok)
        #expect(try #require(dienst.aufrufe.last).body == "{}")
    }

    @Test func unbekanntesGeraetWirdAbgelehntUndNichtWiederholt() async {
        let dienst = FalscherDienst(uhr: { 1_800_000_000_000 })
        let c = FamilienClient(leitung: dienst, signierer: FalscherSchluessel(startwert: 1), jetzt: { 1_800_000_000_000 })
        _ = await c.anlegen(name: "Mama")
        // ein anderes Gerät mit falscher Kennung
        let fremd = FamilienZugang(familie: familie, geraet: "ffffffffffffffffffffffff", name: "?", rolle: "kind", status: "aktiv")
        let a = await c.signiert(fremd, pfad: FamilienProtokoll.pfadLesen, body: "{}")
        #expect(a.status == 401)
        #expect(dienst.aufrufe.count == 2) // anlegen und ein Versuch, kein zweiter
    }

    @Test func falscheUhrWirdAusgeglichenUndMerkt() async throws {
        let schluessel = FalscherSchluessel(startwert: 2)
        let dienst = FalscherDienst(uhr: { 1_800_000_000_000 })
        // Die Uhr des Geräts geht eine Stunde nach
        let c = FamilienClient(leitung: dienst, signierer: schluessel, jetzt: { 1_800_000_000_000 - 3_600_000 })
        _ = await c.anlegen(name: "Mama")
        let z = zugang(schluessel.pub)
        let a = await c.signiert(z, pfad: FamilienProtokoll.pfadLesen, body: "{}")
        #expect(a.ok)
        #expect(await c.versatz == 3_600_000)
        let anfragen = dienst.aufrufe.filter { $0.pfad == "/v2/lesen" }
        #expect(anfragen.count == 2)
        #expect(anfragen[0].status == 401)
        #expect(anfragen[1].status == 200)
        // Beim nächsten Mal stimmt die Zeit gleich
        let b = await c.signiert(z, pfad: FamilienProtokoll.pfadLesen, body: "{}")
        #expect(b.ok)
        #expect(dienst.aufrufe.filter { $0.pfad == "/v2/lesen" }.count == 3)
    }

    @Test func keineVerbindungIstStatusNull() async {
        let schluessel = FalscherSchluessel(startwert: 4)
        let dienst = FalscherDienst(uhr: { 1_800_000_000_000 })
        let c = FamilienClient(leitung: dienst, signierer: schluessel, jetzt: { 1_800_000_000_000 })
        _ = await c.anlegen(name: "Mama")
        dienst.offline(true)
        let a = await c.signiert(zugang(schluessel.pub), pfad: FamilienProtokoll.pfadLesen, body: "{}")
        #expect(a.keineVerbindung)
        #expect(!a.ok)
        #expect(a.fehler.contains("Verbindung"))
    }

    @Test func ohneSchluesselGehtNichtsRaus() async {
        let dienst = FalscherDienst(uhr: { 1_800_000_000_000 })
        let c = FamilienClient(leitung: dienst, signierer: OhneSchluessel(), jetzt: { 1_800_000_000_000 })
        let a = await c.anlegen(name: "Mama")
        let b = await c.koppeln(familie: familie, token: token, name: "Yemin")
        let s = await c.signiert(FamilienZugang(familie: familie, geraet: vektorGeraet, name: "x", rolle: "kind", status: "aktiv"),
                                 pfad: FamilienProtokoll.pfadLesen, body: "{}")
        #expect(a.status == -1 && b.status == -1 && s.status == -1)
        #expect(dienst.aufrufe.isEmpty)
    }

    // MARK: Eltern-PIN

    @Test func pinNurZiffernVierBisAcht() {
        #expect(ElternPin.gueltig("4821"))
        #expect(ElternPin.gueltig("48213579"))
        #expect(!ElternPin.gueltig("482"))
        #expect(!ElternPin.gueltig("482135791"))
        #expect(!ElternPin.gueltig("48a1"))
        #expect(!ElternPin.gueltig(""))
    }

    @Test func leichtePinsWerdenErkannt() {
        #expect(ElternPin.zuLeicht("0000"))
        #expect(ElternPin.zuLeicht("1234"))
        #expect(ElternPin.zuLeicht("98765"))
        #expect(ElternPin.zuLeicht("123"))
        #expect(!ElternPin.zuLeicht("4821"))
        #expect(!ElternPin.zuLeicht("1357"))
    }

    @Test func pinHashPasstNurZurRichtigenPin() {
        let salz = ElternPin.salz((0..<16).map { UInt8($0) })
        #expect(salz == "000102030405060708090a0b0c0d0e0f")
        let h = ElternPin.hash("4821", salz: salz)
        // Gleiche Rechnung in Python (hashlib) nachgerechnet
        #expect(h == "14ce70f923528e030b8eda3cfe551488164e396dcf361d55a08c7434962dba31")
        #expect(ElternPin.stimmt("4821", salz: salz, hash: h))
        #expect(!ElternPin.stimmt("4822", salz: salz, hash: h))
        #expect(!ElternPin.stimmt("4821", salz: "anderes", hash: h))
        #expect(!ElternPin.stimmt("4821", salz: "", hash: h))
        #expect(!ElternPin.stimmt("4821", salz: salz, hash: ""))
        #expect(!ElternPin.stimmt("4821", salz: salz, hash: String(h.dropLast())))
    }

    @Test func anderesSalzGibtAnderenHash() {
        let a = ElternPin.salz([UInt8](repeating: 1, count: 16))
        let b = ElternPin.salz([UInt8](repeating: 2, count: 16))
        #expect(ElternPin.hash("4821", salz: a) != ElternPin.hash("4821", salz: b))
        #expect(ElternPin.hash("4821", salz: a) == ElternPin.hash("4821", salz: a))
    }

    @Test func wartezeitWaechstMitFehlversuchen() {
        #expect(ElternPin.sperreSekunden(0) == 0)
        #expect(ElternPin.sperreSekunden(2) == 0)
        #expect(ElternPin.sperreSekunden(3) == 30)
        #expect(ElternPin.sperreSekunden(4) == 60)
        #expect(ElternPin.sperreSekunden(5) == 300)
        #expect(ElternPin.sperreSekunden(6) == 900)
        #expect(ElternPin.sperreSekunden(50) == 900)
    }

    @Test func wartezeitText() {
        #expect(ElternPin.sperreText(30) == "Bitte noch 30 Sekunden warten.")
        #expect(ElternPin.sperreText(0.2) == "Bitte noch 1 Sekunde warten.")
        #expect(ElternPin.sperreText(300) == "Bitte noch 5 Minuten warten.")
        #expect(!ElternPin.sperreText(30).contains("\u{2014}"))
    }
}
