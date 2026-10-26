import Foundation
import Testing
@testable import YEM1N

// Einwilligung und die Rechtstexte in der App.

@MainActor
struct RechtTests {

    private let kalender = Calendar(identifier: .gregorian)

    private var jetzt: Date {
        DateComponents(calendar: kalender, year: 2026, month: 10, day: 7, hour: 12).date ?? Date.now
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

    @Test func dieEinwilligungKenntDenFamilienDienst() {
        // Version 5: Familien-Dienst statt Familiencode. Ältere Zustimmungen gelten nicht mehr.
        #expect(Einwilligung.aktuelleVersion >= 5)
        #expect(Einwilligung.erforderlich(gespeicherteVersion: 4))
    }

    @Test func hinweiseSagenWasNichtHineingehoert() {
        #expect(RechtHinweise.freitext.contains("Nachnamen"))
        #expect(RechtHinweise.name.contains("Nachnamen"))
    }
}
