import Foundation
import CryptoKit
import Testing
@testable import YEM1N

// Pakete an den Klassencode: Unterschrift und gemerkter Schlüssel.
// Geht hier etwas schief, kommen bei den Klassenkameraden keine Aufgaben an.

@MainActor
struct KlassensiegelTests {

    private let a = Data([1, 2, 3])
    private let b = Data([4, 5, 6])

    @Test func ersterSchluesselWirdGemerkt() {
        #expect(Klassensiegel.bewerte(gemerkt: nil, geholt: a) == .neu(a))
    }

    @Test func gleicherSchluesselBleibtVertraut() {
        #expect(Klassensiegel.bewerte(gemerkt: a, geholt: a) == .vertraut(a))
    }

    @Test func ohneCloudGiltDerGemerkte() {
        #expect(Klassensiegel.bewerte(gemerkt: a, geholt: nil) == .vertraut(a))
    }

    @Test func andererSchluesselWirdErkannt() {
        let stand = Klassensiegel.bewerte(gemerkt: a, geholt: b)
        #expect(stand == .gewechselt)
        #expect(stand.schluessel == nil)
    }

    @Test func ohneSchluesselNirgends() {
        #expect(Klassensiegel.bewerte(gemerkt: nil, geholt: nil) == .fehlt)
    }

    @Test func unterschriftPasstNurZumRichtigenSchluessel() throws {
        let k = Curve25519.Signing.PrivateKey()
        let fremd = Curve25519.Signing.PrivateKey()
        let code = "K-ABCDE-FGHJK"
        let json = "{\"klasse\":\"Klasse 3\"}"
        let sig = try k.signature(for: Data((code + "|" + json).utf8)).base64EncodedString()
        #expect(Klassensiegel.pruefe(code: code, json: json, sig: sig,
                                     oeffentlich: k.publicKey.rawRepresentation))
        #expect(!Klassensiegel.pruefe(code: code, json: json, sig: sig,
                                      oeffentlich: fremd.publicKey.rawRepresentation))
        #expect(!Klassensiegel.pruefe(code: code, json: json + " ", sig: sig,
                                      oeffentlich: k.publicKey.rawRepresentation))
    }

    @Test func jederGrundHatEinenText() {
        let alle: [Klassensiegel.Ablehnung] = [.ohneUnterschrift, .keinSchluessel, .schluesselGewechselt, .unterschriftFalsch]
        for g in alle { #expect(!g.text.isEmpty) }
    }
}
