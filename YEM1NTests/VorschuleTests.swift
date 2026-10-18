import Foundation
import Testing
@testable import YEM1N

// Die neuen Vorschulspiele bereiten auf die Schule vor. Jede Frage muss genau eine
// richtige Antwort haben, und die richtige muss unter den Bildern zum Antippen sein.

@MainActor
struct VorschuleTests {

    static let neue: [VorschulArt] = [.wuerfel, .minus, .zahlbild, .teilen, .buchstabe, .reime, .silben,
                                      .lage, .gefuehle, .reihenfolge, .tierwelt, .verkehr, .unterschied]

    @Test func jedeFrageHatDieRichtigeAntwortUnterDenKnoepfen() {
        for art in Self.neue {
            for stufe in 1...3 {
                for _ in 0..<40 {
                    let f = VorschulGenerator.eine(art, stufe: stufe)
                    #expect(f.optionen.count >= 2, "\(art)")
                    #expect(f.optionen.indices.contains(f.richtig), "\(art)")
                    if art != .unterschied {
                        #expect(Set(f.optionen).count == f.optionen.count, "\(art): doppelte Knöpfe \(f.optionen)")
                    }
                }
            }
        }
    }

    @Test func jedeNeueArtStehtInEinemBereich() {
        let alle = VorschulArt.rechnen + VorschulArt.sprache + VorschulArt.spielen
        for art in VorschulArt.allCases {
            #expect(alle.contains(art), "\(art) fehlt auf der Startseite")
        }
        #expect(Set(VorschulArt.allCases.map { $0.emoji }).count == VorschulArt.allCases.count,
                "Jedes Spiel braucht ein eigenes Bild, sonst stimmen die Stempel nicht")
    }

    @Test func wegnehmenStimmt() {
        for _ in 0..<60 {
            let f = VorschulMehr.minus(2)
            let da = f.zeige.filter { $0 != "💨" }.count
            #expect(f.optionen[f.richtig] == String(da))
        }
    }

    @Test func teilenGehtImmerAuf() {
        for stufe in 1...3 {
            for _ in 0..<60 {
                let f = VorschulMehr.teilen(stufe)
                let je = Int(f.optionen[f.richtig]) ?? 0
                #expect(je > 0 && f.zeige.count % je == 0)
                #expect(f.zeige.count / je == 2 || f.zeige.count / je == 3)
            }
        }
    }

    @Test func linksMitteRechtsStimmt() {
        for _ in 0..<60 {
            let f = VorschulMehr.lage()
            let gewaehlt = f.optionen[f.richtig]
            if f.text.de.contains("links") { #expect(gewaehlt == f.zeige.first) }
            if f.text.de.contains("rechts") { #expect(gewaehlt == f.zeige.last) }
            if f.text.de.contains("Mitte") { #expect(gewaehlt == f.zeige[1]) }
        }
    }

    @Test func dasAndereBildIstWirklichAnders() {
        for _ in 0..<60 {
            let f = VorschulMehr.unterschied()
            let richtig = f.optionen[f.richtig]
            #expect(f.optionen.filter { $0 == richtig }.count == 1)
            #expect(f.optionen.count == 4)
        }
    }

    @Test func reimeReimenSich() {
        for (a, b) in VorschulMehr.reimPaare {
            #expect(a.1.suffix(2).lowercased() == b.1.suffix(2).lowercased(), "\(a.1) und \(b.1)")
        }
        for (_, wort, n) in VorschulMehr.silbenBilder {
            #expect((1...4).contains(n), wort)
        }
    }

    @Test func keineGedankenstricheInDenTexten() {
        for art in Self.neue {
            for _ in 0..<15 {
                let f = VorschulGenerator.eine(art, stufe: 2)
                for t in [f.text.de, f.text.tr ?? ""] + f.optionen {
                    #expect(!t.contains("\u{2013}") && !t.contains("\u{2014}"), t)
                }
            }
        }
    }
}
