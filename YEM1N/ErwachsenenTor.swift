import SwiftUI

// ============================================================
// MARK: - Erwachsenen-Tor
// ============================================================
//
// Steht vor allem, was aus der App hinausführt (Links, Mail, Teilen) und vor den Einstellungen.
// Gilt auf jedem Gerät, auch ohne Familie. Mit Eltern-PIN reicht die PIN, sonst eine Malaufgabe,
// die Kinder bis Klasse 4 nicht im Kopf rechnen. Danach bleibt das Tor fünf Minuten offen.

@Observable
final class ErwachsenenTor {
    static let shared = ErwachsenenTor()

    @ObservationIgnored private var offenBis: Date = .distantPast
    /// Zählt hoch, wenn das Tor geöffnet wird, damit die Oberfläche neu zeichnet.
    private(set) var zaehler = 0

    var offen: Bool {
        _ = zaehler
        return Date.now < offenBis || FamilienModell.shared.entsperrt
    }

    func oeffnen() {
        offenBis = Date.now.addingTimeInterval(ElternPin.offenSekunden)
        zaehler += 1
    }
}

/// Die Seite mit der Frage. [fertig] läuft, wenn die Antwort oder die PIN stimmt.
struct TorAnsicht: View {
    var fertig: () -> Void
    private let familie = FamilienModell.shared
    @State private var frage = ElternFrage.neu()
    @State private var eingabe = ""
    @State private var fehler = ""
    @FocusState private var fokus: Bool

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 18) {
                    Text("🔒")
                        .font(.system(size: 54))
                        .padding(.top, 50)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nur für Erwachsene")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        Text("Hier geht es zu den Einstellungen oder aus der App hinaus. Bitte frag Mama oder Papa.")
                            .font(.subheadline)
                            .foregroundStyle(Color.white)
                        Text(frage.text)
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.white)
                            .padding(.top, 6)
                        TextField("Ergebnis", text: $eingabe)
                            .keyboardType(.numberPad)
                            .focused($fokus)
                            .padding(14)
                            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .onChange(of: eingabe) { eingabe = String(eingabe.filter(\.isNumber).prefix(8)); fehler = "" }
                            .onSubmit { pruefen() }
                        if familie.pinGesetzt {
                            Text("Oder die Eltern-PIN eingeben.")
                                .font(.footnote)
                                .foregroundStyle(Theme.textSanft)
                        }
                        if !fehler.isEmpty {
                            Text(fehler).font(.footnote.weight(.semibold)).foregroundStyle(Theme.koralle)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glasKarte(radius: 26)

                    GelberKnopf(titel: "Weiter") { pruefen() }
                        .disabled(eingabe.isEmpty)
                        .opacity(eingabe.isEmpty ? 0.4 : 1)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear { fokus = true }
    }

    private func pruefen() {
        var richtig = frage.stimmt(eingabe)
        // Nur Eingaben, die eine PIN sein können, zählen als PIN-Versuch (sonst gäbe es unnötig Wartezeit).
        if !richtig && familie.pinGesetzt && ElternPin.gueltig(eingabe) {
            richtig = familie.pinPruefen(eingabe) == nil
        }
        if richtig {
            ErwachsenenTor.shared.oeffnen()
            Haptik.erfolg()
            fertig()
        } else {
            fehler = "Das stimmt leider nicht. Hier ist eine neue Aufgabe."
            frage = ElternFrage.neu()
            eingabe = ""
            Haptik.fehler()
        }
    }
}

/// Ein ganzer Bereich hinter dem Tor, zum Beispiel die Einstellungen.
struct ErwachsenenBereich<Inhalt: View>: View {
    @ViewBuilder var inhalt: () -> Inhalt
    @State private var durch = false

    var body: some View {
        if durch || ErwachsenenTor.shared.offen {
            inhalt()
        } else {
            TorAnsicht { durch = true }
        }
    }
}

private struct TorFenster: ViewModifier {
    @Binding var zeigen: Bool
    let dann: () -> Void
    @State private var bestanden = false

    func body(content: Content) -> some View {
        content.sheet(isPresented: $zeigen, onDismiss: {
            if bestanden {
                bestanden = false
                dann()
            }
        }) {
            TorAnsicht {
                bestanden = true
                zeigen = false
            }
        }
    }
}

extension View {
    /// Zeigt das Erwachsenen-Tor, sobald [zeigen] true wird. Nach bestandenem Tor läuft [dann].
    func erwachsenenTor(_ zeigen: Binding<Bool>, dann: @escaping () -> Void) -> some View {
        modifier(TorFenster(zeigen: zeigen, dann: dann))
    }
}

/// Knopf, dessen Aktion erst nach dem Tor läuft. Ist das Tor noch offen, sofort.
struct TorKnopf<Beschriftung: View>: View {
    let aktion: () -> Void
    @ViewBuilder var beschriftung: () -> Beschriftung
    @State private var zeigeTor = false

    var body: some View {
        Button {
            if ErwachsenenTor.shared.offen { aktion() } else { zeigeTor = true }
        } label: {
            beschriftung()
        }
        .erwachsenenTor($zeigeTor, dann: aktion)
    }
}

/// Link nach außen (Browser, Mail) hinter dem Tor.
struct TorLink<Beschriftung: View>: View {
    let url: URL
    @ViewBuilder var beschriftung: () -> Beschriftung
    @Environment(\.openURL) private var openURL

    var body: some View {
        TorKnopf(aktion: { openURL(url) }, beschriftung: beschriftung)
    }
}

/// Teilen-Knopf hinter dem Tor.
struct TorTeilen<Beschriftung: View>: View {
    let text: String
    @ViewBuilder var beschriftung: () -> Beschriftung
    @State private var zeigeTeilen = false

    var body: some View {
        TorKnopf(aktion: { zeigeTeilen = true }, beschriftung: beschriftung)
            .sheet(isPresented: $zeigeTeilen) {
                ShareSheet(items: [text])
                    .presentationDetents([.medium, .large])
            }
    }
}
