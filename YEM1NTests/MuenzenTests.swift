import Foundation
import Testing
@testable import YEM1N

// Die Münzen sind der Anreiz zum Üben. Wenn sich Spicken lohnt,
// erzieht die App zum Falschen.

@MainActor
struct MuenzenTests {

    @Test func eineMuenzeProRichtigerAufgabe() {
        #expect(Muenzen.verdient(richtig: 5, gesamt: 10, angesehen: 0) == 5)
        #expect(Muenzen.verdient(richtig: 1, gesamt: 10, angesehen: 0) == 1)
    }

    @Test func bonusFuerSterne() {
        // 10 von 10 sind drei Sterne
        #expect(Muenzen.verdient(richtig: 10, gesamt: 10, angesehen: 0) == 10 + Muenzen.bonusDreiSterne)
        // 7 von 10 sind zwei Sterne
        #expect(Muenzen.verdient(richtig: 7, gesamt: 10, angesehen: 0) == 7 + Muenzen.bonusZweiSterne)
        // 5 von 10 ist ein Stern, kein Bonus
        #expect(Muenzen.verdient(richtig: 5, gesamt: 10, angesehen: 0) == 5)
    }

    @Test func angeschauteLoesungenKostenDenBonus() {
        let ohne = Muenzen.verdient(richtig: 10, gesamt: 10, angesehen: 0)
        let mit = Muenzen.verdient(richtig: 10, gesamt: 10, angesehen: 1)
        #expect(mit == 10, "Für den Rest gibt es weiter Münzen")
        #expect(mit < ohne, "Spicken darf sich nicht lohnen")
    }

    @Test func ohneRichtigeAufgabeKeineMuenzen() {
        #expect(Muenzen.verdient(richtig: 0, gesamt: 10, angesehen: 10) == 0)
        #expect(Muenzen.verdient(richtig: 0, gesamt: 0, angesehen: 0) == 0)
    }

    @Test func mehrRichtigBringtNieWeniger() {
        var vorher = -1
        for richtig in 0...12 {
            let jetzt = Muenzen.verdient(richtig: richtig, gesamt: 12, angesehen: 0)
            #expect(jetzt >= vorher, "Bei \(richtig) von 12 gab es weniger als vorher")
            vorher = jetzt
        }
    }

    @Test func einSpielIstInEinPaarRundenVerdient() {
        // Drei saubere Runden mit zehn Aufgaben sollen für ein Spiel reichen
        let dreiRunden = 3 * Muenzen.verdient(richtig: 10, gesamt: 10, angesehen: 0)
        #expect(dreiRunden >= Muenzen.preisProSpiel)
        // Aber eine einzelne Runde soll noch nicht reichen
        #expect(Muenzen.verdient(richtig: 10, gesamt: 10, angesehen: 0) < Muenzen.preisProSpiel)
    }
}
