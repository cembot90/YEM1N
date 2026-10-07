import Foundation
import CoreGraphics

// ============================================================
// MARK: - Münzjagd: Werte und Bilder der Ebenen
// Eigene Datei, damit sich nachrechnen lässt, dass jede Münze
// erreichbar ist und die Gegner langsamer bleiben als der Hase.
// ============================================================

struct JagdPlattform: Equatable {
    /// Mitte der Plattform
    let x: CGFloat
    /// Oberkante, hier steht der Hase
    let y: CGFloat
    let breite: CGFloat

    var links: CGFloat { x - breite / 2 }
    var rechts: CGFloat { x + breite / 2 }
}

struct JagdEbene {
    let plattformen: [JagdPlattform]
    let muenzen: [CGPoint]
}

enum JagdBalance {
    static let breite: CGFloat = 1024
    static let hoehe: CGFloat = 576
    static let bodenOberkante: CGFloat = 70
    static let plattformDicke: CGFloat = 26

    // Spielgefühl
    static let schwerkraft: CGFloat = -1900
    static let sprungKraft: CGFloat = 780
    /// Beim Halten im Fallen wirkt nur ein Teil der Schwerkraft (Schweben).
    static let schwebFaktor: CGFloat = 0.22
    static let schwebFallMax: CGFloat = -170
    static let laufTempo: CGFloat = 330
    static let spielerHoehe: CGFloat = 64
    static let maxLeben = 3

    /// Wie hoch ein Sprung kommt.
    static var maxSprungHoehe: CGFloat {
        sprungKraft * sprungKraft / (2 * -schwerkraft)
    }

    /// Ein Stockwerk darf höchstens so hoch sein, dass der Sprung bequem reicht.
    static var bequemeHoehe: CGFloat { maxSprungHoehe * 0.85 }

    /// So weit darf es zur nächsten Plattform seitlich sein.
    static let bequemeWeite: CGFloat = 200

    // Gegner
    static func gegnerAnzahl(ebene: Int) -> Int {
        min(max(ebene, 1), 5)
    }

    static func gegnerTempo(ebene: Int) -> CGFloat {
        min(110 + CGFloat(max(ebene, 1) - 1) * 18, 230)
    }

    /// Ab dieser Ebene verfolgt ein Gegner den Hasen langsam.
    static let jaegerAbEbene = 3

    // Punkte
    static let punkteMuenze = 1
    static let punkteLeuchtend = 3
    static let punkteEbene = 10

    // MARK: Ebenen

    static let boden = JagdPlattform(x: breite / 2, y: bodenOberkante, breite: breite)

    private static let formen: [[JagdPlattform]] = [
        // Zwei Türme und eine Mitte
        [
            JagdPlattform(x: 190, y: 180, breite: 250),
            JagdPlattform(x: 834, y: 180, breite: 250),
            JagdPlattform(x: 512, y: 290, breite: 320),
            JagdPlattform(x: 170, y: 400, breite: 230),
            JagdPlattform(x: 854, y: 400, breite: 230),
            JagdPlattform(x: 512, y: 500, breite: 260)
        ],
        // Treppe
        [
            JagdPlattform(x: 130, y: 175, breite: 240),
            JagdPlattform(x: 400, y: 255, breite: 200),
            JagdPlattform(x: 670, y: 335, breite: 200),
            JagdPlattform(x: 900, y: 415, breite: 220),
            JagdPlattform(x: 620, y: 495, breite: 240),
            JagdPlattform(x: 300, y: 375, breite: 200)
        ],
        // Burg
        [
            JagdPlattform(x: 110, y: 170, breite: 180),
            JagdPlattform(x: 914, y: 170, breite: 180),
            JagdPlattform(x: 512, y: 190, breite: 200),
            JagdPlattform(x: 300, y: 300, breite: 180),
            JagdPlattform(x: 724, y: 300, breite: 180),
            JagdPlattform(x: 120, y: 420, breite: 200),
            JagdPlattform(x: 904, y: 420, breite: 200),
            JagdPlattform(x: 512, y: 430, breite: 220)
        ]
    ]

    static var anzahlFormen: Int { formen.count }

    /// Ebene 1, 2, 3 ... wechselt durch die Formen.
    static func ebene(_ nummer: Int) -> JagdEbene {
        let index = (max(nummer, 1) - 1) % formen.count
        let platten = formen[index]
        var muenzen: [CGPoint] = []
        for p in platten {
            let n = max(2, Int(p.breite / 80))
            let von = p.links + 30
            let bis = p.rechts - 30
            for i in 0..<n {
                let t = n == 1 ? 0.5 : CGFloat(i) / CGFloat(n - 1)
                muenzen.append(CGPoint(x: von + (bis - von) * t, y: p.y + 38))
            }
        }
        for x in [300, 420, 600, 720] as [CGFloat] {
            muenzen.append(CGPoint(x: x, y: bodenOberkante + 38))
        }
        return JagdEbene(plattformen: platten, muenzen: muenzen)
    }
}
