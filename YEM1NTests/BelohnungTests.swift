import Foundation
import Testing
@testable import YEM1N

// Wann gibt es am Ende einer Runde einen Rekord und wie viel Konfetti fällt?

@MainActor
struct BelohnungTests {
    @Test func einRekordBrauchtEinenFrueherenBestwert() {
        #expect(!Belohnung.istNeuerRekord(gut: 8, beste: 0), "Die erste Runde ist noch kein Rekord")
        #expect(Belohnung.istNeuerRekord(gut: 8, beste: 7))
        #expect(!Belohnung.istNeuerRekord(gut: 7, beste: 7), "Gleich gut ist kein neuer Rekord")
        #expect(!Belohnung.istNeuerRekord(gut: 5, beste: 7))
    }

    @Test func konfettiErstAbZweiSternen() {
        #expect(Belohnung.konfetti(sterne: 0) == 0)
        #expect(Belohnung.konfetti(sterne: 1) == 0)
        #expect(Belohnung.konfetti(sterne: 2) > 0)
        #expect(Belohnung.konfetti(sterne: 3) > Belohnung.konfetti(sterne: 2))
    }
}
