import Foundation
import CoreGraphics

// ============================================================
// MARK: - Münz-Hockey: Werte
// Der Computer muss schlagbar bleiben. Seine Geschwindigkeit liegt
// deshalb immer deutlich unter der des schnellsten Pucks.
// ============================================================

enum HockeyBalance {
    static let breite: CGFloat = 1024
    static let hoehe: CGFloat = 576
    /// Rand um das Spielfeld
    static let rand: CGFloat = 36
    /// Höhe der Toröffnung
    static let torHoehe: CGFloat = 190

    static let puckRadius: CGFloat = 24
    static let schlaegerRadius: CGFloat = 42
    static let puckMaxTempo: CGFloat = 1100
    static let puckMinStoss: CGFloat = 260

    /// Wer zuerst so viele Tore hat, gewinnt das Spiel.
    static let toreZumSieg = 5
    static let hoechstesLevel = 8

    static func level(_ nummer: Int) -> Int {
        min(max(nummer, 1), hoechstesLevel)
    }

    /// Wie schnell der Computer-Schläger höchstens ist, in Punkten je Sekunde.
    static func kiTempo(level l: Int) -> CGFloat {
        380 + CGFloat(level(l) - 1) * 55
    }

    /// Wie ungenau der Computer zielt. Wird mit dem Level besser, bleibt aber über null.
    static func kiFehler(level l: Int) -> CGFloat {
        max(70 - CGFloat(level(l) - 1) * 9, 10)
    }

    /// Wie oft der Computer neu überlegt, in Sekunden.
    static func kiReaktion(level l: Int) -> CGFloat {
        max(0.28 - CGFloat(level(l) - 1) * 0.03, 0.07)
    }

    /// Sieg im Level bringt Punkte, ein Torvorsprung bringt extra.
    static func punkteFuerSieg(level l: Int, vorsprung: Int) -> Int {
        10 * level(l) + max(vorsprung, 0)
    }
}
