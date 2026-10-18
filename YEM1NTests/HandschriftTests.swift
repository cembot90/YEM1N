import Foundation
import Testing
@testable import YEM1N

// Das Kind schreibt die Antwort mit der Hand. Die Texterkennung liefert dazu Text,
// der manchmal Buchstaben statt Ziffern enthält. Hier wird geprüft, dass daraus
// die richtige Zahl wird und dass Unsinn nicht als Zahl durchgeht.

@MainActor
struct HandschriftTests {

    @Test func klareZiffernBleibenWieSieSind() {
        #expect(Handschrift.zahl(aus: "56", maxLaenge: 3) == "56")
        #expect(Handschrift.zahl(aus: "0", maxLaenge: 3) == "0")
        #expect(Handschrift.zahl(aus: "100", maxLaenge: 3) == "100")
    }

    @Test func leerzeichenUndPunkteFallenWeg() {
        #expect(Handschrift.zahl(aus: "5 6", maxLaenge: 3) == "56")
        #expect(Handschrift.zahl(aus: "4.2", maxLaenge: 3) == "42")
        #expect(Handschrift.zahl(aus: " 7 ", maxLaenge: 3) == "7")
    }

    @Test func typischeVerwechslungenWerdenZuZiffern() {
        #expect(Handschrift.zahl(aus: "l2", maxLaenge: 3) == "12")
        #expect(Handschrift.zahl(aus: "S6", maxLaenge: 3) == "56")
        #expect(Handschrift.zahl(aus: "B1", maxLaenge: 3) == "81")
        #expect(Handschrift.zahl(aus: "Z0", maxLaenge: 3) == "20")
        #expect(Handschrift.zahl(aus: "4O", maxLaenge: 3) == "40")
        #expect(Handschrift.zahl(aus: "g", maxLaenge: 3) == "9")
    }

    @Test func fuehrendeNullenFallenWeg() {
        #expect(Handschrift.zahl(aus: "07", maxLaenge: 3) == "7")
        #expect(Handschrift.zahl(aus: "00", maxLaenge: 3) == "0")
    }

    @Test func unsinnIstKeineZahl() {
        #expect(Handschrift.zahl(aus: "", maxLaenge: 3) == nil)
        #expect(Handschrift.zahl(aus: "..", maxLaenge: 3) == nil)
        #expect(Handschrift.zahl(aus: "Haus", maxLaenge: 3) == nil)
        #expect(Handschrift.zahl(aus: "4x", maxLaenge: 3) == nil)
    }

    @Test func zuLangeZahlenPassenNichtInsFeld() {
        #expect(Handschrift.zahl(aus: "1234", maxLaenge: 3) == nil)
        #expect(Handschrift.zahl(aus: "123", maxLaenge: 2) == nil)
    }

    @Test func vonJedemStueckZaehltDerErsteVorschlagDerEineZahlIst() {
        #expect(Handschrift.lies([["Sb", "56"]], maxLaenge: 3) == "56")
        #expect(Handschrift.lies([["Haus", "7"]], maxLaenge: 3) == "7")
    }

    @Test func stueckeWerdenVonLinksNachRechtsZusammengesetzt() {
        #expect(Handschrift.lies([["4"], ["2"]], maxLaenge: 3) == "42")
        #expect(Handschrift.lies([["4"], ["x?"], ["2"]], maxLaenge: 3) == "42", "Ein Krakel dazwischen fällt weg")
    }

    @Test func ohneLesbareSchriftGibtEsKeineZahl() {
        #expect(Handschrift.lies([], maxLaenge: 3) == nil)
        #expect(Handschrift.lies([["Haus"], ["?"]], maxLaenge: 3) == nil)
        #expect(Handschrift.lies([["5"], ["6"], ["7"], ["8"]], maxLaenge: 3) == nil, "Vier Ziffern passen nicht")
    }
}
