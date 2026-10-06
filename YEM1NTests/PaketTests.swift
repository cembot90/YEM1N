import Foundation
import Testing
@testable import YEM1N

// Der Import der Aufgabenpakete. Ein kaputtes Paket darf die App
// nicht durcheinanderbringen, es muss sauber abgelehnt werden.

@MainActor
struct PaketTests {

    // MARK: Gültige Pakete

    @Test func einGutesPaketWirdGelesen() {
        let gelesen = PaketAktion.lese(testPaketJSON)
        #expect(gelesen != nil)
        #expect(gelesen?.paket.arbeit == "Testarbeit Nr. 1")
        #expect(gelesen?.paket.klasse == "Klasse 3")
        #expect(gelesen?.paket.fach == "Mathe")
        #expect(gelesen?.paket.uebungen.count == 1)
        if let p = gelesen?.paket {
            #expect(PaketAktion.anzahl(p) == 2)
            #expect(p.uebungen[0].aufgaben[0].antwort == "56")
            #expect(p.uebungen[0].aufgaben[1].antwort2 == "2")
        }
    }

    @Test func textUmDasJSONHerumStoertNicht() {
        let mitDrumherum = "Hier ist deine Klassenarbeit:\n```json\n" + testPaketJSON + "\n```\nViel Erfolg!"
        #expect(PaketAktion.lese(mitDrumherum) != nil)
    }

    @Test func antwortenDuerfenAuchZahlenSein() {
        let json = """
        {"klasse": "Klasse 3", "fach": "Mathe", "arbeit": "Zahlen", "uebungen": [
          {"titel": "Einmaleins", "aufgaben": [
            {"art": "zahl", "frage": "Rechne.", "rechnung": "7 · 8 =", "antwort": 56}
          ]}
        ]}
        """
        let gelesen = PaketAktion.lese(json)
        #expect(gelesen?.paket.uebungen[0].aufgaben[0].antwort == "56")
    }

    @Test func gruppeUndSymbolDuerfenFehlen() {
        let json = """
        {"klasse": "Klasse 3", "fach": "Mathe", "arbeit": "Sparsam", "uebungen": [
          {"titel": "Einmaleins", "aufgaben": [
            {"art": "zahl", "frage": "Rechne.", "rechnung": "2 · 3 =", "antwort": "6"}
          ]}
        ]}
        """
        #expect(PaketAktion.lese(json) != nil)
    }

    // MARK: Kaputte Pakete

    @Test func unsinnWirdAbgelehnt() {
        #expect(PaketAktion.lese("") == nil)
        #expect(PaketAktion.lese("Guten Morgen") == nil)
        #expect(PaketAktion.lese("{kein gueltiges json") == nil)
        #expect(PaketAktion.lese("[1, 2, 3]") == nil)
    }

    @Test func einPaketOhneUebungenWirdAbgelehnt() {
        let json = """
        {"klasse": "Klasse 3", "fach": "Mathe", "arbeit": "Leer", "uebungen": []}
        """
        #expect(PaketAktion.lese(json) == nil)
    }

    @Test func eineUebungOhneAufgabenWirdAbgelehnt() {
        let json = """
        {"klasse": "Klasse 3", "fach": "Mathe", "arbeit": "Leer", "uebungen": [
          {"titel": "Nichts", "aufgaben": []}
        ]}
        """
        #expect(PaketAktion.lese(json) == nil)
    }

    @Test func einFehlenderKopfWirdAbgelehnt() {
        let json = """
        {"fach": "Mathe", "arbeit": "Ohne Klasse", "uebungen": [
          {"titel": "Einmaleins", "aufgaben": [{"art": "zahl", "antwort": "6"}]}
        ]}
        """
        #expect(PaketAktion.lese(json) == nil)
    }

    // MARK: Vorschule, Aufgaben zum Antippen

    private func wahlPaket(optionen: String, antwort: String, frage: String = "Wie viele sind das?") -> String {
        """
        {"klasse": "Vorschule", "fach": "Vorschule", "arbeit": "Zählen", "uebungen": [
          {"titel": "Zählen", "aufgaben": [
            {"art": "wahl", "frage": "\(frage)", "optionen": \(optionen), "antwort": "\(antwort)"}
          ]}
        ]}
        """
    }

    @Test func eineGueltigeWahlaufgabeWirdAngenommen() {
        #expect(PaketAktion.lese(wahlPaket(optionen: "[\"3\", \"4\"]", antwort: "4")) != nil)
        #expect(PaketAktion.lese(wahlPaket(optionen: "[\"3\", \"4\", \"5\", \"6\"]", antwort: "5")) != nil)
    }

    @Test func zuWenigeOderZuVieleKnoepfeWerdenAbgelehnt() {
        #expect(PaketAktion.lese(wahlPaket(optionen: "[\"4\"]", antwort: "4")) == nil)
        #expect(PaketAktion.lese(wahlPaket(optionen: "[\"1\", \"2\", \"3\", \"4\", \"5\"]", antwort: "4")) == nil)
    }

    @Test func dieAntwortMussEinerDerKnoepfeSein() {
        #expect(PaketAktion.lese(wahlPaket(optionen: "[\"3\", \"4\"]", antwort: "9")) == nil)
    }

    @Test func eineWahlaufgabeOhneFrageWirdAbgelehnt() {
        #expect(PaketAktion.lese(wahlPaket(optionen: "[\"3\", \"4\"]", antwort: "4", frage: "")) == nil)
    }

    // MARK: Erzeugen und wieder einlesen

    @Test func eineErzeugteArbeitLaesstSichWiederEinlesen() {
        let arbeit = MatheGenerator.neueArbeit(titel: "Rundlauf",
                                               klasse: "Klasse 3",
                                               fach: "Mathe",
                                               ausschluss: [])
        let text = arbeit.jsonText()
        #expect(!text.isEmpty, "Die Arbeit ließ sich nicht als JSON schreiben")

        guard let gelesen = PaketAktion.lese(text) else {
            Issue.record("Die selbst erzeugte Arbeit wurde beim Einlesen abgelehnt")
            return
        }
        #expect(gelesen.paket.arbeit == "Rundlauf")
        #expect(gelesen.paket.uebungen.count == arbeit.uebungen.count)

        let erwartet = arbeit.uebungen.reduce(0) { $0 + $1.aufgaben.count }
        #expect(PaketAktion.anzahl(gelesen.paket) == erwartet)

        for (ein, aus) in zip(arbeit.uebungen, gelesen.paket.uebungen) {
            #expect(ein.titel == aus.titel)
            #expect(ein.aufgaben.count == aus.aufgaben.count)
        }
    }

    @Test func zahlenmauernUeberlebenDenRundlauf() {
        var sperre = Set<String>()
        guard let vorlage = MatheGenerator.vorlagen.first(where: { $0.id == "mauer" }) else {
            Issue.record("Die Vorlage für Zahlenmauern fehlt")
            return
        }
        let uebung = MatheGenerator.uebung(vorlage, ausschluss: &sperre)
        let arbeit = MatheArbeit(klasse: "Klasse 3", fach: "Mathe", titel: "Mauern", uebungen: [uebung])

        guard let gelesen = PaketAktion.lese(arbeit.jsonText()) else {
            Issue.record("Mauern wurden beim Einlesen abgelehnt")
            return
        }
        for (ein, aus) in zip(uebung.aufgaben, gelesen.paket.uebungen[0].aufgaben) {
            #expect(aus.art == "mauer")
            #expect(aus.reihen == ein.reihen, "Die Mauer kam anders zurück als sie hineinging")
        }
    }
}
