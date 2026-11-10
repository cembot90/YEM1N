import SwiftUI
import SwiftData

// ============================================================
// MARK: - Eltern: einzelne Antworten des Kindes
// ============================================================
//
// Drei Ansichten:
// - RundeDetailView: alle Aufgaben einer Runde mit der Eingabe des Kindes
// - UebungDetailView: ein Bereich aus dem Schwächen-Radar, mit den Aufgaben, die haken,
//   und allen Runden dieser Übung
// - ProblemZeile und AntwortZeile: die Bausteine dafür, auch in der Übersicht benutzt

/// Für .sheet(item:), wenn im Schwächen-Radar eine Übung angetippt wird.
struct UebungAuswahl: Identifiable {
    let titel: String
    var id: String { titel }
}

// MARK: Bausteine

enum AntwortFarbe {
    static func farbe(_ stand: String) -> Color {
        switch stand {
        case AntwortStand.richtig: return Theme.mint
        case AntwortStand.falsch: return Theme.koralle
        case AntwortStand.angeschaut: return Theme.himmel
        default: return Theme.textSanft
        }
    }

    static func symbol(_ stand: String) -> String {
        switch stand {
        case AntwortStand.richtig: return "checkmark.circle.fill"
        case AntwortStand.falsch: return "xmark.circle.fill"
        case AntwortStand.angeschaut: return "eye.fill"
        default: return "circle.dashed"
        }
    }
}

/// Eine Aufgabe einer Runde: Rechnung, was das Kind geschrieben hat, und die Lösung.
struct AntwortZeile: View {
    let detail: AntwortDetail

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: AntwortFarbe.symbol(detail.stand))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AntwortFarbe.farbe(detail.stand))
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(detail.rechnung.isEmpty ? detail.frage : detail.rechnung)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                if !detail.rechnung.isEmpty && !detail.frage.isEmpty {
                    Text(detail.frage)
                        .font(.caption)
                        .foregroundStyle(Theme.textSanft)
                }
                zeilen
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var zeilen: some View {
        switch detail.stand {
        case AntwortStand.falsch:
            Text("Geschrieben: \(AntwortProtokoll.einzeilig(detail.eingabe))")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.koralle)
            Text("Richtig: \(detail.loesung)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.mint)
        case AntwortStand.angeschaut:
            Text("Lösung angeschaut: \(detail.loesung)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.himmel)
        case AntwortStand.richtig:
            Text(detail.eingabe.isEmpty ? "Richtig" : "Richtig: \(AntwortProtokoll.einzeilig(detail.eingabe))")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSanft)
        default:
            Text("Nicht bearbeitet")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
        }
    }
}

/// Eine Aufgabe, die über mehrere Runden Probleme macht.
struct ProblemZeile: View {
    let problem: ProblemAufgabe
    var zeigeUebung = true

    private var zaehler: String {
        var teile: [String] = []
        if problem.falsch > 0 { teile.append("\(problem.falsch)× falsch") }
        if problem.angeschaut > 0 { teile.append("\(problem.angeschaut)× Lösung angeschaut") }
        if problem.richtig > 0 { teile.append("\(problem.richtig)× richtig") }
        return teile.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(problem.rechnung.isEmpty ? problem.frage : problem.rechnung)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if problem.zuletztRichtig {
                    Label("sitzt jetzt", systemImage: "checkmark")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Theme.mint)
                        .labelStyle(.titleAndIcon)
                }
            }
            if zeigeUebung {
                Text(problem.uebung)
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
            }
            if !problem.falscheEingaben.isEmpty {
                Text("Geschrieben: " + problem.falscheEingaben.prefix(4).joined(separator: ", "))
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.koralle)
            }
            Text("Richtig: \(problem.loesung)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.mint)
            Text(zaehler)
                .font(.caption)
                .foregroundStyle(Theme.textSanft)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

/// Kopf mit Titel und Schließen-Knopf für die Blätter.
private struct BlattKopf: View {
    let titel: String
    let unterzeile: String
    let schliessen: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titel)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                    .fixedSize(horizontal: false, vertical: true)
                Text(unterzeile)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            Button(action: schliessen) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 36, height: 36)
                    .background(Theme.gelb, in: Circle())
            }
            .accessibilityLabel("Schließen")
        }
    }
}

// MARK: Eine Runde

struct RundeDetailView: View {
    let runde: RundenErgebnis
    var mitKopf = true
    @Environment(\.dismiss) private var dismiss
    @State private var nurFehler = false

    private var antworten: [AntwortDetail] { runde.antworten }
    private var probleme: Int { antworten.filter { $0.istProblem }.count }
    private var sichtbar: [AntwortDetail] { nurFehler ? antworten.filter { $0.istProblem } : antworten }

    private var unterzeile: String {
        var t = runde.kind.isEmpty ? "" : runde.kind + " · "
        t += runde.arbeit + " · " + runde.zeitpunkt.formatted(date: .abbreviated, time: .shortened)
        return t
    }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if mitKopf {
                        BlattKopf(titel: runde.uebung, unterzeile: unterzeile) { dismiss() }
                    } else {
                        Text(unterzeile)
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                    }
                    HStack(spacing: 12) {
                        StatKachel(titel: "Richtig", wert: "\(runde.richtig)/\(runde.gesamt)", symbol: "checkmark.circle.fill")
                        StatKachel(titel: "Falsch", wert: "\(antworten.filter { $0.stand == AntwortStand.falsch }.count)", symbol: "xmark.circle.fill")
                        StatKachel(titel: "Angeschaut", wert: "\(runde.angesehen)", symbol: "eye.fill")
                    }
                    if antworten.isEmpty {
                        Text("Für diese Runde gibt es keine einzelnen Antworten. Sie stammt aus einer älteren App-Version oder einem Bereich, der nur die Punkte meldet (Sprachen und Vorschule).")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSanft)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glasKarte(radius: 22)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            if probleme > 0 {
                                Toggle("Nur Fehler und angeschaute Lösungen", isOn: $nurFehler)
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(Color.white)
                                    .tint(Theme.gelb)
                                    .padding(.bottom, 4)
                            }
                            ForEach(sichtbar) { d in
                                AntwortZeile(detail: d)
                                if d.id != sichtbar.last?.id {
                                    Divider().overlay(Color.white.opacity(0.12))
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glasKarte(radius: 26)
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(mitKopf ? "" : runde.uebung)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }
}

// MARK: Ein Bereich (Übung) aus dem Schwächen-Radar

struct UebungDetailView: View {
    let titel: String
    /// Alle Runden dieser Übung im gewählten Zeitraum, neueste zuerst
    let runden: [RundenErgebnis]
    let zeitraum: String
    @Environment(\.dismiss) private var dismiss

    private var probleme: [ProblemAufgabe] {
        AntwortProtokoll.problemAufgaben(runden.map { (uebung: $0.uebung, zeitpunkt: $0.zeitpunkt, details: $0.details) },
                                         limit: 50)
    }

    private var anteilText: String {
        let r = runden.reduce(0) { $0 + $1.richtig }
        let g = runden.reduce(0) { $0 + $1.gesamt }
        guard g > 0 else { return "" }
        return "\(Int((Double(r) / Double(g) * 100).rounded())) % richtig in \(runden.count) \(runden.count == 1 ? "Runde" : "Runden")"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        BlattKopf(titel: titel, unterzeile: [zeitraum, anteilText].filter { !$0.isEmpty }.joined(separator: " · ")) {
                            dismiss()
                        }
                        problemKarte
                        rundenKarte
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }

    private var problemKarte: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diese Aufgaben haken")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            if probleme.isEmpty {
                Text(runden.contains(where: { !$0.details.isEmpty })
                     ? "Keine Fehler in diesem Zeitraum."
                     : "Für diese Runden gibt es noch keine einzelnen Antworten. Sie kommen ab der neuen App-Version auf dem Gerät des Kindes.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSanft)
            } else {
                ForEach(probleme) { p in
                    ProblemZeile(problem: p, zeigeUebung: false)
                    if p.id != probleme.last?.id {
                        Divider().overlay(Color.white.opacity(0.12))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var rundenKarte: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Alle Runden")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            ForEach(runden, id: \.eintragID) { e in
                NavigationLink {
                    RundeDetailView(runde: e, mitKopf: false)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(e.zeitpunkt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.white)
                            Text((e.kind.isEmpty ? "" : e.kind + " · ") + e.arbeit)
                                .font(.caption)
                                .foregroundStyle(Theme.textSanft)
                        }
                        Spacer()
                        Text("\(e.richtig) von \(e.gesamt)")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.textSanft)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }
}
