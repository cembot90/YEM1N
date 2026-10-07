import Foundation
import Testing
@testable import YEM1N

// Serie mit freiem Tag und Wochenziel. Ein verpasster Tag soll nicht
// alles zerstören, aber auch kein Schlupfloch sein.

@MainActor
struct SerieSchutzTests {

    private var kal: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "UTC") ?? TimeZone.current
        k.firstWeekday = 2
        k.minimumDaysInFirstWeek = 4
        return k
    }

    /// Mittwoch, 7. Oktober 2026
    private var heute: Date {
        kal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12)) ?? Date.now
    }

    private func tage(_ vor: [Int]) -> Set<Date> {
        Set(vor.map { n in
            kal.startOfDay(for: kal.date(byAdding: .day, value: -n, to: heute) ?? heute)
        })
    }

    private func serie(_ vor: [Int]) -> (laenge: Int, gerettet: Int) {
        Erfolge.serieMitSchutz(tage(vor), heute: heute, kalender: kal)
    }

    private func runde(_ tag: Int, stunde: Int, monat: Int = 10) -> RundenErgebnis {
        let d = kal.date(from: DateComponents(year: 2026, month: monat, day: tag, hour: stunde)) ?? heute
        return RundenErgebnis(klasse: "Klasse 3", fach: "Mathe", arbeit: "T", uebung: "E",
                              richtig: 10, gesamt: 10, angesehen: 0, zeitpunkt: d, quelle: "lokal")
    }

    private func leererSpeicher(_ name: String) -> UserDefaults {
        let speicher = UserDefaults(suiteName: name) ?? UserDefaults.standard
        speicher.removePersistentDomain(forName: name)
        return speicher
    }

    // MARK: Serie

    @Test func ohneLueckeWieBisher() {
        let s = serie([0, 1, 2])
        #expect(s.laenge == 3)
        #expect(s.gerettet == 0)
    }

    @Test func keineRundenKeineSerie() {
        let s = serie([])
        #expect(s.laenge == 0)
        #expect(s.gerettet == 0)
    }

    @Test func einFreierTagRettetDieSerie() {
        let s = serie([0, 2, 3])
        #expect(s.laenge == 3)
        #expect(s.gerettet == 1)
    }

    @Test func zweiVerpassteTageHintereinanderBeendenDieSerie() {
        let s = serie([0, 3, 4])
        #expect(s.laenge == 1)
        #expect(s.gerettet == 0)
    }

    @Test func derFreieTagGiltNurEinmalProWoche() {
        let s = serie([0, 2, 4])
        #expect(s.laenge == 2)
        #expect(s.gerettet == 1)
    }

    @Test func nachEinerWocheIstWiederEinFreierTagDrin() {
        let s = serie([0, 2, 3, 4, 5, 6, 7, 8, 10])
        #expect(s.laenge == 9)
        #expect(s.gerettet == 2)
    }

    @Test func heuteIstNochOffenUndZaehltNichtAlsVerpasst() {
        let s = serie([1, 2])
        #expect(s.laenge == 2)
        #expect(s.gerettet == 0)
    }

    @Test func gesternVerpasstHeuteNochOffenDieSerieIstNochZuRetten() {
        let s = serie([2, 3])
        #expect(s.laenge == 2)
        #expect(s.gerettet == 1)
    }

    @Test func zweiTageNichtsIstDieSerieWeg() {
        let s = serie([3, 4])
        #expect(s.laenge == 0)
    }

    @Test func mehrereRundenAmSelbenTagZaehlenEinmal() {
        let liste = [runde(7, stunde: 8), runde(7, stunde: 12), runde(6, stunde: 9)]
        let s = Erfolge.geschuetzteSerie(liste, heute: heute, kalender: kal)
        #expect(s.laenge == 2)
    }

    // MARK: Wochenziel

    @Test func dasWochenzielSindFuenfTageMitTagesziel() {
        #expect(Erfolge.wochenziel(tagesziel: 2) == 10)
        #expect(Erfolge.wochenziel(tagesziel: 1) == 5)
        #expect(Erfolge.wochenziel(tagesziel: 0) == 5)
    }

    @Test func dieWocheBeginntAmMontag() {
        let liste = [
            runde(4, stunde: 20),   // Sonntag davor
            runde(5, stunde: 8),    // Montag
            runde(6, stunde: 15),   // Dienstag
            runde(7, stunde: 9),    // Mittwoch, vor jetzt
            runde(7, stunde: 15)    // später als jetzt
        ]
        #expect(Erfolge.wochenRunden(liste, jetzt: heute, kalender: kal) == 3)
    }

    @Test func dieBelohnungGibtEsEinmalProWoche() {
        let s = leererSpeicher("serie-test-belohnung")
        var liste: [RundenErgebnis] = []
        for _ in 0..<10 { liste.append(runde(6, stunde: 10)) }
        #expect(Erfolge.belohnungAbholbar(liste, tagesziel: 2, jetzt: heute, kalender: kal, speicher: s))
        #expect(Erfolge.belohnungHolen(liste, tagesziel: 2, jetzt: heute, kalender: kal, speicher: s)
                == Erfolge.wochenBelohnung)
        #expect(!Erfolge.belohnungAbholbar(liste, tagesziel: 2, jetzt: heute, kalender: kal, speicher: s))
        #expect(Erfolge.belohnungHolen(liste, tagesziel: 2, jetzt: heute, kalender: kal, speicher: s) == 0)
    }

    @Test func ohneGeschaffesWochenzielKeineBelohnung() {
        let s = leererSpeicher("serie-test-zuwenig")
        let liste = [runde(6, stunde: 10), runde(7, stunde: 9)]
        #expect(!Erfolge.belohnungAbholbar(liste, tagesziel: 2, jetzt: heute, kalender: kal, speicher: s))
        #expect(Erfolge.belohnungHolen(liste, tagesziel: 2, jetzt: heute, kalender: kal, speicher: s) == 0)
    }

    @Test func inDerNaechstenWocheZaehltDasWochenzielNeu() {
        let s = leererSpeicher("serie-test-naechste")
        var liste: [RundenErgebnis] = []
        for _ in 0..<10 { liste.append(runde(6, stunde: 10)) }
        _ = Erfolge.belohnungHolen(liste, tagesziel: 2, jetzt: heute, kalender: kal, speicher: s)
        let naechsteWoche = kal.date(byAdding: .day, value: 7, to: heute) ?? heute
        #expect(!Erfolge.belohnungAbholbar(liste, tagesziel: 2, jetzt: naechsteWoche, kalender: kal, speicher: s))
        #expect(Erfolge.wochenKennung(heute, kalender: kal) != Erfolge.wochenKennung(naechsteWoche, kalender: kal))
    }
}
