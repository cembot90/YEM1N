import Foundation
import Testing
@testable import YEM1N

// Ein Tipp auf eine Mitteilung soll direkt im passenden Bereich landen.

struct MitteilungsZielTests {
    @Test func wochenberichtFuehrtZumBericht() {
        #expect(MitteilungsZiel.bereich(ziel: "bericht", kennung: "") == "bericht")
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "wochenbericht") == "bericht")
    }

    @Test func jokerMitteilungenFuehrenZumJoker() {
        for typ in ["frage", "antwort", "daumen", "nachschub", "freigabe"] {
            #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", typ: typ) == "joker")
        }
    }

    @Test func haustierPaketDuellUndGeraete() {
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", typ: "pflege") == "haustier")
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", typ: "paket") == "schule")
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", typ: "duell") == "duell")
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", typ: "duellantwort") == "duell")
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", typ: "geraet") == "familie")
    }

    @Test func unbekanntBleibtWoEsIst() {
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "lernzeit") == nil)
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", typ: "ergebnis") == nil)
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", typ: "unsinn") == nil)
    }
}

@MainActor
struct MitteilungsZielMerkerTests {
    @Test func gemerkterBereichWirdNurEinmalAbgeholt() {
        UserDefaults.standard.set("joker", forKey: MitteilungsZiel.merkSchluessel)
        #expect(MitteilungsZiel.abholen() == "joker")
        #expect(MitteilungsZiel.abholen() == nil)
    }
}
