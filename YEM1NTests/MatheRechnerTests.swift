import Foundation
import Testing
@testable import YEM1N

// Der Rechner ist das Herz der App. Wenn er falsch rechnet,
// lernt das Kind etwas Falsches.

@MainActor
struct MatheRechnerTests {

    /// Rechnet und vergleicht. Wirft der Rechner, gilt der Test als fehlgeschlagen.
    private func ergibt(_ rechnung: String, _ erwartet: Int) {
        do {
            let wert = try MatheRechner.werte(rechnung)
            #expect(wert == erwartet, "\(rechnung) ergab \(wert) statt \(erwartet)")
        } catch {
            Issue.record("\(rechnung) wurde abgelehnt: \(error)")
        }
    }

    @Test func punktVorStrich() {
        ergibt("9 · 9 + 8", 89)
        ergibt("8 + 9 · 9", 89)
        ergibt("100 - 7 · 8", 44)
        ergibt("20 + 36 : 6", 26)
        ergibt("36 : 6 + 20", 26)
        ergibt("50 - 24 : 4", 44)
    }

    @Test func klammernGehenVor() {
        ergibt("(2 + 3) · 4", 20)
        ergibt("2 + 3 · 4", 14)
    }

    @Test func gleichheitszeichenUndLeerzeichenStoerenNicht() {
        ergibt("7 · 8 =", 56)
        ergibt("7·8", 56)
        ergibt(" 7  ·  8 ", 56)
    }

    @Test func alleSchreibweisenFuerMalUndGeteilt() {
        for mal in ["·", "*", "×", "x", "X", "•"] {
            ergibt("6 \(mal) 7", 42)
        }
        for geteilt in [":", "/", "÷"] {
            ergibt("42 \(geteilt) 7", 6)
        }
    }

    @Test func teilenOhneRestWirdVerlangt() {
        #expect(wirftFehler("7 : 2"))
        #expect(wirftFehler("5 : 0"))
    }

    @Test func kaputteRechnungenWerdenAbgelehnt() {
        #expect(wirftFehler(""))
        #expect(wirftFehler("7 +"))
        #expect(wirftFehler("· 7"))
        #expect(wirftFehler("(2 + 3"))
        #expect(wirftFehler("7 € 8"))
    }

    @Test func minusDarfNegativWerden() {
        // Der Rechner selbst erlaubt das, die Generatoren vermeiden es.
        ergibt("3 - 10", -7)
    }

    @Test func anzeigeVereinheitlichtDieZeichen() {
        #expect(MatheRechner.anzeige("7*8") == "7 · 8")
        #expect(MatheRechner.anzeige("42/7") == "42 : 7")
        #expect(MatheRechner.anzeige("7x8=") == "7 · 8")
    }

    @Test func noteNachAnteil() {
        #expect(Spezial.note(gut: 20, gesamt: 20) == 1)
        #expect(Spezial.note(gut: 17, gesamt: 20) == 2)
        #expect(Spezial.note(gut: 14, gesamt: 20) == 3)
        #expect(Spezial.note(gut: 10, gesamt: 20) == 4)
        #expect(Spezial.note(gut: 5, gesamt: 20) == 5)
        #expect(Spezial.note(gut: 2, gesamt: 20) == 6)
        #expect(Spezial.note(gut: 0, gesamt: 0) == 6)
    }

    @Test func sterneNachAnteil() {
        #expect(sterneFuer(gut: 10, gesamt: 10) == 3)
        #expect(sterneFuer(gut: 9, gesamt: 10) == 3)
        #expect(sterneFuer(gut: 7, gesamt: 10) == 2)
        #expect(sterneFuer(gut: 5, gesamt: 10) == 1)
        #expect(sterneFuer(gut: 4, gesamt: 10) == 0)
        #expect(sterneFuer(gut: 0, gesamt: 0) == 0)
    }
}
