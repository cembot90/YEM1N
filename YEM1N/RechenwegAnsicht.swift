import SwiftUI

// ============================================================
// MARK: - Rechenweg: Schritt für Schritt rechnen
// ============================================================
//
// Das Kind rechnet jeden kleinen Schritt selbst. Fertige Schritte bleiben stehen,
// so entsteht der Rechenweg wie im Heft. Am Ende kann das Ergebnis in die Aufgabe.

struct RechenwegKnopf: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("In Schritten", systemImage: "list.number")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.mint)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(Theme.mint.opacity(0.14), in: Capsule())
        }
        .buttonStyle(TastenStil())
        .accessibilityHint("Rechnet die Aufgabe in kleinen Schritten")
    }
}

struct RechenwegSheet: View {
    let aufgabe: String
    let weg: RechenWeg
    /// Übernimmt Ergebnis und Rest in die Aufgabe
    let uebernehmen: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var nr = 0
    @State private var eingabe = ""
    @State private var fehlversuche = 0
    @State private var meldung: String?
    @State private var wackeln = 0
    @FocusState private var fokus: Bool

    private var fertig: Bool { nr >= weg.schritte.count }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(aufgabe)
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 6)

                        ForEach(Array(weg.schritte.enumerated()), id: \.offset) { i, s in
                            if i < nr {
                                erledigt(i, s)
                            } else if i == nr {
                                aktuell(i, s)
                            }
                        }

                        if fertig { schluss }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Schritt für Schritt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .onAppear { sprich() }
    }

    private func erledigt(_ i: Int, _ s: RechenSchritt) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.mint)
            Text("\(s.rechnung) \(s.antwort)")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func aktuell(_ i: Int, _ s: RechenSchritt) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Schritt \(i + 1) von \(weg.schritte.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.gelb)
                Spacer()
                Button { sprich() } label: {
                    Image(systemName: "speaker.wave.2.fill").foregroundStyle(Theme.gelb)
                }
                .accessibilityLabel("Vorlesen")
            }
            Text(s.hinweis)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.textSanft)
            HStack(spacing: 10) {
                Text(s.rechnung)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                TextField("?", text: $eingabe)
                    .keyboardType(.numberPad)
                    .focused($fokus)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(width: 96, height: 54)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.gelb, lineWidth: 2))
                    .offset(x: wackeln % 2 == 0 ? 0 : 8)
                    .animation(.spring(response: 0.18, dampingFraction: 0.25), value: wackeln)
                    .onChange(of: eingabe) { _, neu in
                        let ziffern = String(neu.filter(\.isNumber).prefix(4))
                        if ziffern != neu { eingabe = ziffern }
                    }
            }
            if let m = meldung {
                Text(m)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.koralle)
            }
            GelberKnopf(titel: "Prüfen") { pruefe(s) }
        }
        .padding(16)
        .glasKarte(radius: 22)
        .onAppear { fokus = true }
    }

    private var schluss: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Geschafft! 🎉")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text(weg.schluss)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
            if let a = weg.antwort {
                GelberKnopf(titel: "Ergebnis eintragen") {
                    uebernehmen(a, weg.antwort2 ?? "")
                    dismiss()
                }
                Text("Danach tippst du in der Aufgabe auf Prüfen.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            } else {
                GelberKnopf(titel: "Zurück zur Aufgabe") { dismiss() }
            }
        }
        .padding(16)
        .glasKarte(radius: 22)
    }

    private func pruefe(_ s: RechenSchritt) {
        guard let n = Int(eingabe) else { return }
        if n == s.antwort {
            Haptik.erfolg()
            meldung = nil
            fehlversuche = 0
            eingabe = ""
            withAnimation(.snappy) { nr += 1 }
            if fertig {
                fokus = false
                Sprecher.shared.sprich(weg.schluss, code: "de-DE", stimmung: .froh)
            } else {
                sprich()
            }
        } else {
            Haptik.fehler()
            fehlversuche += 1
            wackeln += 1
            eingabe = ""
            // Nach zwei Versuchen hilft die Lösung des Schritts weiter, damit niemand hängen bleibt
            meldung = fehlversuche >= 2
                ? "Es sind \(s.antwort). Tippe \(s.antwort) ein und mach weiter."
                : "Noch nicht. Schau noch mal genau hin."
        }
    }

    private func sprich() {
        guard nr < weg.schritte.count else { return }
        let s = weg.schritte[nr]
        Sprecher.shared.sprich(s.hinweis + " " + VorleseText.aufgabe(frage: "", rechnung: s.rechnung)
            .trimmingCharacters(in: CharacterSet(charactersIn: ". ")), code: "de-DE")
    }
}
