import Foundation
import Testing
@testable import YEM1N

// Der Wochenbericht in Worten und die Prüfung der KI-Texte.
// Die KI darf nur umformulieren. Erfindet sie eine Zahl, wird ihr Text verworfen.

@MainActor
struct ElternBerichtTests {

    private var kalender: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return k
    }

    private func datum(_ text: String) -> Date {
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone(identifier: "Europe/Berlin")
        return f.date(from: text)!
    }

    private func runde(_ uebung: String, richtig: Int, gesamt: Int, angesehen: Int = 0,
                       am: Date, details: [AntwortDetail] = []) -> BerichtRunde {
        BerichtRunde(kind: "Yemin", uebung: uebung, zeitpunkt: am, richtig: richtig, gesamt: gesamt,
                     angesehen: angesehen, details: AntwortProtokoll.json(details))
    }

    private func restFehler(_ nr: Int) -> AntwortDetail {
        AntwortDetail(nr: nr, frage: "Teile mit Rest.", rechnung: "48 : 4 =",
                      eingabe: "10 Rest 8", loesung: "12 Rest 0", stand: AntwortStand.falsch)
    }

    // MARK: KI-Prüfung

    @Test func kiTextMitErfundenerZahlWirdVerworfen() {
        let fakten = "Aufgabe: 7 · 8 =\nRichtig ist: 56"
        #expect(KIText.istBrauchbar("Sieben mal acht sind 56. Super gemacht!", fakten: fakten, maxZeichen: 300))
        #expect(!KIText.istBrauchbar("7 · 8 sind 54, fast richtig!", fakten: fakten, maxZeichen: 300))
    }

    @Test func kiTextZuLangOderLeer() {
        #expect(!KIText.istBrauchbar("", fakten: "1", maxZeichen: 300))
        #expect(!KIText.istBrauchbar(String(repeating: "a", count: 301), fakten: "", maxZeichen: 300))
    }

    @Test func bereinigtGedankenstricheUndMarkdown() {
        let t = KIText.bereinige("\"**Toll** \u{2014} weiter so\"")
        #expect(t == "Toll, weiter so")
        #expect(!t.contains("\u{2014}"))
    }

    @Test func zahlenImText() {
        #expect(KIText.zahlen(in: "48 : 4 = 12 Rest 0") == [48, 4, 12, 0])
    }

    // MARK: Auswertung

    @Test func zaehltRundenTageUndProzent() {
        let mo = datum("2026-10-12T16:00:00+02:00")
        let di = datum("2026-10-13T16:00:00+02:00")
        let b = ElternBericht.kindBericht(name: "Yemin", runden: [
            runde("Einmaleins", richtig: 10, gesamt: 10, am: mo),
            runde("Einmaleins", richtig: 9, gesamt: 10, am: di),
            runde("Teilen mit Rest", richtig: 4, gesamt: 10, angesehen: 2, am: di)
        ], kalender: kalender)
        #expect(b.runden == 3)
        #expect(b.tage == 2)
        #expect(b.richtig == 23)
        #expect(b.gesamt == 30)
        #expect(b.prozent == 77)
        #expect(b.angesehen == 2)
        #expect(b.stark == ["Einmaleins"])
        #expect(b.ueben == ["Teilen mit Rest"])
    }

    @Test func erkenntWiederkehrendenDenkfehler() {
        let tag = datum("2026-10-13T16:00:00+02:00")
        let b = ElternBericht.kindBericht(name: "Yemin", runden: [
            runde("Teilen mit Rest", richtig: 8, gesamt: 10, am: tag, details: [restFehler(1), restFehler(2)])
        ], kalender: kalender)
        #expect(b.muster.count == 1)
        #expect(b.muster.first?.muster == .restZuGross)
        #expect(b.muster.first?.anzahl == 2)
        #expect(b.muster.first?.beispiel == "48 : 4, geschrieben 10 Rest 8, richtig 12 Rest 0")
    }

    @Test func einzelnerFehlerIstNochKeinMuster() {
        let tag = datum("2026-10-13T16:00:00+02:00")
        let b = ElternBericht.kindBericht(name: "Yemin", runden: [
            runde("Teilen mit Rest", richtig: 9, gesamt: 10, am: tag, details: [restFehler(1)])
        ], kalender: kalender)
        #expect(b.muster.isEmpty)
    }

    @Test func textEnthaeltZahlenBefundUndTipp() {
        let tag = datum("2026-10-13T16:00:00+02:00")
        let b = ElternBericht.kindBericht(name: "Yemin", runden: [
            runde("Teilen mit Rest", richtig: 2, gesamt: 10, am: tag, details: [restFehler(1), restFehler(2)])
        ], kalender: kalender)
        let t = ElternBericht.text(b)
        #expect(t.contains("Yemin hat in den letzten 7 Tagen an 1 Tag geübt, 1 Runde mit 10 Aufgaben."))
        #expect(t.contains("20 Prozent"))
        #expect(t.contains("Yemin hört beim Teilen mit Rest zu früh auf"))
        #expect(t.contains("Tipp für zu Hause:"))
        #expect(!t.contains("\u{2014}") && !t.contains("\u{2013}"))
    }

    @Test func ohneRundenEinSatz() {
        let t = ElternBericht.text(KindBericht(name: ""))
        #expect(t == "Euer Kind hat in den letzten 7 Tagen nicht in YEM1N geübt.")
    }

    @Test func nurDieLetztenSiebenTage() {
        let jetzt = datum("2026-10-13T20:00:00+02:00")
        let alt = datum("2026-10-06T20:00:00+02:00")
        let neu = datum("2026-10-07T08:00:00+02:00")
        let liste = ElternBericht.berichte(runden: [
            runde("Einmaleins", richtig: 5, gesamt: 5, am: alt),
            runde("Einmaleins", richtig: 5, gesamt: 5, am: neu)
        ], kinder: ["Yemin"], jetzt: jetzt, kalender: kalender)
        #expect(liste.count == 1)
        #expect(liste.first?.runden == 1)
    }

    // MARK: Hinweis auf neuen Bericht

    @Test func hinweisAbSonntagAchtzehnUhr() {
        let sonntagAbend = datum("2026-10-18T18:30:00+02:00")
        let gelesenSamstag = datum("2026-10-17T10:00:00+02:00")
        #expect(ElternBericht.letzterTermin(jetzt: sonntagAbend, kalender: kalender)
                == datum("2026-10-18T18:00:00+02:00"))
        #expect(ElternBericht.neuerBerichtDa(jetzt: sonntagAbend, gelesen: gelesenSamstag,
                                             hatRunden: true, kalender: kalender))
        let gelesenJetzt = datum("2026-10-18T18:45:00+02:00")
        #expect(!ElternBericht.neuerBerichtDa(jetzt: datum("2026-10-19T09:00:00+02:00"), gelesen: gelesenJetzt,
                                              hatRunden: true, kalender: kalender))
    }

    @Test func keinHinweisOhneRunden() {
        #expect(!ElternBericht.neuerBerichtDa(gelesen: nil, hatRunden: false))
    }

    @Test func merkSchluesselIstStabil() {
        #expect(ElternBericht.merkSchluessel("abc") == ElternBericht.merkSchluessel("abc"))
        #expect(ElternBericht.merkSchluessel("abc") != ElternBericht.merkSchluessel("abd"))
    }
}
