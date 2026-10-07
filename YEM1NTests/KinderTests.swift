import Foundation
import Testing
@testable import YEM1N

// Die Kinderliste im Eltern-Gerät. Ein Kind darf nicht doppelt auftauchen,
// nur weil ein Leerzeichen oder ein Großbuchstabe anders war.

@MainActor
struct KinderTests {

    private let kalender = Calendar(identifier: .gregorian)

    private var jetzt: Date {
        DateComponents(calendar: kalender, year: 2026, month: 10, day: 7, hour: 12).date ?? Date.now
    }

    private func vor(tagen: Int) -> Date {
        kalender.date(byAdding: .day, value: -tagen, to: jetzt) ?? jetzt
    }

    /// Ein eigener, leerer Speicher, damit die Tests nichts verfälschen.
    private func leererSpeicher(_ name: String) -> UserDefaults {
        let speicher = UserDefaults(suiteName: name) ?? UserDefaults.standard
        speicher.removePersistentDomain(forName: name)
        return speicher
    }

    @Test func gleicheNamenWerdenErkannt() {
        #expect(Kinder.gleich("Yemin", "Yemin"))
        #expect(Kinder.gleich("Yemin", "Yemin "))
        #expect(Kinder.gleich("Yemin", " yemin"))
        #expect(Kinder.gleich("Evîn", "Evin"))
        #expect(!Kinder.gleich("Yemin", "Evin"))
    }

    @Test func zweiSchreibweisenSindEinKind() {
        let eintraege: [(name: String, zeitpunkt: Date)] = [
            (name: "Yemin", zeitpunkt: vor(tagen: 5)),
            (name: "Yemin ", zeitpunkt: vor(tagen: 2)),
            (name: "yemin", zeitpunkt: vor(tagen: 9))
        ]
        let liste = Kinder.liste(aus: eintraege)
        #expect(liste.count == 1, "Aus drei Schreibweisen muss ein Kind werden")
        #expect(liste.first?.runden == 3)
        #expect(liste.first?.name == "Yemin", "Es zählt die Schreibweise der neuesten Runde")
        #expect(liste.first?.zuletzt == vor(tagen: 2))
    }

    @Test func verschiedeneKinderBleibenGetrennt() {
        let eintraege: [(name: String, zeitpunkt: Date)] = [
            (name: "Yemin", zeitpunkt: vor(tagen: 1)),
            (name: "Evîn", zeitpunkt: vor(tagen: 3)),
            (name: "Yemin", zeitpunkt: vor(tagen: 0))
        ]
        let liste = Kinder.liste(aus: eintraege)
        #expect(liste.count == 2)
        #expect(liste.map { $0.name } == ["Evîn", "Yemin"], "Sortiert nach Name")
        #expect(liste.first { $0.name == "Yemin" }?.runden == 2)
    }

    @Test func leereNamenFallenWeg() {
        let eintraege: [(name: String, zeitpunkt: Date)] = [
            (name: "", zeitpunkt: vor(tagen: 1)),
            (name: "   ", zeitpunkt: vor(tagen: 1))
        ]
        #expect(Kinder.liste(aus: eintraege).isEmpty)
    }

    @Test func entfernenVerstecktAltesAberNichtNeues() {
        let speicher = leererSpeicher("yem1n.test.kinder1")
        let grenze = jetzt
        #expect(!Kinder.istEntfernt("Yemin", zeitpunkt: vor(tagen: 3), speicher: speicher))

        Kinder.entfernen("Yemin", am: grenze, speicher: speicher)
        #expect(Kinder.istEntfernt("Yemin", zeitpunkt: vor(tagen: 3), speicher: speicher))
        #expect(Kinder.istEntfernt("yemin ", zeitpunkt: vor(tagen: 1), speicher: speicher),
                "Auch eine andere Schreibweise ist entfernt")

        let spaeter = grenze.addingTimeInterval(60)
        #expect(!Kinder.istEntfernt("Yemin", zeitpunkt: spaeter, speicher: speicher),
                "Spielt das Kind später weiter, kommt es wieder")
        #expect(!Kinder.istEntfernt("Evin", zeitpunkt: vor(tagen: 3), speicher: speicher),
                "Andere Kinder sind nicht betroffen")
    }

    @Test func zuletztTextIstVerstaendlich() {
        #expect(Kinder.zuletztText(jetzt, jetzt: jetzt, kalender: kalender) == "heute")
        #expect(Kinder.zuletztText(vor(tagen: 1), jetzt: jetzt, kalender: kalender) == "gestern")
        #expect(Kinder.zuletztText(vor(tagen: 5), jetzt: jetzt, kalender: kalender) == "vor 5 Tagen")
        #expect(Kinder.zuletztText(vor(tagen: 21), jetzt: jetzt, kalender: kalender) == "vor 3 Wochen")
        #expect(Kinder.zuletztText(vor(tagen: 90), jetzt: jetzt, kalender: kalender) == "vor 3 Monaten")
    }

    @Test func tageSeitWirdNieNegativ() {
        let zukunft = jetzt.addingTimeInterval(86_400 * 3)
        #expect(Kinder.tageSeit(zukunft, jetzt: jetzt, kalender: kalender) == 0)
        #expect(Kinder.tageSeit(vor(tagen: 30), jetzt: jetzt, kalender: kalender) >= Kinder.langeInaktivTage)
    }
}
