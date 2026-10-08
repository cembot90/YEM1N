import Foundation
import Testing
@testable import YEM1N

// Das Widget zeigt nur, was die App in die App Group legt. Wenn dieser Stand
// falsch ist, steht am Sperrbildschirm etwas Falsches.

@MainActor
struct WidgetBrueckeTests {

    private var kal: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "UTC") ?? TimeZone.current
        return k
    }

    private var start: Date {
        kal.date(from: DateComponents(year: 2026, month: 10, day: 8, hour: 12)) ?? Date.now
    }

    private func tier(satt: Double = 80, laune: Double = 80, xp: Int = 5) -> Haustier {
        var h = Haustier(name: "Pip", art: "katze", jetzt: start)
        h.xp = xp
        h.satt = satt
        h.laune = laune
        return h
    }

    private func leererSpeicher(_ name: String) -> UserDefaults {
        let speicher = UserDefaults(suiteName: name) ?? UserDefaults.standard
        speicher.removePersistentDomain(forName: name)
        return speicher
    }

    @Test func ohneHaustierLaedtDasWidgetZumAussuchenEin() {
        let s = WidgetBruecke.stand(haustier: nil, serie: 3, jetzt: start)
        #expect(!s.vorhanden)
        #expect(s.serie == 3)
        #expect(s.text.contains("Haustier"))
    }

    @Test func einFroheresTierMeldetSichMitNameBildUndText() {
        let s = WidgetBruecke.stand(haustier: tier(), serie: 5, jetzt: start)
        #expect(s.vorhanden)
        #expect(s.name == "Pip")
        #expect(s.emoji == "🐱")
        #expect(s.text == "ist froh")
        #expect(s.stufe == "Baby")
    }

    @Test func dasWidgetWeissWannDasTierHungrigWird() {
        // Satt 80: nach 20 Stunden bei 30
        let s = WidgetBruecke.stand(haustier: tier(satt: 80), serie: 0, jetzt: start)
        #expect(s.hungrigAb == start.addingTimeInterval(20 * 3600))
    }

    @Test func einHungrigesTierHatKeinenHungrigAbZeitpunkt() {
        let s = WidgetBruecke.stand(haustier: tier(satt: 10), serie: 0, jetzt: start)
        #expect(s.hungrigAb == nil)
        #expect(s.text == "hat Hunger")
    }

    @Test func dasEiHatKeinenHunger() {
        let ei = Haustier(name: "Pip", art: "katze", jetzt: start)
        let s = WidgetBruecke.stand(haustier: ei, serie: 0, jetzt: start)
        #expect(s.hungrigAb == nil)
        #expect(s.emoji == "🥚")
        #expect(s.text.contains("Schlüpfen"))
    }

    @Test func derHutKommtMitInsWidget() {
        var h = tier()
        h.kaufe(hut: "krone") { _ in true }
        let s = WidgetBruecke.stand(haustier: h, serie: 0, jetzt: start)
        #expect(s.hut == "👑")
    }

    @Test func dieSerieLebtBisZumEndeDesTagesNachDerLetztenRunde() {
        // Letzte Runde am 8. Oktober: gültig bis zum Beginn des 10. Oktober
        let bis = WidgetBruecke.serieBis(letzteRunde: start, kalender: kal)
        #expect(bis == kal.date(from: DateComponents(year: 2026, month: 10, day: 10)))
        #expect(WidgetBruecke.serieBis(letzteRunde: nil, kalender: kal) == nil)
    }

    @Test func derStandLandetInDerGemeinsamenAblage() {
        let ich = leererSpeicher("widget-test-ich")
        let gemeinsam = leererSpeicher("widget-test-gemeinsam")
        HaustierSpeicher.sichern(tier(), speicher: ich)
        WidgetBruecke.aktualisieren(serie: 4, letzteRunde: start, speicher: ich,
                                    gemeinsam: gemeinsam, jetzt: start, neuLaden: false)
        let daten = gemeinsam.data(forKey: WidgetBruecke.key)
        let stand = daten.flatMap { try? JSONDecoder().decode(WidgetStand.self, from: $0) }
        #expect(stand?.name == "Pip")
        #expect(stand?.serie == 4)
        #expect(stand?.serieBis != nil)
    }

    @Test func dieSerieBleibtErhaltenWennNurDasTierSichAendert() {
        let ich = leererSpeicher("widget-test-serie")
        let gemeinsam = leererSpeicher("widget-test-serie-gemeinsam")
        WidgetBruecke.aktualisieren(serie: 6, letzteRunde: start, speicher: ich,
                                    gemeinsam: gemeinsam, jetzt: start, neuLaden: false)
        HaustierSpeicher.sichern(tier(), speicher: ich)
        WidgetBruecke.aktualisieren(speicher: ich, gemeinsam: gemeinsam, jetzt: start, neuLaden: false)
        let stand = gemeinsam.data(forKey: WidgetBruecke.key)
            .flatMap { try? JSONDecoder().decode(WidgetStand.self, from: $0) }
        #expect(stand?.serie == 6)
        #expect(stand?.vorhanden == true)
    }
}
