import Foundation
import CoreGraphics
import Testing
@testable import YEM1N

// Die beiden Spiele Münzjagd und Münz-Hockey. Geprüft wird, was ein Spiel
// unspielbar machen würde: unerreichbare Münzen, zu schnelle Gegner.

@MainActor
struct JagdBalanceTests {

    private var alleEbenen: [JagdEbene] {
        (1...JagdBalance.anzahlFormen).map { JagdBalance.ebene($0) }
    }

    @Test func derSprungHatEineSinnvolleHoehe() {
        let h = JagdBalance.maxSprungHoehe
        #expect(h > 120 && h < 220, "Sprunghöhe \(h) passt nicht zu den Stockwerken")
    }

    @Test func dieEbenenWiederholenSich() {
        let n = JagdBalance.anzahlFormen
        #expect(n >= 3)
        #expect(JagdBalance.ebene(1).plattformen == JagdBalance.ebene(1 + n).plattformen)
        #expect(JagdBalance.ebene(0).plattformen == JagdBalance.ebene(1).plattformen,
                "Unsinn wird zu Ebene 1")
    }

    @Test func allePlattformenLiegenImBild() {
        for (i, e) in alleEbenen.enumerated() {
            for p in e.plattformen {
                #expect(p.links >= 0 && p.rechts <= JagdBalance.breite,
                        "Form \(i + 1): Plattform bei \(p.x) ragt aus dem Bild")
                #expect(p.y > JagdBalance.bodenOberkante + 40 && p.y <= 520,
                        "Form \(i + 1): Plattform in Höhe \(p.y) ist zu tief oder zu hoch")
            }
        }
    }

    @Test func jedePlattformIstZuFussErreichbar() {
        for (i, e) in alleEbenen.enumerated() {
            for p in e.plattformen {
                let darunter = ([JagdBalance.boden] + e.plattformen).filter { q in
                    let hoehe = p.y - q.y
                    let luecke = max(q.links - p.rechts, p.links - q.rechts, 0)
                    return hoehe > 0
                        && hoehe <= JagdBalance.bequemeHoehe
                        && luecke <= JagdBalance.bequemeWeite
                }
                #expect(!darunter.isEmpty,
                        "Form \(i + 1): Zur Plattform bei x \(p.x), y \(p.y) kommt man nicht hinauf")
            }
        }
    }

    @Test func jedeMuenzeIstErreichbar() {
        let reichweite = JagdBalance.maxSprungHoehe + JagdBalance.spielerHoehe / 2
        for (i, e) in alleEbenen.enumerated() {
            #expect(e.muenzen.count >= 12 && e.muenzen.count <= 40,
                    "Form \(i + 1) hat \(e.muenzen.count) Münzen")
            for m in e.muenzen {
                let stuetze = ([JagdBalance.boden] + e.plattformen).contains { q in
                    m.x >= q.links - 60 && m.x <= q.rechts + 60
                        && m.y > q.y && m.y - q.y <= reichweite
                }
                #expect(stuetze, "Form \(i + 1): Münze bei \(m.x), \(m.y) ist unerreichbar")
                #expect(m.x > 0 && m.x < JagdBalance.breite)
                #expect(m.y < JagdBalance.hoehe - 30, "Münze liegt unter den Anzeigen")
            }
        }
    }

    @Test func keineMuenzeLiegtDoppelt() {
        for (i, e) in alleEbenen.enumerated() {
            for a in 0..<e.muenzen.count {
                for b in (a + 1)..<max(e.muenzen.count, a + 1) {
                    let d = hypot(e.muenzen[a].x - e.muenzen[b].x, e.muenzen[a].y - e.muenzen[b].y)
                    #expect(d > 20, "Form \(i + 1): Zwei Münzen liegen übereinander")
                }
            }
        }
    }

    @Test func gegnerBleibenSchlagbar() {
        var vorher: CGFloat = 0
        for ebene in 1...30 {
            let t = JagdBalance.gegnerTempo(ebene: ebene)
            #expect(t >= vorher)
            #expect(t < JagdBalance.laufTempo * 0.75,
                    "Ab Ebene \(ebene) wären die Gegner fast so schnell wie der Hase")
            vorher = t
            let n = JagdBalance.gegnerAnzahl(ebene: ebene)
            #expect(n >= 1 && n <= 5)
        }
        #expect(JagdBalance.gegnerAnzahl(ebene: 1) == 1, "Am Anfang nur ein Gegner")
    }

    @Test func schwebenHilftAberNurEinBisschen() {
        #expect(JagdBalance.schwebFaktor > 0.1 && JagdBalance.schwebFaktor < 0.5)
        #expect(JagdBalance.schwebFallMax < 0)
        #expect(JagdBalance.punkteLeuchtend > JagdBalance.punkteMuenze)
    }
}

@MainActor
struct HockeyBalanceTests {

    private let levels = Array(1...HockeyBalance.hoechstesLevel)

    @Test func derComputerWirdSchneller() {
        var vorher: CGFloat = 0
        for l in levels {
            let t = HockeyBalance.kiTempo(level: l)
            #expect(t > vorher, "Level \(l) ist nicht schneller als das davor")
            vorher = t
        }
        #expect(HockeyBalance.kiTempo(level: 99) == HockeyBalance.kiTempo(level: HockeyBalance.hoechstesLevel))
        #expect(HockeyBalance.kiTempo(level: 0) == HockeyBalance.kiTempo(level: 1))
    }

    @Test func derComputerBleibtSchlagbar() {
        for l in levels {
            #expect(HockeyBalance.kiTempo(level: l) < HockeyBalance.puckMaxTempo * 0.75,
                    "Der Computer wäre in Level \(l) schneller als der Puck erlaubt")
            #expect(HockeyBalance.kiFehler(level: l) > 0, "Ein Computer ohne Fehler ist unschlagbar")
            #expect(HockeyBalance.kiReaktion(level: l) > 0)
        }
    }

    @Test func derComputerZieltGenauer() {
        var fehler: CGFloat = .greatestFiniteMagnitude
        var reaktion: CGFloat = .greatestFiniteMagnitude
        for l in levels {
            #expect(HockeyBalance.kiFehler(level: l) <= fehler)
            #expect(HockeyBalance.kiReaktion(level: l) <= reaktion)
            fehler = HockeyBalance.kiFehler(level: l)
            reaktion = HockeyBalance.kiReaktion(level: l)
        }
    }

    @Test func dasSpielfeldPasst() {
        let H = HockeyBalance.self
        #expect(H.torHoehe < H.hoehe - 2 * H.rand)
        #expect(H.torHoehe > H.puckRadius * 4, "Der Puck muss bequem ins Tor passen")
        #expect(H.torHoehe > H.schlaegerRadius * 2, "Der Schläger muss das Tor verdecken können")
        #expect(H.schlaegerRadius > H.puckRadius)
        #expect(H.breite / 2 - H.schlaegerRadius > H.rand + H.schlaegerRadius * 2,
                "Jeder Schläger braucht Platz in seiner Hälfte")
        #expect(H.puckMinStoss < H.puckMaxTempo)
        #expect(H.toreZumSieg >= 3 && H.toreZumSieg <= 10)
    }

    @Test func punkteFuerSiege() {
        #expect(HockeyBalance.punkteFuerSieg(level: 1, vorsprung: 5) == 15)
        #expect(HockeyBalance.punkteFuerSieg(level: 3, vorsprung: 2) > HockeyBalance.punkteFuerSieg(level: 2, vorsprung: 2))
        #expect(HockeyBalance.punkteFuerSieg(level: 2, vorsprung: -3) == 20, "Ein Rückstand zieht nichts ab")
    }
}

@MainActor
struct SpielArtTests {

    @Test func jedesSpielHatEinenEigenenBestwert() {
        let schluessel = SpielArt.allCases.map { $0.schluessel }
        #expect(Set(schluessel).count == schluessel.count)
        #expect(SpielArt.allCases.count == 3)
    }

    @Test func derAlteBestwertBleibtErhalten() {
        // Der Zahlenlauf speichert seinen Bestwert schon immer unter "lauf"
        #expect(SpielArt.lauf.schluessel == "lauf")
    }

    @Test func jedesSpielHatTexteUndBild() {
        for art in SpielArt.allCases {
            #expect(!art.titel.isEmpty)
            #expect(!art.beschreibung.isEmpty)
            #expect(!art.bild.isEmpty)
            #expect(!art.titel.contains("\u{2014}") && !art.titel.contains("\u{2013}"))
            #expect(!art.beschreibung.contains("\u{2014}") && !art.beschreibung.contains("\u{2013}"))
        }
    }
}
