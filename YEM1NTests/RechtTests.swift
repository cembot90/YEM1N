import Foundation
import Testing
@testable import YEM1N

// Einwilligung, Löschfrist und die Rechtstexte in der App.

@MainActor
struct RechtTests {

    private let kalender = Calendar(identifier: .gregorian)

    private var jetzt: Date {
        DateComponents(calendar: kalender, year: 2026, month: 10, day: 7, hour: 12).date ?? Date.now
    }

    private func vor(tagen: Int, von: Date? = nil) -> Date {
        kalender.date(byAdding: .day, value: -tagen, to: von ?? jetzt) ?? jetzt
    }

    private func leererSpeicher(_ name: String) -> UserDefaults {
        let speicher = UserDefaults(suiteName: name) ?? UserDefaults.standard
        speicher.removePersistentDomain(forName: name)
        return speicher
    }

    // MARK: Einwilligung

    @Test func ohneGespeicherteFassungIstEineEinwilligungNoetig() {
        #expect(Einwilligung.erforderlich(gespeicherteVersion: 0))
        #expect(!Einwilligung.erforderlich(gespeicherteVersion: Einwilligung.aktuelleVersion))
        #expect(!Einwilligung.erforderlich(gespeicherteVersion: Einwilligung.aktuelleVersion + 1))
    }

    @Test func eineNeueFassungVerlangtEineNeueEinwilligung() {
        let alt = max(Einwilligung.aktuelleVersion - 1, 0)
        #expect(Einwilligung.erforderlich(gespeicherteVersion: alt))
    }

    @Test func einwilligungWirdMitDatumGespeichert() {
        let speicher = leererSpeicher("yem1n.test.recht1")
        #expect(Einwilligung.datum(speicher: speicher) == nil)
        Einwilligung.speichern(speicher: speicher, jetzt: jetzt)
        #expect(speicher.integer(forKey: Einwilligung.versionKey) == Einwilligung.aktuelleVersion)
        let datum = Einwilligung.datum(speicher: speicher)
        #expect(datum != nil)
        #expect(abs((datum ?? .distantPast).timeIntervalSince(jetzt)) < 1)
    }

    @Test func widerrufLoeschtDieEinwilligung() {
        let speicher = leererSpeicher("yem1n.test.recht2")
        Einwilligung.speichern(speicher: speicher, jetzt: jetzt)
        Einwilligung.widerrufen(speicher: speicher)
        #expect(speicher.integer(forKey: Einwilligung.versionKey) == 0)
        #expect(Einwilligung.datum(speicher: speicher) == nil)
        #expect(Einwilligung.erforderlich(gespeicherteVersion: speicher.integer(forKey: Einwilligung.versionKey)))
    }

    @Test func datumTextIstLesbar() {
        #expect(Einwilligung.datumText(nil) == "noch nicht erteilt")
        #expect(Einwilligung.datumText(jetzt, kalender: kalender).contains("2026"))
    }

    // MARK: Löschfrist

    @Test func nachZwoelfMonatenIstEinEintragAbgelaufen() {
        #expect(!Loeschfrist.abgelaufen(erstellt: vor(tagen: 0), jetzt: jetzt, kalender: kalender))
        #expect(!Loeschfrist.abgelaufen(erstellt: vor(tagen: 364), jetzt: jetzt, kalender: kalender))
        #expect(Loeschfrist.abgelaufen(erstellt: vor(tagen: 366), jetzt: jetzt, kalender: kalender))
        #expect(Loeschfrist.abgelaufen(erstellt: vor(tagen: 1000), jetzt: jetzt, kalender: kalender))
    }

    @Test func eineZukunftsZeitLoeschtNichts() {
        #expect(!Loeschfrist.abgelaufen(erstellt: jetzt.addingTimeInterval(86_400 * 30), jetzt: jetzt, kalender: kalender))
    }

    @Test func dasAufraeumenLaeuftHoechstensEinmalAmTag() {
        let speicher = leererSpeicher("yem1n.test.recht3")
        #expect(Loeschfrist.faellig(speicher: speicher, jetzt: jetzt, kalender: kalender))
        Loeschfrist.gelaufen(speicher: speicher, jetzt: jetzt)
        #expect(!Loeschfrist.faellig(speicher: speicher, jetzt: jetzt.addingTimeInterval(3600), kalender: kalender))
        let morgen = kalender.date(byAdding: .day, value: 1, to: jetzt) ?? jetzt
        #expect(Loeschfrist.faellig(speicher: speicher, jetzt: morgen, kalender: kalender))
    }

    @Test func nurDieRichtigenTypenWerdenAufgeraeumt() {
        #expect(Loeschfrist.typen.contains("RundenErgebnis"))
        #expect(Loeschfrist.typen.contains("JokerAnfrage"))
        #expect(!Loeschfrist.typen.contains("Lernpaket"), "Aufgabenpakete bleiben")
        #expect(!Loeschfrist.typen.contains("KlassenSchluessel"), "Der Klassenschlüssel bleibt")
    }

    // MARK: Texte

    @Test func impressumEnthaeltDieNoetigenAngaben() {
        let alles = RechtTexte.impressum.map { $0.1 }.joined(separator: " ")
        #expect(alles.contains("Cem Aras"))
        #expect(alles.contains("65618 Selters"))
        #expect(alles.contains("@"))
        #expect(alles.contains("+49"))
    }

    @Test func rechtstexteHabenKeineGedankenstriche() {
        let texte = (RechtTexte.impressum + RechtTexte.beta).flatMap { [$0.0, $0.1] }
            + [RechtHinweise.name, RechtHinweise.freitext]
        for t in texte {
            #expect(!t.contains("\u{2014}") && !t.contains("\u{2013}"), "Gedankenstrich in: \(t)")
            #expect(!t.isEmpty)
        }
    }

    @Test func hinweiseSagenWasNichtHineingehoert() {
        #expect(RechtHinweise.freitext.contains("Nachnamen"))
        #expect(RechtHinweise.name.contains("Nachnamen"))
    }
}
