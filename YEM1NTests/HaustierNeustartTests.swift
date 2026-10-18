import Foundation
import Testing
@testable import YEM1N

// Mit dem großen Haustier-Update fangen alle einmal mit einem neuen Ei an.
// Das darf nur genau einmal passieren, und niemand verliert dabei Münzen.

@MainActor
struct HaustierNeustartTests {

    private func leererSpeicher() -> UserDefaults {
        let name = "neustart-test-\(UUID().uuidString)"
        let speicher = UserDefaults(suiteName: name) ?? .standard
        speicher.removePersistentDomain(forName: name)
        return speicher
    }

    private func tier(huete: [String] = []) -> Haustier {
        var h = Haustier(name: "Luna", art: "hund")
        h.xp = 300
        h.huete = huete
        h.hut = huete.first ?? ""
        return h
    }

    @Test func dasAlteTierZiehtUmUndDieHutMuenzenKommenDoppeltZurueck() {
        let speicher = leererSpeicher()
        HaustierSpeicher.sichern(tier(huete: ["brille", "krone"]), speicher: speicher)
        speicher.set(true, forKey: Eule.einfuehrungKey)
        var gutgeschrieben = 0
        let a = HaustierNeustart.durchfuehren(speicher: speicher) { gutgeschrieben += $0 }
        #expect(a == HaustierNeustart.Abschied(name: "Luna", art: "hund", muenzen: 220))
        #expect(gutgeschrieben == 220, "Sonnenbrille 30 und Krone 80, mal zwei")
        #expect(HaustierSpeicher.laden(speicher: speicher) == nil)
        #expect(!speicher.bool(forKey: Eule.einfuehrungKey), "Olli stellt sich für das neue Ei wieder vor")
        let brief = HaustierNeustart.dekodiere(speicher.data(forKey: HaustierNeustart.abschiedKey) ?? Data())
        #expect(brief == a)
    }

    @Test func derNeustartPassiertNurEinmal() {
        let speicher = leererSpeicher()
        HaustierSpeicher.sichern(tier(huete: ["kappe"]), speicher: speicher)
        var gutgeschrieben = 0
        HaustierNeustart.durchfuehren(speicher: speicher) { gutgeschrieben += $0 }
        // Das Kind sucht sich ein neues Tier aus, dann startet die App wieder
        HaustierSpeicher.sichern(tier(), speicher: speicher)
        let zweites = HaustierNeustart.durchfuehren(speicher: speicher) { gutgeschrieben += $0 }
        #expect(zweites == nil)
        #expect(gutgeschrieben == 60)
        #expect(HaustierSpeicher.laden(speicher: speicher) != nil, "Das neue Tier bleibt")
    }

    @Test func ohneTierPassiertNichtsAuchNichtSpaeter() {
        let speicher = leererSpeicher()
        var gutgeschrieben = 0
        let erstes = HaustierNeustart.durchfuehren(speicher: speicher) { gutgeschrieben += $0 }
        #expect(erstes == nil)
        // Wer erst nach dem Update ein Tier bekommt, behält es
        HaustierSpeicher.sichern(tier(), speicher: speicher)
        let spaeter = HaustierNeustart.durchfuehren(speicher: speicher) { gutgeschrieben += $0 }
        #expect(spaeter == nil)
        #expect(HaustierSpeicher.laden(speicher: speicher) != nil)
        #expect(gutgeschrieben == 0)
        #expect(speicher.data(forKey: HaustierNeustart.abschiedKey) == nil)
    }

    @Test func ohneHuteGibtEsKeineErstattung() {
        let speicher = leererSpeicher()
        HaustierSpeicher.sichern(tier(), speicher: speicher)
        var aufgerufen = false
        let a = HaustierNeustart.durchfuehren(speicher: speicher) { _ in aufgerufen = true }
        #expect(a?.muenzen == 0)
        #expect(!aufgerufen)
    }

    @Test func ollisBriefIstFreundlichUndStimmt() {
        let mit = HaustierNeustart.brief(.init(name: "Luna", art: "hund", muenzen: 220))
        #expect(mit.contains("Luna"))
        #expect(mit.contains("Eulenhof"))
        #expect(mit.contains("220 Münzen"))
        let ohne = HaustierNeustart.brief(.init(name: "Luna", art: "hund", muenzen: 0))
        #expect(!ohne.contains("Münzen"))
        #expect(ohne.contains("neues Ei"))
        for text in [mit, ohne] {
            #expect(!text.contains("\u{2013}") && !text.contains("\u{2014}"))
        }
    }
}
