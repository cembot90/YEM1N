import Foundation
import Testing
@testable import YEM1N

// Der Erklär-Freund und der Elternbericht nennen einen Grund für einen Fehler.
// Dieser Grund muss stimmen, sonst lernt das Kind etwas Falsches.

@MainActor
struct FehlerAnalyseTests {

    private func zahl(_ rechnung: String, soll: String, ist: String, erklaerung: String = "") -> FehlerBefund? {
        FehlerAnalyse.befund(art: "zahl", rechnung: rechnung, erklaerung: erklaerung,
                             antwort: soll, antwort2: "", eingabe: ist)
    }

    // MARK: Rechenausdruck

    @Test func liestEinfacheRechnungen() {
        #expect(Rechenausdruck.lies("7 · 8 =") == Rechenausdruck(zahlen: [7, 8], zeichen: ["*"]))
        #expect(Rechenausdruck.lies("58 : 4 = 14 R 2") == Rechenausdruck(zahlen: [58, 4], zeichen: ["/"]))
        #expect(Rechenausdruck.lies("9 · 9 + 8 =")?.wert == 89)
        #expect(Rechenausdruck.lies("8 + 9 · 9 =")?.wert == 89)
        #expect(Rechenausdruck.lies("8 + 9 · 9 =")?.linksNachRechts == 153)
    }

    @Test func woerterSindKeinAusdruck() {
        #expect(Rechenausdruck.lies("Subtrahiere von 75 die Zahl 8.") == nil)
        #expect(Rechenausdruck.lies("") == nil)
        #expect(Rechenausdruck.lies("12") == nil)
        #expect(Rechenausdruck.lies("(3 + 4) · 2 =") == nil)
    }

    // MARK: Teilen mit Rest

    @Test func beiZehnStehenGeblieben() {
        let b = FehlerAnalyse.befund(art: "rest", rechnung: "48 : 4 =", erklaerung: "",
                                     antwort: "12", antwort2: "0", eingabe: "10", eingabe2: "8")
        #expect(b?.muster == .restZuGross)
        #expect(b?.satz.contains("bei 10 stehen geblieben") == true)
        #expect(b?.satz.contains("48 : 4 = 12 Rest 0") == true)
    }

    @Test func nurDerRestFalsch() {
        let b = FehlerAnalyse.befund(art: "rest", rechnung: "58 : 4 =", erklaerung: "",
                                     antwort: "14", antwort2: "2", eingabe: "14", eingabe2: "3")
        #expect(b?.muster == .restFalsch)
        #expect(b?.satz.contains("14 · 4 = 56") == true)
    }

    @Test func zuGrosseZahlBeimTeilen() {
        let b = FehlerAnalyse.befund(art: "rest", rechnung: "58 : 4 =", erklaerung: "",
                                     antwort: "14", antwort2: "2", eingabe: "15", eingabe2: "0")
        #expect(b?.muster == .geteiltZuViel)
    }

    @Test func richtigeRestaufgabeHatKeinenBefund() {
        let b = FehlerAnalyse.befund(art: "rest", rechnung: "58 : 4 =", erklaerung: "",
                                     antwort: "14", antwort2: "2", eingabe: "14", eingabe2: "2")
        #expect(b == nil)
    }

    // MARK: Rechnen

    @Test func plusStattMal() {
        #expect(zahl("7 · 8 =", soll: "56", ist: "15")?.muster == .plusStattMal)
    }

    @Test func eineReiheZuVielOderZuWenig() {
        let viel = zahl("6 · 7 =", soll: "42", ist: "49")
        #expect(viel?.muster == .malReiheZuViel)
        #expect(viel?.satz.contains("eine 7 zu viel") == true)
        #expect(zahl("6 · 7 =", soll: "42", ist: "35")?.muster == .malReiheZuWenig)
    }

    @Test func malStattGeteiltUndUmkehraufgabe() {
        #expect(zahl("32 : 8 =", soll: "4", ist: "256")?.muster == .malStattGeteilt)
        let b = zahl("32 : 8 =", soll: "4", ist: "5")
        #expect(b?.muster == .geteiltDaneben)
        #expect(b?.satz.contains("5 · 8 = 40") == true)
    }

    @Test func plusUndMinusVerwechselt() {
        #expect(zahl("75 - 8 =", soll: "67", ist: "83")?.muster == .plusStattMinus)
        #expect(zahl("45 + 7 =", soll: "52", ist: "38")?.muster == .minusStattPlus)
    }

    @Test func wortaufgabeNutztDieErklaerung() {
        let b = zahl("Wie heißt die Differenz der Zahlen 75 und 8?", soll: "67", ist: "83",
                     erklaerung: "75 - 8 = 67")
        #expect(b?.muster == .plusStattMinus)
    }

    @Test func punktVorStrichMissachtet() {
        let b = zahl("8 + 9 · 9 =", soll: "89", ist: "153")
        #expect(b?.muster == .punktVorStrich)
    }

    @Test func zifferDreherZehnerUndKnapp() {
        #expect(zahl("Rechne.", soll: "76", ist: "67")?.muster == .zifferDreher)
        #expect(zahl("48 + 25 =", soll: "73", ist: "63")?.muster == .zehnerDaneben)
        #expect(zahl("48 + 25 =", soll: "73", ist: "72")?.muster == .knappDaneben)
    }

    @Test func unbekannterFehlerOhneBefund() {
        #expect(zahl("7 · 8 =", soll: "56", ist: "12") == nil)
        #expect(zahl("7 · 8 =", soll: "56", ist: "56") == nil)
        #expect(zahl("7 · 8 =", soll: "56", ist: "abc") == nil)
    }

    @Test func jederSatzNenntDieRichtigeLoesung() {
        let faelle: [(String, String, String)] = [
            ("7 · 8 =", "56", "15"), ("6 · 7 =", "42", "49"), ("32 : 8 =", "4", "5"),
            ("75 - 8 =", "67", "83"), ("8 + 9 · 9 =", "89", "153"), ("48 + 25 =", "73", "72")
        ]
        for (r, soll, ist) in faelle {
            let b = zahl(r, soll: soll, ist: ist)
            #expect(b != nil, "Kein Befund für \(r)")
            #expect(b?.satz.contains(soll) == true, "Lösung fehlt im Satz zu \(r)")
        }
    }

    // MARK: Größer oder kleiner

    @Test func vergleichszeichen() {
        let um = FehlerAnalyse.befund(art: "vergleich", rechnung: "5 · 5  ?  9 · 7", erklaerung: "25 < 63",
                                      antwort: "<", antwort2: "", eingabe: ">")
        #expect(um?.muster == .vergleichUmgedreht)
        #expect(um?.satz.contains("25 < 63") == true)
        let gleich = FehlerAnalyse.befund(art: "vergleich", rechnung: "4 · 6  ?  6 · 4", erklaerung: "24 = 24",
                                          antwort: "=", antwort2: "", eingabe: "<")
        #expect(gleich?.muster == .gleichUebersehen)
    }

    // MARK: Rechtschreibung

    private func text(_ soll: String, _ ist: String) -> FehlerMuster? {
        FehlerAnalyse.befund(art: "text", rechnung: "", erklaerung: "",
                             antwort: soll, antwort2: "", eingabe: ist)?.muster
    }

    @Test func rechtschreibMuster() {
        #expect(text("Hund", "hund") == .grossKlein)
        #expect(text("d", "t") == .hartWeich)
        #expect(text("Wald", "Walt") == .hartWeich)
        #expect(text("Äpfel", "Epfel") == .aeStattE)
        #expect(text("Sonne", "Sone") == .doppelterMitlaut)
        #expect(text("Biene", "Bine") == .ieStattI)
        #expect(text("Schule", "Schuke") == .einBuchstabe)
        #expect(text("Haus", "Baum") == nil)
        #expect(text("Haus", "Haus") == nil)
    }

    // MARK: Eltern-Gerät

    @Test func befundAusDemProtokoll() {
        let rest = AntwortDetail(nr: 1, frage: "Teile mit Rest.", rechnung: "48 : 4 =",
                                 eingabe: "10 Rest 8", loesung: "12 Rest 0", stand: AntwortStand.falsch)
        #expect(FehlerAnalyse.befund(detail: rest)?.muster == .restZuGross)
        let vergleich = AntwortDetail(nr: 2, frage: "Was gehört in die Mitte?", rechnung: "5 · 5  ?  9 · 7",
                                      eingabe: ">", loesung: "<", stand: AntwortStand.falsch)
        #expect(FehlerAnalyse.befund(detail: vergleich)?.muster == .vergleichUmgedreht)
        let wort = AntwortDetail(nr: 3, frage: "Schreib richtig.", rechnung: "Hun?",
                                 eingabe: "t", loesung: "d", stand: AntwortStand.falsch)
        #expect(FehlerAnalyse.befund(detail: wort)?.muster == .hartWeich)
        let richtig = AntwortDetail(nr: 4, frage: "Rechne.", rechnung: "7 · 8 =",
                                    eingabe: "56", loesung: "56", stand: AntwortStand.richtig)
        #expect(FehlerAnalyse.befund(detail: richtig) == nil)
    }
}
