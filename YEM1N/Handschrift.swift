import SwiftUI
import UIKit
import PencilKit
import Vision

// ============================================================
// MARK: - Mit dem Stift schreiben
// ============================================================
//
// In der Klassenarbeit schreibt das Kind mit der Hand. Darum kann es die Antwort auch
// mit dem Apple Pencil oder dem Finger auf ein Karoblatt schreiben. Die Texterkennung
// von Apple liest die Ziffern auf dem Gerät, es geht nichts ins Internet.
// Die gelesene Zahl steht sofort im Antwortfeld. Das Kind sieht also, was die App
// gelesen hat, und prüft erst dann. Die Zahlentasten bleiben immer als Ausweg.

enum Handschrift {
    static let key = "stiftEingabe"

    /// Auf dem iPad ist der Stift von Anfang an an, auf dem iPhone die Tasten.
    static var standard: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    /// Zeichen, die beim Lesen von handgeschriebenen Ziffern oft herauskommen.
    /// Nur eindeutige Fälle, damit aus einem Buchstaben keine falsche Ziffer wird.
    static let ersatz: [Character: Character] = [
        "O": "0", "o": "0", "D": "0", "Q": "0", "°": "0",
        "l": "1", "I": "1", "i": "1", "|": "1", "!": "1", "/": "1", "]": "1", "[": "1",
        "Z": "2", "z": "2",
        "S": "5", "s": "5",
        "b": "6", "G": "6",
        "T": "7",
        "B": "8",
        "g": "9", "q": "9"
    ]

    /// Zeichen ohne Bedeutung, zum Beispiel ein Punkt, wenn der Stift kurz aufkommt.
    static let ohneBedeutung: Set<Character> = [".", ",", "'", "`", "_", "-", "~", "\u{00B4}"]

    /// Macht aus einem gelesenen Text eine Zahl. nil, wenn der Text keine Zahl ist.
    static func zahl(aus gelesen: String, maxLaenge: Int) -> String? {
        var ziffern = ""
        for ch in gelesen {
            if ch.isWhitespace || ohneBedeutung.contains(ch) { continue }
            if ch.isASCII, ch.isNumber {
                ziffern.append(ch)
            } else if let e = ersatz[ch] {
                ziffern.append(e)
            } else {
                return nil
            }
        }
        while ziffern.count > 1 && ziffern.first == "0" { ziffern.removeFirst() }
        guard !ziffern.isEmpty, ziffern.count <= maxLaenge else { return nil }
        return ziffern
    }

    /// Die Texterkennung liefert für jedes Stück Schrift von links nach rechts mehrere
    /// Vorschläge. Von jedem Stück nehmen wir den ersten Vorschlag, der eine Zahl ist.
    /// Stücke ohne Zahl, etwa ein Krakel am Rand, fallen weg.
    static func lies(_ stuecke: [[String]], maxLaenge: Int) -> String? {
        var gesamt = ""
        for vorschlaege in stuecke {
            if let z = vorschlaege.lazy.compactMap({ zahl(aus: $0, maxLaenge: 12) }).first {
                gesamt += z
            }
        }
        return zahl(aus: gesamt, maxLaenge: maxLaenge)
    }

    // MARK: Lesen mit der Texterkennung

    /// Läuft ohne Bildschirm, damit das Lesen die Oberfläche nicht anhält.
    nonisolated static func erkenne(_ bild: CGImage) -> [[String]] {
        let anfrage = VNRecognizeTextRequest()
        anfrage.recognitionLevel = .accurate
        anfrage.usesLanguageCorrection = false
        anfrage.recognitionLanguages = ["en-US"]
        let handler = VNImageRequestHandler(cgImage: bild, options: [:])
        do {
            try handler.perform([anfrage])
        } catch {
            return []
        }
        let stuecke = (anfrage.results ?? []).sorted { $0.boundingBox.minX < $1.boundingBox.minX }
        return stuecke.map { stueck in stueck.topCandidates(5).map { $0.string } }
    }

    /// Schwarze Schrift auf weißem Grund mit etwas Rand. So liest die Erkennung am besten.
    static func bild(von zeichnung: PKDrawing) -> CGImage? {
        let rahmen = zeichnung.bounds
        guard !rahmen.isEmpty, rahmen.width.isFinite, rahmen.height.isFinite else { return nil }
        let rand = max(rahmen.height * 0.4, 24)
        let flaeche = rahmen.insetBy(dx: -rand, dy: -rand)
        let skala = min(max(180 / flaeche.height, 1), 4)
        var fertig: CGImage?
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            let striche = zeichnung.image(from: flaeche, scale: skala)
            let groesse = CGSize(width: flaeche.width * skala, height: flaeche.height * skala)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let maler = UIGraphicsImageRenderer(size: groesse, format: format)
            let bild = maler.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: groesse))
                striche.draw(in: CGRect(origin: .zero, size: groesse))
            }
            fertig = bild.cgImage
        }
        return fertig
    }
}

// MARK: - Schreibfeld mit Karopapier

struct SchreibFeld: View {
    @Binding var text: String
    var maxLaenge = 3
    var onPruefen: () -> Void

    @State private var zeichnung = PKDrawing()
    @State private var liest = false
    @State private var nichtLesbar = false
    @State private var lesen: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                KaroPapier()
                SchreibLeinwand(zeichnung: $zeichnung) { planeLesen($0) }
                if zeichnung.strokes.isEmpty {
                    Label("Schreib hier deine Zahl", systemImage: "pencil.and.scribble")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(Color(red: 0.55, green: 0.6, blue: 0.7))
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.gelb.opacity(0.7), lineWidth: 2))

            HStack(spacing: 12) {
                Button {
                    leeren()
                } label: {
                    Label("Wegwischen", systemImage: "eraser.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Theme.koralle.opacity(0.30), in: Capsule())
                }
                .buttonStyle(TastenStil())

                Group {
                    if liest {
                        Text("Ich lese ...")
                    } else if nichtLesbar {
                        Text("Nicht lesbar. Schreib etwas größer.")
                    } else {
                        Text(" ")
                    }
                }
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSanft)
                .frame(maxWidth: .infinity)

                Button(action: onPruefen) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(Theme.navy)
                        .frame(width: 64, height: 50)
                        .background(Theme.gelb, in: Capsule())
                }
                .buttonStyle(TastenStil())
                .disabled(text.isEmpty || liest)
                .opacity(text.isEmpty || liest ? 0.45 : 1)
                .accessibilityLabel("Prüfen")
            }
        }
        .padding(.horizontal, 24)
        .onDisappear { lesen?.cancel() }
    }

    private func leeren() {
        lesen?.cancel()
        zeichnung = PKDrawing()
        text = ""
        liest = false
        nichtLesbar = false
    }

    /// Kurz nach dem letzten Strich wird gelesen. Wer weiterschreibt, startet die Pause neu.
    private func planeLesen(_ z: PKDrawing) {
        lesen?.cancel()
        guard !z.strokes.isEmpty else {
            text = ""
            liest = false
            return
        }
        let laenge = maxLaenge
        lesen = Task {
            do { try await Task.sleep(for: .milliseconds(600)) } catch { return }
            liest = true
            guard let bild = Handschrift.bild(von: z) else {
                liest = false
                return
            }
            let gelesen = await Task.detached(priority: .userInitiated) {
                Handschrift.erkenne(bild)
            }.value
            guard !Task.isCancelled else { return }
            liest = false
            if let zahl = Handschrift.lies(gelesen, maxLaenge: laenge) {
                text = zahl
                nichtLesbar = false
            } else {
                text = ""
                nichtLesbar = true
            }
        }
    }
}

/// Helles Karopapier wie im Matheheft
struct KaroPapier: View {
    var body: some View {
        Canvas { ctx, groesse in
            ctx.fill(Path(CGRect(origin: .zero, size: groesse)),
                     with: .color(Color(red: 0.98, green: 0.98, blue: 0.96)))
            let kaestchen: CGFloat = 22
            var linien = Path()
            var x: CGFloat = kaestchen
            while x < groesse.width {
                linien.move(to: CGPoint(x: x, y: 0))
                linien.addLine(to: CGPoint(x: x, y: groesse.height))
                x += kaestchen
            }
            var y: CGFloat = kaestchen
            while y < groesse.height {
                linien.move(to: CGPoint(x: 0, y: y))
                linien.addLine(to: CGPoint(x: groesse.width, y: y))
                y += kaestchen
            }
            ctx.stroke(linien, with: .color(Color(red: 0.62, green: 0.75, blue: 0.9).opacity(0.55)),
                       lineWidth: 0.8)
        }
        .allowsHitTesting(false)
    }
}

/// Die Fläche, auf der geschrieben wird. Finger und Stift schreiben beide.
struct SchreibLeinwand: UIViewRepresentable {
    @Binding var zeichnung: PKDrawing
    var beiAenderung: (PKDrawing) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let c = PKCanvasView()
        c.drawingPolicy = .anyInput
        c.backgroundColor = .clear
        c.isOpaque = false
        c.isScrollEnabled = false
        c.overrideUserInterfaceStyle = .light
        c.drawing = zeichnung
        c.tool = PKInkingTool(.pen, color: UIColor(red: 0.05, green: 0.1, blue: 0.3, alpha: 1), width: 7)
        c.delegate = context.coordinator
        return c
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        context.coordinator.eltern = self
        if uiView.drawing != zeichnung {
            uiView.drawing = zeichnung
        }
    }

    func makeCoordinator() -> Koordinator { Koordinator(self) }

    final class Koordinator: NSObject, PKCanvasViewDelegate {
        var eltern: SchreibLeinwand
        init(_ eltern: SchreibLeinwand) { self.eltern = eltern }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard canvasView.drawing != eltern.zeichnung else { return }
            eltern.zeichnung = canvasView.drawing
            eltern.beiAenderung(canvasView.drawing)
        }
    }
}

/// Schalter zwischen Stift und Tasten, direkt über der Eingabe
struct EingabeUmschalter: View {
    @Binding var stift: Bool

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.25)) { stift.toggle() }
            Haptik.leicht()
        } label: {
            Label(stift ? "Lieber Tasten" : "Mit dem Stift schreiben",
                  systemImage: stift ? "circle.grid.3x3.fill" : "pencil.tip")
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.gelb)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(Theme.gelb.opacity(0.14), in: Capsule())
        }
        .buttonStyle(TastenStil())
    }
}
