import Foundation
import Testing
@testable import YEM1N

// Olli zeigt Rechnungen als Bild. Das Bild muss genau zur Aufgabe passen.
// Passt die Rechnung nicht zur Lösung, gibt es lieber gar kein Bild.

@MainActor
struct ErklaerBildTests {

    /// Mit Art, zum Beispiel bild("rest", "58 : 4 =", "14", rest: "2")
    private func bild(_ art: String, _ rechnung: String, erklaerung: String = "",
                      _ antwort: String, rest: String = "") -> ErklaerBild? {
        ErklaerBildPlan.bild(art: art, rechnung: rechnung, erklaerung: erklaerung,
                             antwort: antwort, antwort2: rest)
    }

    /// Ohne Art ist es eine Zahlaufgabe, zum Beispiel bild("7 · 8 =", "56")
    private func bild(_ rechnung: String, erklaerung: String = "", _ antwort: String,
                      rest: String = "") -> ErklaerBild? {
        bild("zahl", rechnung, erklaerung: erklaerung, antwort, rest: rest)
    }

    // MARK: Mal

    @Test func malWirdZumPunktefeld() {
        let b = bild("7 · 8 =", "56")
        #expect(b?.art == .punkte(reihen: 7, spalten: 8))
        #expect(b?.saetze.contains("Zähle in Achterschritten: 8, 16, 24, 32, 40, 48, 56.") == true)
        #expect(b?.saetze.last == "Zusammen sind es 56.")
    }

    @Test func nachbaraufgabenZeigenEineReiheMehrOderWeniger() {
        let mehr = bild("6 · 7 =", "42")
        #expect(mehr?.art == .nachbar(kern: 5, reihen: 6, spalten: 7))
        #expect(mehr?.saetze[1] == "Eine Reihe mehr: 35 + 7 = 42.")
        let weniger = bild("9 · 4 =", "36")
        #expect(weniger?.art == .nachbar(kern: 10, reihen: 9, spalten: 4))
        #expect(weniger?.saetze[1] == "Eine Reihe weniger: 40 - 4 = 36.")
        let vier = bild("4 · 6 =", "24")
        #expect(vier?.art == .nachbar(kern: 5, reihen: 4, spalten: 6))
    }

    @Test func eineFalscheLoesungBekommtKeinBild() {
        #expect(bild("7 · 8 =", "54") == nil)
        #expect(bild("47 + 8 =", "56") == nil)
        #expect(bild("rest", "58 : 4 =", "14", rest: "3") == nil)
        #expect(bild("vergleich", "5 · 5  ?  9 · 7", ">") == nil)
    }

    // MARK: Geteilt

    @Test func teilenMitRestVerteiltKekseAufTeller() {
        let b = bild("rest", "58 : 4 =", "14", rest: "2")
        #expect(b?.art == .teller(gesamt: 58, teller: 4, jeder: 14, rest: 2))
        #expect(b?.saetze.contains("2 Kekse bleiben übrig. Das ist der Rest.") == true)
        #expect(b?.saetze.contains("58 : 4 = 14 Rest 2") == true)
        let einer = bild("rest", "13 : 4 =", "3", rest: "1")
        #expect(einer?.saetze.contains("1 Keks bleibt übrig. Das ist der Rest.") == true)
    }

    @Test func geteiltOhneRestLaesstNichtsUebrig() {
        let b = bild("32 : 8 =", "4")
        #expect(b?.art == .teller(gesamt: 32, teller: 8, jeder: 4, rest: 0))
        #expect(b?.saetze.last == "Es bleibt nichts übrig. 32 : 8 = 4")
    }

    @Test func zuVieleKekseProTellerWerdenNichtGemalt() {
        #expect(bild("96 : 2 =", "48") == nil)
    }

    // MARK: Plus und Minus

    @Test func spruengeGehenZuerstBisZumZehner() {
        #expect(ErklaerBildPlan.spruenge(von: 47, plus: true, um: 8) == [3, 5])
        #expect(ErklaerBildPlan.spruenge(von: 75, plus: false, um: 8) == [-5, -3])
        #expect(ErklaerBildPlan.spruenge(von: 47, plus: true, um: 25) == [20, 3, 2])
        #expect(ErklaerBildPlan.spruenge(von: 75, plus: false, um: 28) == [-20, -5, -3])
        #expect(ErklaerBildPlan.spruenge(von: 32, plus: true, um: 5) == [5])
        #expect(ErklaerBildPlan.spruenge(von: 60, plus: false, um: 6) == [-6])
        #expect(ErklaerBildPlan.spruenge(von: 345, plus: true, um: 278) == [200, 70, 5, 3])
    }

    @Test func dieSpruengeErgebenGenauDasErgebnis() {
        for a in stride(from: 0, through: 100, by: 7) {
            for b in 1...40 {
                let hoch = ErklaerBildPlan.spruenge(von: a, plus: true, um: b)
                #expect(a + hoch.reduce(0, +) == a + b)
                if a >= b {
                    let runter = ErklaerBildPlan.spruenge(von: a, plus: false, um: b)
                    #expect(a + runter.reduce(0, +) == a - b)
                }
            }
        }
    }

    @Test func wortaufgabenNehmenDieRechnungAusDerErklaerung() {
        let b = bild("Subtrahiere von 75 die Zahl 8.", erklaerung: "75 - 8 = 67", "67")
        #expect(b?.art == .spruenge(start: 75, schritte: [-5, -3]))
        #expect(b?.saetze == ["Rechne in Sprüngen auf dem Zahlenstrahl.",
                              "Zuerst bis zum Zehner, dann weiter.",
                              "75 - 5 = 70",
                              "70 - 3 = 67"])
    }

    // MARK: Mehrere Rechenzeichen

    @Test func punktVorStrichZeigtDenRechenweg() {
        let b = bild("9 · 9 + 8 =", "89")
        #expect(b?.art == .rechenweg(["9 · 9 + 8", "81 + 8", "89"]))
        #expect(b?.saetze == ["Punkt vor Strich: Mal und Geteilt kommen zuerst.",
                              "Zuerst: 9 · 9 = 81",
                              "Dann: 81 + 8 = 89"])
        let geteilt = bild("20 - 12 : 4 =", "17")
        #expect(geteilt?.art == .rechenweg(["20 - 12 : 4", "20 - 3", "17"]))
    }

    @Test func nichtAufgehendeOderNegativeRechnungenBekommenKeinBild() {
        #expect(bild("10 : 3 + 1 =", "4") == nil)
        #expect(bild("2 - 5 + 10 =", "7") == nil)
    }

    // MARK: Größer oder kleiner

    @Test func vergleichRechnetErstBeideSeitenAus() {
        let b = bild("vergleich", "5 · 5  ?  9 · 7", "<")
        #expect(b?.art == .rechenweg(["5 · 5  ?  9 · 7", "25  ?  63", "25  <  63"]))
        #expect(b?.saetze.contains("25 ist kleiner als 63.") == true)
        let gleich = bild("vergleich", "3 · 8  ?  4 · 6", "=")
        #expect(gleich?.saetze.contains("24 ist genauso groß wie 24.") == true)
        let zahl = bild("vergleich", "45  ?  6 · 7", ">")
        #expect(zahl?.art == .rechenweg(["45  ?  6 · 7", "45  ?  42", "45  >  42"]))
    }

    // MARK: Kein Bild, wo keins passt

    @Test func raetselTextUndMauerBekommenKeinBild() {
        #expect(bild("Meine Zahl ist gerade.\nSie ist eine Neunerzahl.", "36") == nil)
        #expect(bild("text", "Hun?", "d") == nil)
        #expect(bild("mauer", "", "") == nil)
    }

    @Test func soVieleSchritteHatDasBild() {
        #expect(ErklaerBildPlan.schrittZahl(.punkte(reihen: 7, spalten: 8)) == 7)
        #expect(ErklaerBildPlan.schrittZahl(.teller(gesamt: 58, teller: 4, jeder: 14, rest: 2)) == 15)
        #expect(ErklaerBildPlan.schrittZahl(.teller(gesamt: 32, teller: 8, jeder: 4, rest: 0)) == 4)
        #expect(ErklaerBildPlan.schrittZahl(.rechenweg(["a", "b", "c"])) == 2)
    }

    @Test func keineGedankenstricheInOllisSaetzen() {
        let alle = [bild("7 · 8 =", "56"), bild("6 · 7 =", "42"), bild("rest", "58 : 4 =", "14", rest: "2"),
                    bild("47 + 25 =", "72"), bild("9 · 9 + 8 =", "89"), bild("vergleich", "5 · 5  ?  9 · 7", "<")]
        for b in alle {
            #expect(b != nil)
            for satz in b?.saetze ?? [] {
                #expect(!satz.contains("\u{2013}") && !satz.contains("\u{2014}"), "\(satz)")
            }
        }
    }
}
