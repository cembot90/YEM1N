import Foundation
import CryptoKit
import Testing
@testable import YEM1N

// Die echte Kryptografie des iPhones gegen die Prüfwerte aus cloud/testvektoren-v2.json:
// Der Worker (Web Crypto) und Android (Java) prüfen dieselben Werte. Stimmt hier etwas nicht,
// lehnt der Familien-Dienst jede Anfrage dieses iPhones ab.

nonisolated struct Vektor {
    static let pub = "BACBhXWQwMQwxvWWFL5KCmOgehZlKSlSEThnt5dni9Gb6lYOFvMdTdEqH6IIeZXNMevq-P81VXlRUs9HlNCEYow"
    static let familie = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    static let geraet = "35880c633aaf87fd6ff9d04b"
    static let bodyHash = "99942f494cdb29c4ce98753fa2dffc82a1d40ea23b6311b29a23b0d10b2a7d1f"
    static let nachricht = "YEM1N-V2\nPOST\n/v2/senden\n\(familie)\n\(geraet)\n1800000000000\n\(bodyHash)"
    static let signatur = "jKEu-8wC5ACgpNyWle7tNvDICOKuCdqNRaHfJ8ZxPgomdMxQvludjrsHAI9UnWoMoeK2Yzelo4DSD8GRRViLRg"
    /// Dieselbe Unterschrift, nur mit anderem Inhalt: darf nicht passen.
    static let andereNachricht = "YEM1N-V2\nPOST\n/v2/senden\n\(familie)\n\(geraet)\n1800000000000\nc6cce9f44f977fd0efd0f86be4300cbece83312106cce9c0b77b63450f38a9f1"
}

nonisolated func oeffentlicherSchluessel(_ bytes: [UInt8]) throws -> P256.Signing.PublicKey {
    try P256.Signing.PublicKey(x963Representation: Data(bytes))
}

nonisolated func unterschriftPasst(pub: [UInt8], sig: [UInt8], text: String) -> Bool {
    guard let schluessel = try? oeffentlicherSchluessel(pub),
          let s = try? P256.Signing.ECDSASignature(rawRepresentation: Data(sig)) else { return false }
    return schluessel.isValidSignature(s, for: Data(text.utf8))
}

/// Ein Speicher im Arbeitsspeicher. Der Schlüsselbund geht in Tests ohne Signatur der App nicht überall.
nonisolated final class SpeicherImArbeitsspeicher: SchluesselSpeicher, @unchecked Sendable {
    private let schloss = NSLock()
    private var daten: Data?

    func lese() -> Data? { schloss.lock(); defer { schloss.unlock() }; return daten }
    func schreibe(_ neu: Data) -> Bool { schloss.lock(); daten = neu; schloss.unlock(); return true }
    func loesche() { schloss.lock(); daten = nil; schloss.unlock() }
}

/// Merkt sich, was der Client abschickt.
nonisolated final class Aufzeichner: FamilienLeitung, @unchecked Sendable {
    struct Aufruf: Sendable {
        var pfad: String
        var kopf: [String: String]
        var body: String
    }

    private let schloss = NSLock()
    private var liste: [Aufruf] = []

    var aufrufe: [Aufruf] { schloss.lock(); defer { schloss.unlock() }; return liste }

    func post(pfad: String, kopf: [String: String], body: String) async -> (status: Int, text: String) {
        merke(Aufruf(pfad: pfad, kopf: kopf, body: body))
        return (200, "{\"ok\":true}")
    }

    // NSLock gehört in eine gewöhnliche Funktion, nicht in eine async-Funktion.
    private func merke(_ a: Aufruf) { schloss.lock(); liste.append(a); schloss.unlock() }
}

nonisolated func schluesselbundGeht() -> Bool {
    let probe = SchluesselbundSpeicher(konto: "probe-\(UUID().uuidString)")
    defer { probe.loesche() }
    return probe.schreibe(Data([1, 2, 3])) && probe.lese() == Data([1, 2, 3])
}

struct FamilieKryptoTests {

    // MARK: Prüfwerte

    @Test func dieUnterschriftAusDemTestvektorPasst() throws {
        let pub = try #require(FamilienKrypto.base64urlLesen(Vektor.pub))
        let sig = try #require(FamilienKrypto.base64urlLesen(Vektor.signatur))
        #expect(sig.count == 64)
        #expect(unterschriftPasst(pub: pub, sig: sig, text: Vektor.nachricht))
    }

    @Test func eineAndereNachrichtPasstNicht() throws {
        let pub = try #require(FamilienKrypto.base64urlLesen(Vektor.pub))
        let sig = try #require(FamilienKrypto.base64urlLesen(Vektor.signatur))
        #expect(!unterschriftPasst(pub: pub, sig: sig, text: Vektor.andereNachricht))
    }

    @Test func derNachrichtentextStimmtMitDemTestvektor() {
        let text = FamilienKrypto.unterschriftText(methode: "POST", pfad: "/v2/senden", familie: Vektor.familie,
                                                   geraet: Vektor.geraet, zeit: 1_800_000_000_000,
                                                   bodyHash: Vektor.bodyHash)
        #expect(text == Vektor.nachricht)
    }

    // MARK: Der Schlüssel dieses Geräts

    @Test func derGeraeteSchluesselUnterschreibtSoWieDerDienstEsPrueft() throws {
        let speicher = SpeicherImArbeitsspeicher()
        let schluessel = GeraetSchluessel(speicher: speicher)
        defer { schluessel.loeschen() }
        #expect(!schluessel.vorhanden)
        #expect(schluessel.oeffentlich() == nil)
        #expect(schluessel.signieren([1, 2, 3]) == nil)

        #expect(schluessel.neuErzeugen(), "Der Schlüssel konnte nicht angelegt werden")
        let pub = try #require(schluessel.oeffentlich())
        #expect(pub.count == 65 && pub[0] == 4)

        let daten = Array(Vektor.nachricht.utf8)
        let sig = try #require(schluessel.signieren(daten))
        #expect(sig.count == 64)
        #expect(unterschriftPasst(pub: pub, sig: sig, text: Vektor.nachricht))
        #expect(!unterschriftPasst(pub: pub, sig: sig, text: Vektor.andereNachricht))

        // Der Schlüssel bleibt nach einem Neustart derselbe (ein neues Objekt liest ihn aus dem Schlüsselbund)
        let nochmal = GeraetSchluessel(speicher: speicher)
        #expect(nochmal.oeffentlich() == pub)
    }

    @Test func einNeuerSchluesselIstEinAnderer() throws {
        let schluessel = GeraetSchluessel(speicher: SpeicherImArbeitsspeicher())
        defer { schluessel.loeschen() }
        #expect(schluessel.neuErzeugen())
        let eins = try #require(schluessel.oeffentlich())
        #expect(schluessel.neuErzeugen())
        let zwei = try #require(schluessel.oeffentlich())
        #expect(eins != zwei)
    }

    @Test func nachDemLoeschenIstKeinSchluesselMehrDa() {
        let schluessel = GeraetSchluessel(speicher: SpeicherImArbeitsspeicher())
        #expect(schluessel.neuErzeugen())
        schluessel.loeschen()
        #expect(!schluessel.vorhanden)
        #expect(schluessel.signieren([1]) == nil)
    }

    /// Der echte Schlüsselbund. In der Prüfung auf GitHub läuft die App ohne Signatur, dort geht er nicht.
    /// Auf dem Gerät und in Xcode läuft dieser Test mit.
    @Test(.enabled(if: schluesselbundGeht()))
    func derSchluesselbundBehaeltDenSchluessel() throws {
        let konto = "test-\(UUID().uuidString)"
        let schluessel = GeraetSchluessel(konto: konto)
        defer { schluessel.loeschen() }
        #expect(schluessel.neuErzeugen())
        let pub = try #require(schluessel.oeffentlich())
        let nochmal = GeraetSchluessel(konto: konto)
        #expect(nochmal.oeffentlich() == pub)
        schluessel.loeschen()
        #expect(GeraetSchluessel(konto: konto).oeffentlich() == nil)
    }

    // MARK: Client und Schlüssel zusammen

    @Test func dieAnfrageDesClientsTragtEineGueltigeUnterschrift() async throws {
        let schluessel = GeraetSchluessel(speicher: SpeicherImArbeitsspeicher())
        defer { schluessel.loeschen() }
        #expect(schluessel.neuErzeugen())
        let pub = try #require(schluessel.oeffentlich())

        let leitung = Aufzeichner()
        let client = FamilienClient(leitung: leitung, signierer: schluessel, jetzt: { 1_800_000_000_000 })
        let zugang = FamilienZugang(familie: Vektor.familie, geraet: FamilienKrypto.geraetId(pub: pub),
                                    name: "Yemin", rolle: "kind", status: "aktiv")
        let body = "{\"typ\":\"frage\",\"daten\":{\"id\":\"frage-0001\",\"kind\":\"Yemin\",\"text\":\"Was ist 56 : 7?\"}}"
        let antwort = await client.signiert(zugang, pfad: "/v2/senden", body: body)
        #expect(antwort.ok)

        let a = try #require(leitung.aufrufe.first)
        #expect(a.pfad == "/v2/senden")
        #expect(a.body == body)
        #expect(a.kopf["Y-Familie"] == Vektor.familie)
        #expect(a.kopf["Y-Geraet"] == zugang.geraet)
        #expect(a.kopf["Y-Zeit"] == "1800000000000")

        // So prüft der Dienst: Text neu bauen, Unterschrift mit dem öffentlichen Schlüssel des Geräts prüfen
        let text = FamilienKrypto.unterschriftText(methode: "POST", pfad: a.pfad, familie: Vektor.familie,
                                                   geraet: zugang.geraet, zeit: 1_800_000_000_000,
                                                   bodyHash: FamilienKrypto.sha256Hex(body))
        let sigText = try #require(a.kopf["Y-Signatur"])
        let sig = try #require(FamilienKrypto.base64urlLesen(sigText))
        #expect(unterschriftPasst(pub: pub, sig: sig, text: text))
        // Ein veränderter Körper würde auffallen
        let falsch = FamilienKrypto.unterschriftText(methode: "POST", pfad: a.pfad, familie: Vektor.familie,
                                                     geraet: zugang.geraet, zeit: 1_800_000_000_000,
                                                     bodyHash: FamilienKrypto.sha256Hex(body + " "))
        #expect(!unterschriftPasst(pub: pub, sig: sig, text: falsch))
    }

    @Test func dieGeraeteKennungKommtAusDemOeffentlichenSchluessel() throws {
        // CryptoKit und die eigene SHA-256 müssen dieselbe Kennung ergeben
        let pub = try #require(FamilienKrypto.base64urlLesen(Vektor.pub))
        let kennung = SHA256.hash(data: Data(pub)).map { String(format: "%02x", $0) }.joined().prefix(24)
        #expect(String(kennung) == Vektor.geraet)
        #expect(FamilienKrypto.geraetId(pub: pub) == Vektor.geraet)
    }

    @Test func dieEigeneSha256GleichtCryptoKit() {
        for text in ["", "a", "Was ist 56 : 7?", String(repeating: "Ä", count: 500)] {
            let erwartet = SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
            #expect(FamilienKrypto.sha256Hex(text) == erwartet, "Abweichung bei \(text.prefix(10))")
        }
    }
}
