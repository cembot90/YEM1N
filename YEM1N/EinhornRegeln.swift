import CoreGraphics

// ============================================================
// MARK: - Einhorn-Flug: Regeln und Zahlen
// Für Vorschulkinder: großzügig, langsam, nie gemein. Reine Rechenregeln
// ohne Grafik, damit sie sich testen lassen.
// ============================================================

enum EinhornRegeln {
    static let breite: CGFloat = 1024
    static let hoehe: CGFloat = 576

    static let schwerkraft: CGFloat = 820
    static let flugStoss: CGFloat = 360
    static let maxLeben = 3
    /// Ab so vielen Punkten steigt das Level.
    static let punkteProLevel = 15
    /// So nah muss das Einhorn an einem Ding sein, um es zu fangen. Bewusst großzügig.
    static let fangAbstand: CGFloat = 62

    enum Ding: Equatable {
        case stern, regenbogen, herz, gewitter

        var bild: String {
            switch self {
            case .stern: return "⭐"
            case .regenbogen: return "🌈"
            case .herz: return "💖"
            case .gewitter: return "⛈️"
            }
        }

        var punkte: Int {
            switch self {
            case .stern: return 1
            case .regenbogen: return 3
            case .herz, .gewitter: return 0
            }
        }
    }

    static func level(punkte: Int) -> Int {
        max(0, punkte) / punkteProLevel + 1
    }

    /// Wie schnell die Dinge von rechts kommen (Punkte pro Sekunde).
    static func tempo(level: Int) -> CGFloat {
        min(460, 210 + 25 * CGFloat(level - 1))
    }

    /// Abstand zwischen zwei neuen Dingen (Sekunden).
    static func abstand(level: Int) -> Double {
        max(0.7, 1.35 - 0.06 * Double(level - 1))
    }

    /// Anteil der Gewitterwolken. Am Anfang selten, später etwas öfter.
    static func gewitterAnteil(level: Int) -> Double {
        min(0.32, 0.12 + 0.03 * Double(level - 1))
    }

    /// Wählt das nächste Ding. `zufall` liegt zwischen 0 und 1.
    /// Herzen gibt es nur, wenn ein Leben fehlt.
    static func naechstes(zufall: Double, level: Int, leben: Int) -> Ding {
        let gewitter = gewitterAnteil(level: level)
        if zufall < gewitter { return .gewitter }
        if leben < maxLeben && zufall < gewitter + 0.08 { return .herz }
        if zufall > 0.8 { return .regenbogen }
        return .stern
    }

    /// Ein gefangenes Ding verändert Punkte und Leben.
    static func fange(_ ding: Ding, punkte: Int, leben: Int) -> (punkte: Int, leben: Int) {
        switch ding {
        case .herz: return (punkte, min(maxLeben, leben + 1))
        case .gewitter: return (punkte, max(0, leben - 1))
        default: return (punkte + ding.punkte, leben)
        }
    }
}
