import Foundation
import CoreGraphics

// ============================================================
// MARK: - Schwierigkeit im Zahlenlauf
// Eigene Datei, damit sich die Kurve nachrechnen und testen lässt.
// ============================================================

enum LaufBalance {
    /// Ab so vielen Punkten beginnt die nächste Stufe.
    static let punkteProStufe = 120
    static let hoechsteStufe = 8
    /// Ab dieser Stufe kommen fliegende Gegner dazu.
    static let fliegerAbStufe = 2
    /// Ab dieser Stufe gibt es Trampoline.
    static let federAbStufe = 3

    static func stufe(punkte: Int) -> Int {
        let roh = punkte / punkteProStufe + 1
        return min(max(roh, 1), hoechsteStufe)
    }

    /// Wie schnell die Welt vorbeizieht, in Punkten je Sekunde.
    static func tempo(stufe: Int) -> CGFloat {
        let s = CGFloat(min(max(stufe, 1), hoechsteStufe) - 1)
        return 320 + s * 52
    }

    /// Abstand zwischen zwei Hindernissen. Wird enger, aber nie unfair.
    static func abstand(stufe: Int) -> ClosedRange<CGFloat> {
        let s = CGFloat(min(max(stufe, 1), hoechsteStufe) - 1)
        let klein = max(360 - s * 16, 280)
        let gross = max(620 - s * 30, 420)
        return klein...gross
    }

    /// Wie wahrscheinlich ein Hindernis ein Flieger ist.
    static func fliegerAnteil(stufe: Int) -> Double {
        guard stufe >= fliegerAbStufe else { return 0 }
        return min(0.18 + Double(stufe - fliegerAbStufe) * 0.05, 0.42)
    }

    /// Wie viel Zeit im ungünstigsten Fall zwischen zwei Hindernissen bleibt.
    /// Darunter wird es für ein Kind unfair, deshalb wird das getestet.
    static func zeitZwischenHindernissen(stufe: Int) -> CGFloat {
        abstand(stufe: stufe).lowerBound / tempo(stufe: stufe)
    }

    /// Weniger Zeit als das soll nie herauskommen.
    static let kuerzesteReaktion: CGFloat = 0.38
}
