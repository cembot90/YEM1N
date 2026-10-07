import Foundation
import Testing
@testable import YEM1N

// Die Probearbeit soll jedes Mal anders aussehen, aber immer fair bleiben.

/// Ein Zufallsgenerator mit festem Start, damit die Tests gleich ablaufen.
struct FesterZufall: RandomNumberGenerator {
    var zustand: UInt64
    init(_ start: UInt64) { zustand = start }
    mutating func next() -> UInt64 {
        zustand &+= 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@MainActor
struct ProbearbeitTests {

    @Test func immerZwanzigAufgabenUndJederBereich() {
        for start in 0..<200 {
            var zufall = FesterZufall(UInt64(start))
            let plan = Spezial.probePlan(zufall: &zufall)
            #expect(plan.reduce(0) { $0 + $1.1 } == Spezial.probeAufgaben)
            #expect(plan.map { $0.0 } == Spezial.probeBereiche, "Die Reihenfolge der Bereiche bleibt")
            for (id, n) in plan { #expect(n >= 1, "\(id) fehlt") }
        }
    }

    @Test func hoechstensZweiZahlenmauern() {
        for start in 0..<300 {
            var zufall = FesterZufall(UInt64(start))
            let mauern = Spezial.probePlan(zufall: &zufall).first { $0.0 == "mauer" }?.1 ?? 0
            #expect(mauern >= 1 && mauern <= Spezial.probeMaxMauern)
        }
    }

    @Test func derAufbauIstNichtJedesMalGleich() {
        var verschiedene = Set<String>()
        for start in 0..<50 {
            var zufall = FesterZufall(UInt64(start))
            let plan = Spezial.probePlan(zufall: &zufall)
            verschiedene.insert(plan.map { "\($0.0)\($0.1)" }.joined(separator: ","))
        }
        #expect(verschiedene.count >= 25, "Nur \(verschiedene.count) verschiedene Aufbauten in 50 Versuchen")
    }

    @Test func alleBereicheGibtEsAlsVorlage() {
        for id in Spezial.probeBereiche {
            #expect(MatheGenerator.vorlagen.contains { $0.id == id }, "Vorlage \(id) fehlt")
        }
    }

    @Test func eineAngefangeneProbeWirdNurHeuteWeitergemacht() {
        let kalender = Calendar(identifier: .gregorian)
        let jetzt = DateComponents(calendar: kalender, year: 2026, month: 10, day: 7, hour: 15).date ?? Date.now
        let gestern = kalender.date(byAdding: .day, value: -1, to: jetzt) ?? jetzt
        let frueh = DateComponents(calendar: kalender, year: 2026, month: 10, day: 7, hour: 7).date ?? jetzt

        #expect(Spezial.probeWeiterfuehren(erstellt: frueh, beantwortet: 4, jetzt: jetzt, kalender: kalender))
        #expect(!Spezial.probeWeiterfuehren(erstellt: frueh, beantwortet: 0, jetzt: jetzt, kalender: kalender),
                "Ohne Antworten gibt es neue Aufgaben")
        #expect(!Spezial.probeWeiterfuehren(erstellt: gestern, beantwortet: 9, jetzt: jetzt, kalender: kalender),
                "Von gestern gibt es neue Aufgaben")
    }
}
