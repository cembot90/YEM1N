import SwiftUI
import CryptoKit

// ============================================================
// MARK: - Elternbericht in Worten
// ============================================================
//
// Aus den Runden der letzten 7 Tagen entsteht ein kurzer Text für die Eltern:
// wie viel geübt wurde, was sitzt, wo es hakt und welcher Denkfehler dahinter steckt.
// Alle Zahlen und Befunde rechnet der Code aus. Die KI auf dem Gerät macht daraus
// nur einen flüssigen Text. Kann sie das nicht, steht der feste Text da.
// Sonntags um 18 Uhr kommt eine Mitteilung, ein Tipp darauf öffnet den Bericht direkt.

/// Die Daten einer Runde, die der Bericht braucht. Einfach gehalten, damit es sich testen lässt.
struct BerichtRunde {
    var kind: String
    var uebung: String
    var zeitpunkt: Date
    var richtig: Int
    var gesamt: Int
    var angesehen: Int
    var details: String
}

extension RundenErgebnis {
    var berichtRunde: BerichtRunde {
        BerichtRunde(kind: kind, uebung: uebung, zeitpunkt: zeitpunkt,
                     richtig: richtig, gesamt: gesamt, angesehen: angesehen, details: details)
    }
}

/// Ein Denkfehler, der in der Woche mehrfach vorkam.
struct BerichtMuster: Equatable {
    let muster: FehlerMuster
    let anzahl: Int
    /// Zum Beispiel "48 : 4, geschrieben 10 Rest 8, richtig 12 Rest 0"
    let beispiel: String
}

struct KindBericht: Equatable {
    var name: String
    var runden = 0
    var tage = 0
    var richtig = 0
    var gesamt = 0
    var angesehen = 0
    var stark: [String] = []
    var ueben: [String] = []
    var muster: [BerichtMuster] = []

    var prozent: Int { gesamt > 0 ? Int((Double(richtig) / Double(gesamt) * 100).rounded()) : 0 }
}

enum ElternBericht {
    static let tage = 7

    // MARK: Zeitraum und Hinweis

    /// Beginn des Berichtszeitraums: heute und die 6 Tage davor.
    static func beginn(jetzt: Date = .now, kalender: Calendar = .current) -> Date {
        kalender.date(byAdding: .day, value: -(tage - 1), to: kalender.startOfDay(for: jetzt)) ?? .distantPast
    }

    /// Der letzte Sonntag 18 Uhr, der nicht in der Zukunft liegt. Ab da gilt ein neuer Bericht.
    static func letzterTermin(jetzt: Date = .now, kalender: Calendar = .current) -> Date {
        var d = DateComponents()
        d.weekday = 1
        d.hour = 18
        d.minute = 0
        return kalender.nextDate(after: jetzt, matching: d, matchingPolicy: .nextTime,
                                 direction: .backward) ?? jetzt
    }

    /// true, wenn seit dem letzten Sonntag 18 Uhr ein Bericht bereitliegt, den noch niemand gelesen hat.
    static func neuerBerichtDa(jetzt: Date = .now, gelesen: Date?, hatRunden: Bool,
                               kalender: Calendar = .current) -> Bool {
        guard hatRunden else { return false }
        let termin = letzterTermin(jetzt: jetzt, kalender: kalender)
        guard let gelesen else { return true }
        return gelesen < termin
    }

    // MARK: Auswerten

    static func kindBericht(name: String, runden: [BerichtRunde],
                            kalender: Calendar = .current) -> KindBericht {
        var b = KindBericht(name: name)
        b.runden = runden.count
        b.tage = Set(runden.map { kalender.startOfDay(for: $0.zeitpunkt) }).count
        b.richtig = runden.reduce(0) { $0 + $1.richtig }
        b.gesamt = runden.reduce(0) { $0 + $1.gesamt }
        b.angesehen = runden.reduce(0) { $0 + $1.angesehen }

        // Übungen nach Anteil richtig
        var bereiche: [(titel: String, anteil: Double, gesamt: Int)] = []
        for (titel, liste) in Dictionary(grouping: runden, by: \.uebung) {
            let g = liste.reduce(0) { $0 + $1.gesamt }
            let r = liste.reduce(0) { $0 + $1.richtig }
            if g > 0 { bereiche.append((titel, Double(r) / Double(g), g)) }
        }
        b.stark = bereiche
            .filter { $0.anteil >= 0.9 && $0.gesamt >= 5 }
            .sorted { $0.gesamt != $1.gesamt ? $0.gesamt > $1.gesamt : $0.titel < $1.titel }
            .prefix(2).map(\.titel)
        b.ueben = bereiche
            .filter { $0.anteil < 0.75 && $0.gesamt >= 3 }
            .sorted { $0.anteil != $1.anteil ? $0.anteil < $1.anteil : $0.titel < $1.titel }
            .prefix(2).map(\.titel)

        // Denkfehler zählen. Muster mit gleichem Elterntext werden zusammengefasst.
        var zaehler: [String: (muster: FehlerMuster, anzahl: Int, beispiel: String, zuletzt: Date)] = [:]
        for runde in runden {
            for d in AntwortProtokoll.liste(aus: runde.details) {
                guard let befund = FehlerAnalyse.befund(detail: d) else { continue }
                let schluessel = befund.muster.elternText
                let beispiel = "\(AntwortProtokoll.einzeilig(d.rechnung).replacingOccurrences(of: " =", with: "")), geschrieben \(d.eingabe), richtig \(d.loesung)"
                var e = zaehler[schluessel] ?? (muster: befund.muster, anzahl: 0, beispiel: beispiel, zuletzt: .distantPast)
                e.anzahl += 1
                if runde.zeitpunkt >= e.zuletzt {
                    e.beispiel = beispiel
                    e.zuletzt = runde.zeitpunkt
                }
                zaehler[schluessel] = e
            }
        }
        b.muster = zaehler.values
            .filter { $0.anzahl >= 2 }
            .sorted { $0.anzahl != $1.anzahl ? $0.anzahl > $1.anzahl : $0.muster.rawValue < $1.muster.rawValue }
            .prefix(2)
            .map { BerichtMuster(muster: $0.muster, anzahl: $0.anzahl, beispiel: $0.beispiel) }
        return b
    }

    /// Alle Kinder mit ihren Runden im Zeitraum. Ohne Namen heißt das Kind "Euer Kind".
    static func berichte(runden: [BerichtRunde], kinder: [String], jetzt: Date = .now,
                         kalender: Calendar = .current) -> [KindBericht] {
        let grenze = beginn(jetzt: jetzt, kalender: kalender)
        let diese = runden.filter { $0.zeitpunkt >= grenze && $0.zeitpunkt <= jetzt }
        let namen = kinder.isEmpty ? [""] : kinder
        return namen.map { name in
            let eigene = diese.filter { name.isEmpty || Kinder.gleich($0.kind, name) }
            return kindBericht(name: name, runden: eigene, kalender: kalender)
        }
    }

    // MARK: Fester Text

    /// Der Bericht als fertiger Text, ganz ohne KI. Er ist auch die Faktenliste für die KI.
    static func text(_ b: KindBericht) -> String {
        let n = b.name.isEmpty ? "Euer Kind" : b.name
        guard b.runden > 0 else {
            return "\(n) hat in den letzten \(tage) Tagen nicht in YEM1N geübt."
        }
        var s: [String] = []
        let tageText = b.tage == 1 ? "an 1 Tag" : "an \(b.tage) Tagen"
        let rundenText = b.runden == 1 ? "1 Runde" : "\(b.runden) Runden"
        s.append("\(n) hat in den letzten \(tage) Tagen \(tageText) geübt, \(rundenText) mit \(b.gesamt) Aufgaben.")
        s.append("\(b.richtig) davon waren richtig, das sind \(b.prozent) Prozent.")
        if b.angesehen > 0 {
            s.append(b.angesehen == 1 ? "Einmal wurde die Lösung angeschaut." : "\(b.angesehen)-mal wurde die Lösung angeschaut.")
        }
        if !b.stark.isEmpty {
            s.append("Sicher sitzt: \(liste(b.stark)).")
        }
        if !b.ueben.isEmpty {
            s.append("Mehr Übung braucht: \(liste(b.ueben)).")
        }
        for m in b.muster {
            s.append("Auffällig: \(n) \(m.muster.elternText) (\(m.anzahl)-mal, zum Beispiel \(m.beispiel)).")
        }
        if let tipp = b.muster.first?.muster.elternTipp {
            s.append("Tipp für zu Hause: \(tipp)")
        }
        if b.prozent >= 90, b.runden >= 3 {
            s.append("Eine starke Woche!")
        }
        return s.joined(separator: " ")
    }

    private static func liste(_ l: [String]) -> String {
        guard l.count > 1, let letzter = l.last else { return l.first ?? "" }
        return l.dropLast().joined(separator: ", ") + " und " + letzter
    }

    // MARK: KI

    static let kiAnweisung = """
    Du schreibst für Eltern einen kurzen, warmen Wochenbericht über das Lernen ihres Kindes in einer Übungs-App. \
    Schreibe 4 bis 6 ganze Sätze auf Deutsch, sachlich und ermutigend, ohne Übertreibung. \
    Nutze nur die Fakten, erfinde nichts dazu und ändere keine Zahl. Behalte den Tipp für zu Hause bei, wenn es einen gibt. \
    Kein Markdown, keine Aufzählung, keine Überschrift, keine Gedankenstriche. Schreibe nur den Text.
    """

    /// Fertige KI-Texte werden gemerkt, damit der Bericht beim zweiten Öffnen sofort da ist.
    static func gemerkterText(fuer fakten: String) -> String? {
        UserDefaults.standard.string(forKey: merkSchluessel(fakten))
    }

    static func merke(_ text: String, fuer fakten: String) {
        UserDefaults.standard.set(text, forKey: merkSchluessel(fakten))
    }

    static func merkSchluessel(_ fakten: String) -> String {
        let hash = SHA256.hash(data: Data(fakten.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
        return "berichtKI." + hash
    }
}

// MARK: - Ansicht

struct ElternBerichtView: View {
    let berichte: [KindBericht]
    @Environment(\.dismiss) private var dismiss
    @AppStorage("berichtGelesen") private var gelesen: Double = 0
    @State private var kiTexte: [String: String] = [:]
    @State private var laedt = false
    @State private var pdfURL: URL?
    @State private var zeigePDF = false

    private func anzeige(_ b: KindBericht) -> String {
        let fest = ElternBericht.text(b)
        return kiTexte[fest] ?? fest
    }

    private var gesamtText: String {
        var zeilen = ["📊 YEM1N Wochenbericht"]
        for b in berichte {
            zeilen.append("")
            zeilen.append("⭐ " + (b.name.isEmpty ? "Euer Kind" : b.name))
            zeilen.append(anzeige(b))
        }
        return zeilen.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wochenbericht")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.gelb)
                        Text("Die letzten \(ElternBericht.tage) Tage, Stand \(Date.now.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                        ForEach(berichte, id: \.name) { b in karte(b) }
                        HStack(spacing: 18) {
                            ShareLink(item: gesamtText) {
                                Label("Teilen", systemImage: "square.and.arrow.up")
                            }
                            Button {
                                pdfURL = BerichtPDF.erstellen(gesamtText)
                                zeigePDF = pdfURL != nil
                            } label: {
                                Label("Als PDF", systemImage: "doc.richtext")
                            }
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.gelb)
                        Text(KIText.verfuegbar
                             ? "Die Texte formuliert Apples KI direkt auf diesem iPhone. Es wird nichts ins Internet geschickt. Alle Zahlen und Befunde rechnet YEM1N selbst aus."
                             : "\(KIText.statusText). Der Bericht wird deshalb ohne KI geschrieben, die Zahlen sind dieselben.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSanft)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .sheet(isPresented: $zeigePDF) {
                if let url = pdfURL { ShareSheet(items: [url]) }
            }
        }
        .task { await formulieren() }
        .onAppear { gelesen = Date.now.timeIntervalSince1970 }
    }

    private func karte(_ b: KindBericht) -> some View {
        let fest = ElternBericht.text(b)
        let ki = kiTexte[fest] != nil
        return VStack(alignment: .leading, spacing: 12) {
            Text(b.name.isEmpty ? "Euer Kind" : b.name)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            if b.runden > 0 {
                HStack(spacing: 10) {
                    zahl("\(b.runden)", "Runden")
                    zahl("\(b.tage)", "Tage")
                    zahl("\(b.prozent) %", "richtig")
                }
            }
            Text(anzeige(b))
                .font(.body)
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeOut, value: ki)
            if laedt && !ki && KIText.verfuegbar && b.runden > 0 {
                HStack(spacing: 8) {
                    ProgressView().tint(Theme.gelb)
                    Text("Die KI schreibt den Bericht schöner ...")
                        .font(.caption)
                        .foregroundStyle(Theme.textSanft)
                }
            } else if ki {
                Text("✨ von der KI auf diesem Gerät formuliert")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSanft)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func zahl(_ wert: String, _ titel: String) -> some View {
        VStack(spacing: 2) {
            Text(wert)
                .font(.system(.title3, design: .rounded).weight(.black))
                .foregroundStyle(Theme.gelb)
            Text(titel)
                .font(.caption2)
                .foregroundStyle(Theme.textSanft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func formulieren() async {
        for b in berichte where b.runden > 0 {
            let fest = ElternBericht.text(b)
            if let alt = ElternBericht.gemerkterText(fuer: fest) { kiTexte[fest] = alt }
        }
        guard KIText.verfuegbar else { return }
        laedt = true
        for b in berichte where b.runden > 0 {
            let fest = ElternBericht.text(b)
            guard kiTexte[fest] == nil else { continue }
            let e = await KIText.formuliere(anweisung: ElternBericht.kiAnweisung, fakten: fest,
                                            ersatz: fest, maxZeichen: 900, wartezeit: .seconds(20))
            if e.vonKI {
                ElternBericht.merke(e.text, fuer: fest)
                withAnimation(.easeOut) { kiTexte[fest] = e.text }
            }
        }
        laedt = false
    }
}

/// Hinweis oben in der Übersicht, wenn ein neuer Bericht bereitliegt.
struct BerichtHinweis: View {
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 12) {
                Text("📊").font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Neuer Wochenbericht")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.navy)
                    Text("Tippen, um zu lesen, wie die Woche lief")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.navy.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(Theme.navy)
            }
            .padding(16)
            .background(Theme.gelb, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(TastenStil())
    }
}
