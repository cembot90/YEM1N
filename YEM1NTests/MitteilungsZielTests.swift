import Foundation
import Testing
@testable import YEM1N

// Ein Tipp auf eine Mitteilung soll direkt im passenden Bereich landen.

struct MitteilungsZielTests {
    @Test func wochenberichtFuehrtZumBericht() {
        #expect(MitteilungsZiel.bereich(ziel: "bericht", kennung: "", abo: "") == "bericht")
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "wochenbericht", abo: "") == "bericht")
    }

    @Test func jokerMitteilungenFuehrenZumJoker() {
        for abo in ["JokerAnfrage-ABCDE-12345", "JokerNachschub-ABCDE-12345",
                    "JokerAntwort-ABCDE-12345", "JokerFreigabe-ABCDE-12345",
                    "JokerDaumen-ABCDE-12345-Papa"] {
            #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", abo: abo) == "joker")
        }
    }

    @Test func haustierUndLernpaket() {
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", abo: "HaustierPflege-ABCDE-12345") == "haustier")
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", abo: "Lernpaket-ABCDE-12345") == "schule")
    }

    @Test func unbekanntBleibtWoEsIst() {
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "lernzeit", abo: "") == nil)
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", abo: "RundenErgebnis-ABCDE-12345") == nil)
    }
}
