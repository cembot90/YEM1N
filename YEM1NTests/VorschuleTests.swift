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
            #expect((1...4).contains(n), "\(wort)")
        }
    }

    @Test func keineGedankenstricheInDenTexten() {
        for art in Self.neue {
            for _ in 0..<15 {
                let f = VorschulGenerator.eine(art, stufe: 2)
                for t in [f.text.de, f.text.tr ?? "", f.text.en ?? ""] + f.optionen {
                    #expect(!t.contains("\u{2013}") && !t.contains("\u{2014}"), "\(t)")
                }
            }
        }
    }

    // MARK: Sprachen: Deutsch fest, Englisch und Türkisch nur als Zusatz

    /// Diese Spiele drehen sich um deutsche Wörter und bleiben auf Deutsch
    static let nurDeutsch: Set<VorschulArt> = [.anlaut, .reime, .silben]

    @Test func ohneZusatzBleibtEsBeiDeutsch() {
        #expect(VorschulSprache.angebot(englisch: false, tuerkisch: false) == ["de"])
        #expect(VorschulSprache.angebot(englisch: true, tuerkisch: true) == ["de", "en", "tr"])
        // Wer früher Türkisch gewählt hatte, bekommt Deutsch, solange Türkisch nicht eingeschaltet ist
        #expect(VorschulSprache.aktiv(gewaehlt: "tr", englisch: false, tuerkisch: false) == "de")
        #expect(VorschulSprache.aktiv(gewaehlt: "tr", englisch: true, tuerkisch: false) == "de")
        #expect(VorschulSprache.aktiv(gewaehlt: "tr", englisch: false, tuerkisch: true) == "tr")
        #expect(VorschulSprache.aktiv(gewaehlt: "en", englisch: true, tuerkisch: false) == "en")
        #expect(VorschulSprache.aktiv(gewaehlt: "xx", englisch: true, tuerkisch: true) == "de")
        #expect(VorschulSprache.code("en") == "en-GB")
        #expect(VorschulSprache.code("tr") == "tr-TR")
        #expect(VorschulSprache.code("de") == "de-DE")
    }

    @Test func jedesSpielGibtEsAuchAufEnglisch() {
        let arten = VorschulArt.allCases.filter { $0 != .mix && $0 != .memory }
        for art in arten {
            for stufe in 1...3 {
                for _ in 0..<20 {
                    let f = VorschulGenerator.eine(art, stufe: stufe)
                    if Self.nurDeutsch.contains(art) {
                        #expect(f.text.en == nil, "\(art)")
                        #expect(f.text.sprache("en") == "de" && f.text.text("en") == f.text.de, "\(art)")
                    } else {
                        let en = f.text.en ?? ""
                        #expect(!en.isEmpty, "\(art) hat keinen englischen Text")
                        #expect(f.text.sprache("en") == "en" && f.text.text("en") == en, "\(art)")
                        #expect(en != f.text.de, "\(art): \(en)")
                    }
                }
            }
        }
    }

    @Test func zahlenStimmenInJederSprache() {
        for _ in 0..<60 {
            let f = VorschulGenerator.eine(.zahlen, stufe: 3)
            let n = f.optionen[f.richtig]
            #expect(f.text.de.contains(n) && (f.text.en ?? "").contains(n) && (f.text.tr ?? "").contains(n))
            let g = VorschulMehr.minus(2)
            let da = g.zeige.filter { $0 != "💨" }.count
            let weg = g.zeige.count - da
            #expect((g.text.en ?? "").contains("There were \(g.zeige.count).") && (g.text.en ?? "").contains(weg == 1 ? "One flew" : "\(weg) flew"))
        }
    }

    @Test func fehltDieSpracheKommtDeutsch() {
        let t = VorschulText(de: "Hallo", tr: nil)
        #expect(t.text("tr") == "Hallo" && t.text("en") == "Hallo")
        #expect(t.sprache("tr") == "de" && t.sprache("en") == "de")
        let u = VorschulText(de: "Hallo", tr: "Merhaba", en: "Hello")
        #expect(u.text("tr") == "Merhaba" && u.text("en") == "Hello" && u.text("de") == "Hallo")
    }
}

// MARK: - Englisch für Kleine

@MainActor
struct VorschulEnglischTests {

    @Test func jedesThemaHatGenugEindeutigeWoerter() {
        for t in EnglischThema.mitWoertern {
            let w = t.woerter
            #expect(w.count >= 8, "\(t) hat zu wenige Wörter")
            #expect(Set(w.map(\.en)).count == w.count, "\(t): doppeltes Wort")
            #expect(Set(w.map(\.bild)).count == w.count, "\(t): doppeltes Bild")
            #expect(w.allSatisfy { !$0.de.isEmpty && !$0.en.isEmpty && !$0.bild.isEmpty })
        }
        let alle = EnglischThema.gemischt.woerter.map(\.en)
        #expect(Set(alle).count == alle.count, "Ein Wort steht in zwei Themen")
        #expect(Set(EnglischThema.allCases.map(\.emoji)).count == EnglischThema.allCases.count)
    }

    @Test func jedeRundeFragtVerschiedeneWoerterMitDemRichtigenBild() {
        for t in EnglischThema.allCases {
            for _ in 0..<30 {
                let runde = VorschulEnglisch.fragen(t)
                #expect(runde.count == 8, "\(t)")
                #expect(Set(runde.map { $0.text.en ?? "" }).count == runde.count, "\(t): Wort doppelt in einer Runde")
                for f in runde {
                    #expect(f.optionen.count == 3 && Set(f.optionen).count == 3, "\(t): \(f.optionen)")
                    #expect(f.optionen.indices.contains(f.richtig))
                    // Das gesuchte Wort steht in der Aufforderung, das richtige Bild gehört dazu
                    let gesucht = EnglischThema.gemischt.woerter.first { $0.bild == f.optionen[f.richtig] }
                    #expect(gesucht != nil && (f.text.en ?? "").contains(gesucht?.en ?? "?"), "\(f.text.en ?? "")")
                    #expect(f.text.sprache("en") == "en")
                }
            }
        }
    }

    @Test func dieSaetzeSindRichtigesEnglisch() {
        let hund = EnglischWort(bild: "🐶", de: "der Hund", en: "dog")
        let hose = EnglischWort(bild: "👖", de: "die Hose", en: "trousers", mehrzahl: true)
        let rot = VorschulEnglisch.f("🔴", "rot", "red")
        #expect(VorschulEnglisch.aufforderung(hund, art: 0) == "Tap the dog!")
        #expect(VorschulEnglisch.aufforderung(hund, art: 1) == "Where is the dog?")
        #expect(VorschulEnglisch.aufforderung(hund, art: 2) == "Find the dog!")
        #expect(VorschulEnglisch.aufforderung(hose, art: 1) == "Where are the trousers?")
        #expect(VorschulEnglisch.aufforderung(rot, art: 0) == "Tap red!")
        #expect(VorschulEnglisch.aufforderung(rot, art: 1) == "Where is red?")
        #expect(VorschulEnglisch.bedeutung(hund) == "dog: der Hund")
    }

    @Test func keineGedankenstriche() {
        for w in EnglischThema.gemischt.woerter {
            for t in [w.de, w.en, VorschulEnglisch.aufforderung(w, art: 1)] {
                #expect(!t.contains("\u{2013}") && !t.contains("\u{2014}"), "\(t)")
            }
        }
    }
}
