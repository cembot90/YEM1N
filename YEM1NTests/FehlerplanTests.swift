import Foundation
import Testing
@testable import YEM1N

// Ein Fehler ist erst gemeistert, wenn er nach ein paar Tagen noch einmal
// richtig war. Sonst übt das Kind nur das Kurzzeitgedächtnis.

@MainActor
struct FehlerplanTests {

    private var kal: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "UTC") ?? TimeZone.current
        return k
    }

    private var start: Date {
        kal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12)) ?? Date.now
    }

    private func tage(_ n: Int) -> Date {
        kal.date(byAdding: .day, value: n, to: start) ?? start
    }

    private func leererSpeicher(_ name: String) -> UserDefaults {
        let speicher = UserDefaults(suiteName: name) ?? UserDefaults.standard
        speicher.removePersistentDomain(forName: name)
        return speicher
    }

    @Test func einNeuerFehlerIstSofortDran() {
        let s = leererSpeicher("fehlerplan-test-neu")
        #expect(Fehlerplan.istFaellig("a", jetzt: start, speicher: s))
        #expect(Fehlerplan.faelligAb("a", speicher: s) == nil)
    }

    @Test func nachDerErstenRichtigenAntwortKommtDerFehlerInDreiTagenWieder() {
        let s = leererSpeicher("fehlerplan-test-erste")
        let gemeistert = Fehlerplan.richtig("a", jetzt: start, speicher: s, kalender: kal)
        #expect(!gemeistert)
        #expect(!Fehlerplan.istFaellig("a", jetzt: start, speicher: s))
        #expect(!Fehlerplan.istFaellig("a", jetzt: tage(2), speicher: s))
        #expect(Fehlerplan.istFaellig("a", jetzt: tage(3), speicher: s))
    }

    @Test func dieZweiteRichtigeAntwortMeistertDenFehler() {
        let s = leererSpeicher("fehlerplan-test-zweite")
        Fehlerplan.richtig("a", jetzt: start, speicher: s, kalender: kal)
        let gemeistert = Fehlerplan.richtig("a", jetzt: tage(3), speicher: s, kalender: kal)
        #expect(gemeistert)
        #expect(Fehlerplan.faelligAb("a", speicher: s) == nil, "Der Eintrag wird aufgeräumt")
    }

    @Test func eineFalscheAntwortStelltDenFehlerAufAnfang() {
        let s = leererSpeicher("fehlerplan-test-falsch")
        Fehlerplan.richtig("a", jetzt: start, speicher: s, kalender: kal)
        Fehlerplan.falsch("a", jetzt: tage(3), speicher: s, kalender: kal)
        #expect(!Fehlerplan.istFaellig("a", jetzt: tage(3), speicher: s))
        #expect(Fehlerplan.istFaellig("a", jetzt: tage(4), speicher: s), "Schon morgen wieder")
        // Danach braucht es wieder zwei richtige Antworten
        #expect(!Fehlerplan.richtig("a", jetzt: tage(4), speicher: s, kalender: kal))
        #expect(Fehlerplan.richtig("a", jetzt: tage(7), speicher: s, kalender: kal))
    }

    @Test func dieFehlerSindUnabhaengigVoneinander() {
        let s = leererSpeicher("fehlerplan-test-mehrere")
        Fehlerplan.richtig("a", jetzt: start, speicher: s, kalender: kal)
        #expect(!Fehlerplan.istFaellig("a", jetzt: start, speicher: s))
        #expect(Fehlerplan.istFaellig("b", jetzt: start, speicher: s))
    }

    @Test func dieFaelligkeitLiegtImmerAmTagesanfang() {
        // Ein Fehler vom Abend ist am dritten Tag morgens wieder da, nicht erst abends
        let s = leererSpeicher("fehlerplan-test-tagesanfang")
        let abend = kal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 21)) ?? start
        Fehlerplan.richtig("a", jetzt: abend, speicher: s, kalender: kal)
        let drittenTagMorgens = kal.date(from: DateComponents(year: 2026, month: 10, day: 10, hour: 7)) ?? start
        #expect(Fehlerplan.istFaellig("a", jetzt: drittenTagMorgens, speicher: s))
    }
}

@MainActor
struct FehlerplanTabelleTests {
    @Test func ohneEintragIstEinFehlerSofortDran() {
        #expect(Fehlerplan.istFaellig("a|b", in: [:]))
    }

    @Test func dieTabelleEntscheidetNachDemZeitpunkt() {
        let jetzt = Date(timeIntervalSince1970: 1_000_000)
        let tabelle = ["spaeter": 1_000_100.0, "frueher": 999_900.0]
        #expect(!Fehlerplan.istFaellig("spaeter", in: tabelle, jetzt: jetzt))
        #expect(Fehlerplan.istFaellig("frueher", in: tabelle, jetzt: jetzt))
    }
}
