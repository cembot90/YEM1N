import Foundation
import Testing
@testable import YEM1N

// Die Eltern füttern das Tier über die Cloud. Diese Tests prüfen die Regeln dahinter:
// Tageslimit, Verfall alter Einträge und dass jeder Eintrag nur einmal wirkt.

@MainActor
struct HaustierCloudTests {

    private var kal: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "UTC") ?? TimeZone.current
        return k
    }

    private var jetzt: Date {
        kal.date(from: DateComponents(year: 2026, month: 10, day: 8, hour: 12)) ?? Date.now
    }

    private func tag(_ versatz: Int) -> String {
        let d = kal.date(byAdding: .day, value: versatz, to: jetzt) ?? jetzt
        return Haustier.tagKennung(d, kalender: kal)
    }

    private func eintrag(_ art: String, _ versatz: Int) -> PflegeEintrag {
        PflegeEintrag(name: HaustierPflege.eintragName(code: "ABC", art: art, tag: tag(versatz)),
                      art: art, tag: tag(versatz))
    }

    private func hungrigesTier() -> Haustier {
        var h = Haustier(name: "Pip", art: "katze", jetzt: jetzt)
        h.xp = 5
        h.satt = 20
        h.laune = 20
        return h
    }

    @Test func derEintragsnameEnthaeltTagUndArt() {
        #expect(HaustierPflege.eintragName(code: "ABC", art: "leckerli", tag: "2026-10-8")
                == "pflege-ABC-2026-10-8-leckerli")
    }

    @Test func proTagUndArtGibtEsNurEinenEintrag() {
        let heute = tag(0)
        let vorhanden = [eintrag("leckerli", 0), eintrag("spielen", -1)]
        #expect(HaustierPflege.gegeben("leckerli", heute: heute, vorhandene: vorhanden))
        #expect(!HaustierPflege.gegeben("spielen", heute: heute, vorhandene: vorhanden))
    }

    @Test func nurHeuteUndGesternWirken() {
        let alle = [eintrag("leckerli", 0), eintrag("spielen", -1), eintrag("leckerli", -3)]
        let neu = HaustierPflege.neue(alle, angewandt: [], jetzt: jetzt, kalender: kal)
        #expect(neu.count == 2)
        #expect(!neu.contains(eintrag("leckerli", -3)))
    }

    @Test func einEintragWirktNurEinmal() {
        let alle = [eintrag("leckerli", 0), eintrag("spielen", 0)]
        let schon: Set<String> = [alle[0].name]
        let neu = HaustierPflege.neue(alle, angewandt: schon, jetzt: jetzt, kalender: kal)
        #expect(neu == [alle[1]])
    }

    @Test func leckerliMachtSattUndSpielenMachtFroh() {
        var h = hungrigesTier()
        let satt = h.satt
        let laune = h.laune
        let gewirkt = HaustierPflege.anwenden([eintrag("leckerli", 0), eintrag("spielen", 0)],
                                              auf: &h, jetzt: jetzt)
        #expect(gewirkt == 2)
        #expect(h.satt > satt)
        #expect(h.laune > laune)
    }

    @Test func einEiNimmtNichtsAn() {
        var h = Haustier(name: "Pip", art: "katze", jetzt: jetzt)
        let gewirkt = HaustierPflege.anwenden([eintrag("leckerli", 0)], auf: &h, jetzt: jetzt)
        #expect(gewirkt == 0)
    }

    @Test func einSattesTierNimmtKeinLeckerliMehr() {
        var h = hungrigesTier()
        h.satt = 100
        let gewirkt = HaustierPflege.anwenden([eintrag("leckerli", 0)], auf: &h, jetzt: jetzt)
        #expect(gewirkt == 0)
    }

    @Test func eineUnbekannteArtTutNichts() {
        var h = hungrigesTier()
        let vorher = h
        let gewirkt = HaustierPflege.anwenden([PflegeEintrag(name: "x", art: "gift", tag: tag(0))],
                                              auf: &h, jetzt: jetzt)
        #expect(gewirkt == 0)
        #expect(h.satt == vorher.satt)
    }

    @Test func dasTierBleibtImTextUnveraendert() {
        var h = hungrigesTier()
        h.huete = ["brille"]
        h.hut = "brille"
        let text = HaustierPflege.text(h)
        #expect(!text.isEmpty)
        #expect(HaustierPflege.haustier(aus: text) == h)
        #expect(HaustierPflege.haustier(aus: "kaputt") == nil)
    }
}
