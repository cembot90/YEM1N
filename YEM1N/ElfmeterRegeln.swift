import CoreGraphics

// ============================================================
// MARK: - Elfmeterschießen: Regeln und Zahlen
// Reine Rechenregeln ohne Grafik, damit sie sich testen lassen.
// Das Spielfeld ist 1024 · 576 Punkte groß, unten liegt der Ball.
// ============================================================

enum ElfmeterRegeln {
    static let breite: CGFloat = 1024
    static let hoehe: CGFloat = 576

    // Das Tor
    static let torLinks: CGFloat = 262
    static let torRechts: CGFloat = 762
    static let torUnten: CGFloat = 300
    static let torOben: CGFloat = 470
    static var torMitte: CGFloat { (torLinks + torRechts) / 2 }

    /// Hier liegt der Ball vor dem Schuss.
    static let ballStart = CGPoint(x: 512, y: 110)

    /// So weit kommt der Torwart seitlich mit den Händen.
    static let reichweite: CGFloat = 64

    /// Nach so vielen Fehlschüssen ist das Spiel vorbei.
    static let fehlschuesseErlaubt = 3

    /// Alle so viele Tore steigt das Level.
    static let toreProLevel = 5

    // MARK: Schuss

    /// Wohin der Ball fliegt, abhängig vom Wischen. Nach oben wischen zielt aufs Tor.
    static func ziel(wisch: CGVector) -> CGPoint {
        let x = torMitte + wisch.dx * 1.5
        let y = torUnten + max(0, wisch.dy - 120) * 0.75
        return CGPoint(x: x, y: y)
    }

    /// Flugzeit: schnelles Wischen gibt einen schnellen Schuss.
    static func flugzeit(wischTempo: CGFloat) -> Double {
        let t = 0.85 - Double(min(max(wischTempo, 0), 3000)) / 3000 * 0.4
        return max(0.42, min(0.85, t))
    }

    static func istImTor(_ p: CGPoint) -> Bool {
        p.x > torLinks + 14 && p.x < torRechts - 14 && p.y >= torUnten && p.y < torOben - 10
    }

    /// Schüsse nah an Pfosten oder Latte zählen als Winkel und bringen mehr Punkte.
    static func istWinkel(_ p: CGPoint) -> Bool {
        guard istImTor(p) else { return false }
        let seitlich = abs(p.x - torMitte) > (torRechts - torLinks) / 2 * 0.72
        let oben = p.y > torUnten + (torOben - torUnten) * 0.72
        return seitlich || oben
    }

    // MARK: Torwart

    /// Wie lange der Torwart braucht, bis er losspringt (Sekunden).
    static func reaktion(level: Int) -> Double {
        max(0.08, 0.32 - 0.03 * Double(level - 1))
    }

    /// Wie schnell der Torwart zur Seite kommt (Punkte pro Sekunde).
    static func tempo(level: Int) -> CGFloat {
        min(950, 380 + 70 * CGFloat(level - 1))
    }

    /// Wie oft der Torwart in die falsche Ecke springt.
    static func falscheEckeChance(level: Int) -> Double {
        max(0.06, 0.35 - 0.04 * Double(level - 1))
    }

    /// Bis zu dieser Höhe kommt der Torwart mit einem Sprung.
    static func sprungHoehe(level: Int) -> CGFloat {
        min(torOben - 6, torUnten + 128 + 6 * CGFloat(level - 1))
    }

    enum Ergebnis: Equatable {
        case tor(winkel: Bool)
        case gehalten
        case daneben
    }

    /// Entscheidet den Schuss. `zufall` liegt zwischen 0 und 1 und bestimmt, ob der
    /// Torwart sich verschätzt. Gibt auch zurück, wohin der Torwart springt.
    static func ergebnis(ziel: CGPoint, torwartX: CGFloat, flugzeit: Double, level: Int,
                         zufall: Double) -> (ergebnis: Ergebnis, torwartZiel: CGFloat) {
        let verschaetzt = zufall < falscheEckeChance(level: level)
        let gewollt = verschaetzt ? 2 * torMitte - ziel.x : ziel.x
        let weg = CGFloat(max(0, flugzeit - reaktion(level: level))) * tempo(level: level)
        let schritt = min(max(gewollt - torwartX, -weg), weg)
        let endX = min(max(torwartX + schritt, torLinks + 30), torRechts - 30)

        guard istImTor(ziel) else { return (.daneben, endX) }
        let erreicht = abs(ziel.x - endX) <= reichweite && ziel.y <= sprungHoehe(level: level)
        if erreicht { return (.gehalten, endX) }
        return (.tor(winkel: istWinkel(ziel)), endX)
    }

    // MARK: Punkte

    /// Ein Tor bringt 1 Punkt, in den Winkel 3. Ab dem dritten Treffer in Folge gibt es einen Extrapunkt.
    static func punkte(winkel: Bool, serie: Int) -> Int {
        (winkel ? 3 : 1) + (serie >= 3 ? 1 : 0)
    }

    static func level(tore: Int) -> Int {
        max(0, tore) / toreProLevel + 1
    }
}
