import SwiftUI

// ============================================================
// MARK: - Erklär-Freund
// ============================================================
//
// Nach einer falschen Antwort kann das Kind auf "Warum?" tippen. Die Eule erklärt dann,
// wo der Denkfehler lag. Den Grund findet FehlerAnalyse im Code, die KI auf dem Gerät
// formuliert ihn nur kindgerecht. Ohne KI erscheint der feste Satz, der genauso stimmt.

struct ErklaerFreund: View {
    let art: String
    let rechnung: String
    let erklaerung: String
    let antwort: String
    let antwort2: String
    /// Was das Kind eingegeben hat, bei Rest als "14 Rest 2"
    let gegeben: String

    @State private var text: String?
    @State private var laedt = false
    @State private var vonKI = false

    private var teile: (String, String) {
        let t = gegeben.components(separatedBy: " Rest ")
        return t.count == 2 ? (t[0], t[1]) : (gegeben, "")
    }

    private var befund: FehlerBefund? {
        FehlerAnalyse.befund(art: art, rechnung: rechnung, erklaerung: erklaerung,
                             antwort: antwort, antwort2: antwort2,
                             eingabe: teile.0, eingabe2: teile.1)
    }

    private var loesung: String {
        art == "rest" ? "\(antwort) Rest \(antwort2)" : antwort
    }

    /// Ohne erkannten Fehler und ohne KI gibt es nichts zu erklären, was nicht schon dasteht.
    static func lohntSich(art: String, rechnung: String, erklaerung: String,
                          antwort: String, antwort2: String, gegeben: String) -> Bool {
        guard art != "mauer" else { return false }
        let t = gegeben.components(separatedBy: " Rest ")
        let b = FehlerAnalyse.befund(art: art, rechnung: rechnung, erklaerung: erklaerung,
                                     antwort: antwort, antwort2: antwort2,
                                     eingabe: t.first ?? "", eingabe2: t.count == 2 ? t[1] : "")
        return b != nil || KIText.verfuegbar
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let text {
                HStack(alignment: .top, spacing: 10) {
                    Text("🦉").font(.system(size: 30))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(text)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.white)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 14) {
                            Button {
                                Sprecher.shared.sprich(text, code: "de-DE")
                            } label: {
                                Label("Vorlesen", systemImage: "speaker.wave.2.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.gelb)
                            }
                            if vonKI {
                                Text("✨ von der KI auf diesem Gerät")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSanft)
                            }
                        }
                    }
                }
                .transition(.opacity)
            } else {
                Button {
                    Task { await erklaeren() }
                } label: {
                    HStack(spacing: 8) {
                        if laedt {
                            ProgressView().tint(Theme.gelb)
                            Text("Die Eule denkt nach ...")
                        } else {
                            Text("🦉")
                            Text("Warum war das falsch?")
                        }
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Theme.gelb.opacity(0.15), in: Capsule())
                }
                .disabled(laedt)
            }
        }
    }

    private func erklaeren() async {
        laedt = true
        let b = befund
        let ersatz: String
        if let b {
            ersatz = b.satz
        } else {
            ersatz = erklaerung.isEmpty ? "Richtig ist \(loesung)." : "Richtig ist \(loesung). \(erklaerung)"
        }
        let fakten = """
        Aufgabe: \(rechnung.replacingOccurrences(of: "\n", with: " "))
        Das Kind hat geschrieben: \(gegeben)
        Richtig ist: \(loesung)
        Erklärung: \(ersatz)
        """
        var anweisung = """
        Du bist eine freundliche Eule, die einem Kind der 3. Klasse in Deutschland beim Lernen hilft. \
        Formuliere die Erklärung neu, damit das Kind sie gut versteht: höchstens drei kurze Sätze, \
        einfache Wörter, ermutigend, in der Du-Form. Ändere keine Zahl und erfinde keine neuen Zahlen. \
        Benutze für mal das Zeichen · und für geteilt das Zeichen :. \
        Kein Markdown, keine Aufzählung, keine Gedankenstriche. Schreibe nur den Text.
        """
        if b == nil {
            anweisung += " Nenne keinen Grund für den Fehler, erkläre nur den richtigen Weg."
        }
        let ergebnis = await KIText.formuliere(anweisung: anweisung, fakten: fakten,
                                               ersatz: ersatz, maxZeichen: 320)
        withAnimation(.easeOut(duration: 0.25)) {
            text = ergebnis.text
            vonKI = ergebnis.vonKI
            laedt = false
        }
    }
}
