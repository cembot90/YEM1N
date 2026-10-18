import Foundation

// Ersatz für Teile der App, die die Prüfung unter Linux nicht braucht.
final class Sprecher {
    nonisolated(unsafe) static let shared = Sprecher()
    func sprich(_ text: String, code: String, tonhoehe: Float = 1.0, stimmung: SprechStimmung = .normal) {}
}
