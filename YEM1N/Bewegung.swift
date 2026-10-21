import SwiftUI
import UIKit
import CoreMotion

// ============================================================
// MARK: - Bewegung
// Bausteine für lebendige Animationen: Konfetti, Lichtring, Einblenden,
// Zoom-Übergang und Neigen. Wer in iOS "Bewegung reduzieren" eingeschaltet
// hat, bekommt ruhige Varianten ohne Wackeln und Fliegen.
// ============================================================

// MARK: Regeln für Belohnungen

enum Belohnung {
    /// Ein Rekord zählt nur, wenn es schon einmal einen Bestwert gab und er übertroffen wird.
    static func istNeuerRekord(gut: Int, beste: Int) -> Bool {
        beste > 0 && gut > beste
    }

    /// Wie viel Konfetti am Ende einer Runde fällt. Unter zwei Sternen keins.
    static func konfetti(sterne: Int) -> Int {
        switch sterne {
        case 3...: return 110
        case 2: return 60
        default: return 0
        }
    }
}

// MARK: Konfetti

/// Bunter Regen aus kleinen Streifen. Läuft einmal ab und hält dann an.
/// Mit `.id(...)` lässt er sich neu starten.
struct KonfettiRegen: View {
    var anzahl = 70
    var dauer: Double = 2.6
    /// true: explodiert aus der Mitte, false: fällt von oben herein.
    var ausDerMitte = false

    @Environment(\.accessibilityReduceMotion) private var systemRuhig
    @AppStorage(Sparmodus.key) private var spar = false
    /// Ruhig bei "Bewegung reduzieren", im Sparmodus und im Stromsparmodus
    private var ruhig: Bool { systemRuhig || spar || Sparmodus.stromsparen }
    @State private var start = Date.now
    @State private var fertig = false
    @State private var teile: [Teil] = []

    private struct Teil {
        let x: Double
        let vx: Double
        let vy: Double
        let dreh: Double
        let breite: Double
        let farbe: Int
    }

    private var farben: [Color] {
        [Theme.gelb, Theme.koralle, Theme.mint, Theme.himmel, Color(red: 1.0, green: 0.55, blue: 0.85), .white]
    }

    var body: some View {
        if ruhig {
            EmptyView()
        } else {
            TimelineView(.animation(minimumInterval: nil, paused: fertig)) { zeit in
                Canvas { ctx, groesse in
                    let t = zeit.date.timeIntervalSince(start)
                    guard t >= 0, t < dauer else { return }
                    let schwere = 900.0
                    let palette = farben
                    for p in teile {
                        let x0 = ausDerMitte ? groesse.width / 2 : p.x * groesse.width
                        let y0 = ausDerMitte ? groesse.height * 0.4 : -20
                        let x = x0 + p.vx * t
                        let y = y0 + p.vy * t + 0.5 * schwere * t * t
                        var c = ctx
                        c.opacity = max(0, 1 - t / dauer)
                        c.translateBy(x: x, y: y)
                        c.rotate(by: .radians(p.dreh * t))
                        let r = CGRect(x: -p.breite / 2, y: -p.breite, width: p.breite, height: p.breite * 2)
                        c.fill(Path(roundedRect: r, cornerRadius: 2), with: .color(palette[p.farbe % palette.count]))
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                start = Date.now
                fertig = false
                teile = (0..<anzahl).map { _ in
                    Teil(x: Double.random(in: 0...1),
                         vx: ausDerMitte ? Double.random(in: -380...380) : Double.random(in: -60...60),
                         vy: ausDerMitte ? Double.random(in: -900 ... -300) : Double.random(in: 40...220),
                         dreh: Double.random(in: -9...9),
                         breite: Double.random(in: 5...9),
                         farbe: Int.random(in: 0..<6))
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(dauer))
                fertig = true
            }
        }
    }
}

// MARK: Lichtring und Federn

private struct RingWerte {
    var skala: Double = 0.6
    var deckkraft: Double = 0
}

/// Ein Lichtring breitet sich aus, wenn `trigger` sich ändert. Für richtige Antworten.
struct LichtRing: View {
    let trigger: Int
    var farbe: Color = Theme.gelb
    var radius: CGFloat = 34

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .stroke(farbe, lineWidth: 5)
            .keyframeAnimator(initialValue: RingWerte(), trigger: trigger) { inhalt, w in
                inhalt
                    .scaleEffect(w.skala)
                    .opacity(w.deckkraft)
            } keyframes: { _ in
                KeyframeTrack(\.skala) {
                    LinearKeyframe(0.92, duration: 0.01)
                    SpringKeyframe(1.12, duration: 0.55, spring: .smooth)
                }
                KeyframeTrack(\.deckkraft) {
                    LinearKeyframe(0.95, duration: 0.01)
                    LinearKeyframe(0.0, duration: 0.55)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

extension View {
    /// Federt kurz auf, wenn sich `trigger` ändert.
    func federn(_ trigger: Int, staerke: Double = 1.06) -> some View {
        keyframeAnimator(initialValue: 1.0, trigger: trigger) { inhalt, s in
            inhalt.scaleEffect(s)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(staerke, duration: 0.14, spring: .snappy)
                SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
            }
        }
    }

    /// Kippt kurz hin und her wie ein Kopfschütteln, wenn sich `trigger` ändert.
    func kopfschuetteln(_ trigger: Int) -> some View {
        keyframeAnimator(initialValue: 0.0, trigger: trigger) { inhalt, grad in
            inhalt.rotationEffect(.degrees(grad))
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-4.5, duration: 0.08)
                CubicKeyframe(3.5, duration: 0.1)
                CubicKeyframe(-2.0, duration: 0.1)
                CubicKeyframe(0.0, duration: 0.14)
            }
        }
    }

    /// Wiegt sich fröhlich hin und her, zum Beispiel das 🎉 am Ende einer Runde.
    func jubeln() -> some View {
        modifier(Jubeln())
    }

    /// Lässt eine Karte beim ersten Erscheinen von unten hereinschweben, nacheinander nach `index`.
    func einblenden(_ index: Int) -> some View {
        modifier(Einblenden(index: index))
    }

    /// Ab iOS 18: Diese Karte ist der Start für den Zoom-Übergang.
    @ViewBuilder
    func zoomQuelle<ID: Hashable>(_ id: ID, in raum: Namespace.ID) -> some View {
        if #available(iOS 18.0, *), !Sparmodus.an {
            self.matchedTransitionSource(id: id, in: raum)
        } else {
            self
        }
    }

    /// Ab iOS 18: Die neue Seite wächst aus der angetippten Karte heraus.
    @ViewBuilder
    func zoomZiel<ID: Hashable>(_ id: ID, in raum: Namespace.ID) -> some View {
        if #available(iOS 18.0, *), !Sparmodus.an {
            self.navigationTransition(.zoom(sourceID: id, in: raum))
        } else {
            self
        }
    }

    /// Wird beim Wegscrollen nach oben weich kleiner und blasser.
    func wegscrollenSchrumpfen() -> some View {
        scrollTransition(.interactive, axis: .vertical) { inhalt, phase in
            let v = min(phase.value, 0)
            return inhalt
                .scaleEffect(1 + 0.1 * CGFloat(v), anchor: .bottom)
                .opacity(1 + 0.6 * v)
        }
    }
}

struct Jubeln: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemRuhig
    @AppStorage(Sparmodus.key) private var spar = false
    /// Ruhig bei "Bewegung reduzieren", im Sparmodus und im Stromsparmodus
    private var ruhig: Bool { systemRuhig || spar || Sparmodus.stromsparen }

    @ViewBuilder
    func body(content: Content) -> some View {
        if ruhig {
            content
        } else {
            content.phaseAnimator([false, true]) { inhalt, an in
                inhalt
                    .scaleEffect(an ? 1.08 : 0.96)
                    .rotationEffect(.degrees(an ? 6 : -6))
            } animation: { _ in
                .easeInOut(duration: 0.7)
            }
        }
    }
}

struct Einblenden: ViewModifier {
    let index: Int
    @State private var da = false
    @Environment(\.accessibilityReduceMotion) private var systemRuhig
    @AppStorage(Sparmodus.key) private var spar = false
    /// Ruhig bei "Bewegung reduzieren", im Sparmodus und im Stromsparmodus
    private var ruhig: Bool { systemRuhig || spar || Sparmodus.stromsparen }

    func body(content: Content) -> some View {
        let sichtbar = da || ruhig
        content
            .opacity(sichtbar ? 1 : 0)
            .offset(y: sichtbar ? 0 : 24)
            .scaleEffect(sichtbar ? 1 : 0.97)
            .onAppear {
                guard !da else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(Double(min(index, 10)) * 0.05)) {
                    da = true
                }
            }
    }
}

// MARK: Zahlen, die hochzählen

/// Zeigt eine Zahl, die beim Erscheinen von 0 auf den Zielwert hochrollt.
struct ZaehlText: View {
    let wert: Int
    var vorne: String = ""
    var hinten: String = ""
    var verzoegerung: Double = 0
    @State private var angezeigt = 0

    var body: some View {
        Text("\(vorne)\(angezeigt)\(hinten)")
            .contentTransition(.numericText(value: Double(angezeigt)))
            .task(id: wert) {
                angezeigt = 0
                try? await Task.sleep(for: .seconds(verzoegerung))
                withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) { angezeigt = wert }
            }
    }
}

// MARK: Neigen

/// Liest, wie das iPhone gehalten wird, für einen leichten Tiefeneffekt.
/// Läuft nur, solange eine Kopfkarte zu sehen ist. Braucht keine Erlaubnis.
@Observable
final class Neigung {
    static let shared = Neigung()
    /// -1 bis 1, links und rechts
    var x: Double = 0
    /// -1 bis 1, vor und zurück
    var y: Double = 0

    private let sensor = CMMotionManager()
    @ObservationIgnored private var nutzer = 0

    func anmelden() {
        nutzer += 1
        guard nutzer == 1, sensor.isDeviceMotionAvailable,
              !UIAccessibility.isReduceMotionEnabled, !Sparmodus.an else { return }
        sensor.deviceMotionUpdateInterval = 1.0 / 20.0
        // Muss .main bleiben, die Werte gehören dem Haupt-Thread
        sensor.startDeviceMotionUpdates(to: .main) { [weak self] daten, _ in
            guard let self, let daten else { return }
            let nx = max(-1, min(1, daten.gravity.x * 2))
            let ny = max(-1, min(1, (daten.gravity.y + 0.6) * 2))
            // Weich nachziehen, damit nichts zittert
            let neuX = self.x * 0.8 + nx * 0.2
            let neuY = self.y * 0.8 + ny * 0.2
            // Jede Änderung zeichnet das Bild neu. Kleinste Bewegungen sieht man nicht.
            if abs(neuX - self.x) > 0.01 { self.x = neuX }
            if abs(neuY - self.y) > 0.01 { self.y = neuY }
        }
    }

    func abmelden() {
        nutzer = max(0, nutzer - 1)
        if nutzer == 0 {
            sensor.stopDeviceMotionUpdates()
            x = 0
            y = 0
        }
    }
}
