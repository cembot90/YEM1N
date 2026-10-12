import Foundation
import Testing
@testable import YEM1N

// Die Eltern sollen genau sehen, bei welcher Aufgabe das Kind was geschrieben hat.

@MainActor
struct AntwortenTests {

    private func eintrag(nr: Int = 1, art: String = "zahl", rechnung: String = "7 · 8 =",
                         antwort: String = "56", antwort2: String = "", reihen: [[Int]] = [],
                         richtig: Bool?, angesehen: Bool = false,
                         gegeben: String = "", soll: String = "") -> AntwortDetail {
        AntwortProtokoll.eintrag(nr: nr, art: art, frage: "Rechne.", rechnung: rechnung,
                                 antwort: antwort, antwort2: antwort2, reihen: reihen,
                                 richtig: richtig, angesehen: angesehen,
                                 gegeben: gegeben, soll: soll)
    }

    // MARK: Einträge

    @Test func falscheAntwortMerktSichDieEingabe() {
        let d = eintrag(richtig: false, gegeben: "54")
        #expect(d.stand == AntwortStand.falsch)
        #expect(d.eingabe == "54")
        #expect(d.loesung == "56")
        #expect(d.rechnung == "7 · 8 =")
        #expect(d.istProblem)
    }

    @Test func richtigeAntwortIstKeinProblem() {
        let d = eintrag(richtig: true, gegeben: "56")
        #expect(d.stand == AntwortStand.richtig)
        #expect(!d.istProblem)
    }

    @Test func angeschauteLoesungHatKeineEingabe() {
        let d = eintrag(richtig: nil, angesehen: true, gegeben: "56")
        #expect(d.stand == AntwortStand.angeschaut)
        #expect(d.eingabe.isEmpty)
        #expect(d.istProblem)
    }

    @Test func unbearbeiteteAufgabeIstOffen() {
        #expect(eintrag(richtig: nil).stand == AntwortStand.offen)
    }

    @Test func teilenMitRestZeigtBeideZahlen() {
        let d = eintrag(art: "rest", rechnung: "58 : 4 =", antwort: "14", antwort2: "2",
                        richtig: false, gegeben: "10 Rest 18")
        #expect(d.loesung == "14 Rest 2")
        #expect(d.eingabe == "10 Rest 18")
    }

    @Test func zahlenmauerZeigtDieUntersteReiheUndDieFalscheStelle() {
        let reihen = [[14, 11, 11, 9], [25, 22, 20], [47, 42], [89]]
        let falsch = eintrag(art: "mauer", rechnung: "", reihen: reihen,
                             richtig: false, gegeben: "24", soll: "14 + 11 = 25")
        #expect(falsch.rechnung == "Zahlenmauer, unten: 14, 11, 11, 9")
        #expect(falsch.loesung == "14 + 11 = 25")
        let richtig = eintrag(art: "mauer", rechnung: "", reihen: reihen,
                              richtig: true, gegeben: "alles richtig")
        #expect(richtig.loesung == "Spitze 89")
    }

    @Test func langeTexteWerdenGekuerzt() {
        let lang = String(repeating: "a", count: 500)
        let d = eintrag(rechnung: lang, richtig: true)
        #expect(d.rechnung.count <= AntwortProtokoll.maxTextLaenge + 4)
    }

    // MARK: Speichern und Lesen

    @Test func jsonHinUndZurueck() {
        let liste = [eintrag(nr: 2, richtig: true, gegeben: "56"),
                     eintrag(nr: 1, rechnung: "6 · 7 =", antwort: "42", richtig: false, gegeben: "48")]
        let text = AntwortProtokoll.json(liste)
        #expect(!text.isEmpty)
        let zurueck = AntwortProtokoll.liste(aus: text)
        #expect(zurueck.count == 2)
        #expect(zurueck.first?.nr == 1)
        #expect(zurueck.first?.eingabe == "48")
    }

    @Test func leererOderKaputterTextErgibtLeereListe() {
        #expect(AntwortProtokoll.liste(aus: "").isEmpty)
        #expect(AntwortProtokoll.liste(aus: "kein json").isEmpty)
        #expect(AntwortProtokoll.json([]).isEmpty)
    }

    @Test func umlauteBleibenErhalten() {
        let d = AntwortProtokoll.eintrag(nr: 1, art: "text", frage: "Ergänze.", rechnung: "Stra?e",
                                         antwort: "ß", antwort2: "", reihen: [],
                                         richtig: false, angesehen: false, gegeben: "ss", soll: "")
        let zurueck = AntwortProtokoll.liste(aus: AntwortProtokoll.json([d]))
        #expect(zurueck.first?.loesung == "ß")
        #expect(zurueck.first?.frage == "Ergänze.")
    }

    // MARK: Aufgaben, die haken

    private func runde(_ uebung: String, vorTagen: Int, _ details: [AntwortDetail])
        -> (uebung: String, zeitpunkt: Date, details: String) {
        let zeit = Date(timeIntervalSince1970: 1_800_000_000 - Double(vorTagen) * 86_400)
        return (uebung: uebung, zeitpunkt: zeit, details: AntwortProtokoll.json(details))
    }

    @Test func gleicheAufgabeWirdUeberRundenZusammengefasst() {
        let runden = [
            runde("Einmaleins", vorTagen: 3, [eintrag(richtig: false, gegeben: "54")]),
            runde("Einmaleins", vorTagen: 2, [eintrag(richtig: false, gegeben: "48")]),
            runde("Einmaleins", vorTagen: 1, [eintrag(richtig: false, gegeben: "54")])
        ]
        let liste = AntwortProtokoll.problemAufgaben(runden)
        #expect(liste.count == 1)
        let p = liste.first
        #expect(p?.falsch == 3)
        #expect(p?.falscheEingaben == ["54", "48"])
        #expect(p?.zuletztRichtig == false)
    }

    @Test func richtigeAufgabenTauchenNichtAuf() {
        let runden = [runde("Einmaleins", vorTagen: 1, [eintrag(richtig: true, gegeben: "56")])]
        #expect(AntwortProtokoll.problemAufgaben(runden).isEmpty)
    }

    @Test func wasNochNichtSitztKommtZuerst() {
        let geschafft = eintrag(rechnung: "6 · 7 =", antwort: "42", richtig: false, gegeben: "48")
        let geschafftSpaeter = eintrag(rechnung: "6 · 7 =", antwort: "42", richtig: true, gegeben: "42")
        let offen = eintrag(rechnung: "9 · 7 =", antwort: "63", richtig: false, gegeben: "56")
        let runden = [
            runde("Einmaleins", vorTagen: 4, [geschafft]),
            runde("Einmaleins", vorTagen: 3, [geschafft]),
            runde("Einmaleins", vorTagen: 2, [offen]),
            runde("Einmaleins", vorTagen: 1, [geschafftSpaeter])
        ]
        let liste = AntwortProtokoll.problemAufgaben(runden)
        #expect(liste.map(\.rechnung) == ["9 · 7 =", "6 · 7 ="])
        #expect(liste.last?.zuletztRichtig == true)
        #expect(liste.last?.richtig == 1)
    }

    @Test func gleicheRechnungInVerschiedenenUebungenBleibtGetrennt() {
        let runden = [
            runde("Einmaleins", vorTagen: 2, [eintrag(richtig: false, gegeben: "54")]),
            runde("Alles gemischt", vorTagen: 1, [eintrag(richtig: false, gegeben: "54")])
        ]
        #expect(AntwortProtokoll.problemAufgaben(runden).count == 2)
    }

    @Test func angeschauteLoesungZaehltAlsProblem() {
        let runden = [runde("Geteilt", vorTagen: 1, [eintrag(rechnung: "32 : 8 =", antwort: "4",
                                                              richtig: nil, angesehen: true)])]
        let p = AntwortProtokoll.problemAufgaben(runden).first
        #expect(p?.angeschaut == 1)
        #expect(p?.falscheEingaben.isEmpty == true)
    }

    @Test func grenzeWirdEingehalten() {
        let viele = (1...20).map { i in
            eintrag(nr: i, rechnung: "\(i) · 3 =", antwort: "\(i * 3)", richtig: false, gegeben: "0")
        }
        let liste = AntwortProtokoll.problemAufgaben([runde("Einmaleins", vorTagen: 1, viele)], limit: 8)
        #expect(liste.count == 8)
    }

    // MARK: Beispieldaten

    @Test func beispieldatenPassenZuDenZahlen() {
        for uebung in ["Einmaleins", "Teilen mit Rest", "Zahlenmauern", "Sachaufgaben"] {
            let liste = AntwortProtokoll.liste(aus: AntwortProtokoll.beispiel(uebung: uebung, gesamt: 10,
                                                                                richtig: 6, angesehen: 1))
            #expect(liste.count == 10)
            #expect(liste.filter { $0.stand == AntwortStand.richtig }.count == 6)
            #expect(liste.filter { $0.stand == AntwortStand.angeschaut }.count == 1)
            #expect(liste.filter { $0.stand == AntwortStand.falsch }.count == 3)
            for d in liste where d.stand == AntwortStand.falsch {
                #expect(d.eingabe != d.loesung)
            }
        }
    }
}
