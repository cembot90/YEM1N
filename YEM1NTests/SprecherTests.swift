import Foundation
import Testing
@testable import YEM1N

// Welche Stimme vorliest, entscheidet die Rangfolge. Eine schlechte Stimme
// vor einer guten wäre genau das, worüber sich Eltern beschwert haben.

@MainActor
struct SprecherTests {

    @Test func premiumVorErweitertVorEinfach() {
        let einfach = Sprecher.punkte(qualitaet: 1, gleicheRegion: true)
        let erweitert = Sprecher.punkte(qualitaet: 2, gleicheRegion: true)
        let premium = Sprecher.punkte(qualitaet: 3, gleicheRegion: true)
        #expect(premium > erweitert)
        #expect(erweitert > einfach)
    }

    @Test func qualitaetZaehltMehrAlsRegion() {
        // Eine Premium-Stimme aus Österreich ist besser als eine einfache aus Deutschland
        #expect(Sprecher.punkte(qualitaet: 3, gleicheRegion: false)
                > Sprecher.punkte(qualitaet: 1, gleicheRegion: true))
    }

    @Test func beiGleicherQualitaetGewinntDieEigeneRegion() {
        #expect(Sprecher.punkte(qualitaet: 2, gleicheRegion: true)
                > Sprecher.punkte(qualitaet: 2, gleicheRegion: false))
    }

    @Test func schluesselNurNachSprache() {
        // de-DE und de-AT teilen sich eine Auswahl
        #expect(Sprecher.schluessel("de-DE") == "stimme.de")
        #expect(Sprecher.schluessel("de-AT") == "stimme.de")
        #expect(Sprecher.schluessel("tr-TR") == "stimme.tr")
    }
}
