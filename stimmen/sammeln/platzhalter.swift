import Foundation

// Ersatz für Teile der App, die der Sammler nicht braucht.
// Der Sammler spricht nichts, er schreibt nur auf, was gesprochen würde.
final class Sprecher {
    nonisolated(unsafe) static let shared = Sprecher()
    func sprich(_ text: String, code: String, tonhoehe: Float = 1.0, stimmung: SprechStimmung = .normal) {}
}
