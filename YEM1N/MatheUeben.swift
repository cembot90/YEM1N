import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers
import CloudKit
import AVFoundation
import UserNotifications
import PencilKit
import CryptoKit
import Security
import WebKit
import CoreImage.CIFilterBuiltins

// MARK: - Übungsmenü einer Klassenarbeit

struct ArbeitView: View {
    let arbeit: Klassenarbeit

    private var gruppen: [String] {
        var geordnet: [String] = []
        for u in arbeit.sortierteUebungen where !geordnet.contains(u.gruppe) {
            geordnet.append(u.gruppe)
        }
        return geordnet
    }

    private func uebungen(in gruppe: String) -> [Uebung] {
        arbeit.sortierteUebungen.filter { $0.gruppe == gruppe }
    }

    private func spalten(_ anzahl: Int) -> [GridItem] {
        anzahl == 1
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    kopfkarte
                    ForEach(gruppen, id: \.self) { gruppe in
                        let liste = uebungen(in: gruppe)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(gruppe)
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.gelb)
                                .padding(.leading, 4)
                            LazyVGrid(columns: spalten(liste.count), spacing: 12) {
                                ForEach(liste) { u in
                                    NavigationLink(value: u) { UebungKachel(uebung: u) }
                                        .buttonStyle(TastenStil())
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(arbeit.titel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var kopfkarte: some View {
        HStack(spacing: 18) {
            ZStack {
                Fortschrittsring(wert: Double(arbeit.sterne) / Double(max(arbeit.maxSterne, 1)),
                                 breite: 9)
                Image(systemName: "star.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.gelb)
            }
            .frame(width: 78, height: 78)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(arbeit.klasse) · \(arbeit.fach)")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textSanft)
                Text("\(arbeit.sterne) von \(arbeit.maxSterne) Sternen")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText())
                Text("\(arbeit.fertigeUebungen) von \(arbeit.uebungen.count) Übungen geschafft")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 30)
    }
}

struct UebungKachel: View {
    let uebung: Uebung

    private var status: String {
        let n = uebung.aufgaben.count
        if uebung.laufend { return "Aufgabe \(uebung.beantwortet + 1) von \(n)" }
        if uebung.beste > 0 || uebung.istFertig { return "Bestes: \(uebung.beste) von \(n)" }
        return "Noch nicht geübt"
    }

    private var anteil: Double {
        Double(uebung.beantwortet) / Double(max(uebung.aufgaben.count, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(uebung.symbol)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Theme.navy)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 46, minHeight: 38)
                    .background(Theme.gelb, in: Capsule())
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(i < uebung.sterne ? Theme.gelb : Color.white.opacity(0.22))
                    }
                }
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
            Text(uebung.titel)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Text(status)
                .font(.caption)
                .foregroundStyle(Theme.textSanft)
            if uebung.laufend {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.14))
                        Capsule().fill(Theme.gelb).frame(width: geo.size.width * anteil)
                    }
                }
                .frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(14)
        .glasKarte(radius: 26)
    }
}

// MARK: - Punktefeld

struct PunkteFeld: View {
    let reihen: Int
    let spalten: Int

    var body: some View {
        let punkt: CGFloat = (reihen > 6 || spalten > 8) ? 12 : 16
        VStack(spacing: 5) {
            ForEach(0..<reihen, id: \.self) { _ in
                HStack(spacing: 5) {
                    ForEach(0..<spalten, id: \.self) { _ in
                        Circle()
                            .fill(Theme.gelb.gradient)
                            .frame(width: punkt, height: punkt)
                    }
                }
            }
        }
    }
}

// MARK: - Wackeln bei falscher Antwort

struct Wackeln: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 3), y: 0)
        )
    }
}

// MARK: - Zahlentastatur

struct ZahlenTastatur: View {
    @Binding var text: String
    var maxLaenge: Int = 3
    var onPruefen: () -> Void

    private let tasten = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✓"]
    private let spalten = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: spalten, spacing: 12) {
            ForEach(tasten, id: \.self) { taste in
                Button { tippen(taste) } label: {
                    inhalt(taste)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(taste == "✓" ? Theme.navy : Color.white)
                        .background(farbe(taste),
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(taste == "✓" ? 0 : 0.10), lineWidth: 1)
                        )
                }
                .buttonStyle(TastenStil())
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func inhalt(_ taste: String) -> some View {
        switch taste {
        case "⌫":
            Image(systemName: "delete.left.fill").font(.system(size: 22, weight: .bold))
        case "✓":
            Image(systemName: "checkmark").font(.system(size: 26, weight: .black))
        default:
            Text(taste).font(.system(size: 30, weight: .bold, design: .rounded))
        }
    }

    private func farbe(_ taste: String) -> Color {
        switch taste {
        case "✓": return Theme.gelb
        case "⌫": return Theme.koralle.opacity(0.30)
        default: return Color.white.opacity(0.10)
        }
    }

    private func tippen(_ taste: String) {
        switch taste {
        case "⌫": if !text.isEmpty { text.removeLast() }
        case "✓": onPruefen()
        default: if text.count < maxLaenge { text += taste }
        }
    }
}

// MARK: - Übungsansicht

enum Bewertung {
    case richtig, falsch, loesung
}

// Zeigt eine Übung und wechselt am Ende auf Wunsch direkt zur nächsten
struct UebungView: View {
    let start: Uebung
    @State private var aktuelle: Uebung?

    init(uebung: Uebung) {
        self.start = uebung
    }

    var body: some View {
        let u = aktuelle ?? start
        UebungInhalt(uebung: u, wechsel: { aktuelle = $0 })
            .id(u.persistentModelID)
    }
}

struct UebungInhalt: View {
    @Bindable var uebung: Uebung
    var wechsel: ((Uebung) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var eingabe = ""
    @State private var eingabe2 = ""
    @State private var aktivesFeld = 1
    @State private var bewertet: Aufgabe?
    @State private var bewertung: Bewertung = .richtig
    @State private var zeigeLoesungDialog = false
    @State private var zeigeJokerSheet = false
    @State private var jokerText = ""
    @State private var jokerMeldung: String? = nil
    @Environment(\.modelContext) private var context
    @AppStorage("modus") private var modus = ""
    @State private var lobWort = "Richtig."
    @State private var erklaerungText = ""
    @State private var mauerWerte: [[Int?]] = []
    @State private var mauerSchritt = 0
    @State private var kurzerHinweis: String?
    @State private var wackeln = 0
    @State private var probeStart = Date.now
    @State private var zeigeNotiz = false
    @State private var notiz = PKDrawing()
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle == "lokal" })
    private var lokaleRunden: [RundenErgebnis]
    @AppStorage("tagesziel") private var tagesziel = 2
    @State private var neuePokale: [Pokal] = []

    private var istProbe: Bool { uebung.arbeit?.spezial == "probe" }

    private func pruefePokale() {
        guard modus == "kind" else { return }
        let neu = Erfolge.neue(lokaleRunden, ziel: tagesziel)
        if !neu.isEmpty { neuePokale += neu }
    }

    // Die nächste Übung derselben Arbeit, bevorzugt eine noch nicht fertige
    private var naechsteUebung: Uebung? {
        guard let arbeit = uebung.arbeit else { return nil }
        let liste = arbeit.sortierteUebungen
        guard let i = liste.firstIndex(where: { $0.persistentModelID == uebung.persistentModelID }) else { return nil }
        let danach = Array(liste[(i + 1)...])
        return danach.first(where: { !$0.istFertig }) ?? danach.first
    }

    private var naechste: Aufgabe? { uebung.sortierteAufgaben.first { !$0.erledigt } }
    private var aktuell: Aufgabe? { bewertet ?? naechste }

    var body: some View {
        ZStack {
            HintergrundView()

            if let a = aktuell {
                ScrollView {
                    VStack(spacing: 18) {
                        kopfzeile
                        karte(a)
                            .id(a.persistentModelID)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)))
                        unten(a)
                    }
                    .padding(.vertical, 12)
                    .animation(.smooth(duration: 0.35), value: aktuell?.persistentModelID)
                }
                .scrollIndicators(.hidden)
            } else {
                ergebnis
            }
        }
        .navigationTitle(uebung.titel)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { bereiteVor() }
        .onChange(of: aktuell?.persistentModelID) { bereiteVor() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { zeigeNotiz = true } label: {
                    Image(systemName: "pencil.tip.crop.circle")
                }
            }
        }
        .sheet(isPresented: $zeigeNotiz) { notizSheet }
        .confirmationDialog("Lösung anzeigen?",
                            isPresented: $zeigeLoesungDialog,
                            titleVisibility: .visible) {
            Button("Lösung zeigen") {
                if let a = aktuell, bewertet == nil { zeigeLoesung(a) }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Die Aufgabe zählt dann nicht als richtig.")
        }
        .sheet(isPresented: $zeigeJokerSheet) {
            ShareSheet(items: [jokerText])
        }
        .alert("Joker", isPresented: Binding(get: { jokerMeldung != nil },
                                             set: { if !$0 { jokerMeldung = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(jokerMeldung ?? "")
        }
    }

    // MARK: Kopf mit Fortschritt

    private var kopfzeile: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(Array(uebung.sortierteAufgaben.enumerated()), id: \.offset) { _, t in
                    Capsule()
                        .fill(balkenFarbe(t))
                        .frame(height: 6)
                }
            }
            let nummer = min(uebung.beantwortet + (bewertet == nil ? 1 : 0), uebung.aufgaben.count)
            HStack {
                Text("Aufgabe \(nummer) von \(uebung.aufgaben.count)")
                    .contentTransition(.numericText())
                Spacer()
                if istProbe { probeUhr }
                Label("\(uebung.richtigAnzahl)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.gelb)
                    .contentTransition(.numericText())
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.textSanft)
        }
        .padding(.horizontal, 24)
    }

    private func balkenFarbe(_ t: Aufgabe) -> Color {
        if t.richtig == true { return Theme.gelb }
        if t.richtig == false { return Theme.koralle }
        if t.angesehen { return Theme.himmel }
        if t === aktuell { return Color.white }
        return Color.white.opacity(0.2)
    }

    // MARK: Aufgabenkarte

    private func karte(_ a: Aufgabe) -> some View {
        VStack(spacing: 16) {
            Text(a.frage)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)

            if a.art == "mauer" {
                mauer(a)
            } else {
                if let (x, y) = a.faktoren, a.hinweis.isEmpty, !istProbe {
                    PunkteFeld(reihen: x, spalten: y)
                }
                Text(angezeigteRechnung(a))
                    .font(grosseSchrift(a)
                          ? Font.system(size: 42, weight: .heavy, design: .rounded)
                          : Font.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)

                if !a.hinweis.isEmpty && !istProbe {
                    Text(a.hinweis)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.gelb)
                        .multilineTextAlignment(.center)
                }
                felder(a)
            }
            rueckmeldung
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 34)
        .overlay(alignment: .topTrailing) { vorlesenKnopf(a) }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func vorlesenKnopf(_ a: Aufgabe) -> some View {
        if a.art != "text" && a.art != "mauer" {
            Button {
                Sprecher.shared.sprich(sprechText(a), code: "de-DE")
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 36, height: 36)
                    .background(Theme.gelb, in: Circle())
            }
            .padding(14)
            .accessibilityLabel("Vorlesen")
        }
    }

    // Rechenzeichen werden für die Sprachausgabe in Wörter übersetzt
    private func sprechText(_ a: Aufgabe) -> String {
        var t = a.frage + ". " + a.rechnung
        let tausch: [(String, String)] = [
            ("\n", ". "), (" · ", " mal "), (" : ", " geteilt durch "),
            (" - ", " minus "), (" + ", " plus "), ("=", " gleich "),
            (" ? ", " und "), ("<", " kleiner "), (">", " größer ")
        ]
        for (alt, neu) in tausch { t = t.replacingOccurrences(of: alt, with: neu) }
        return t
    }

    private func grosseSchrift(_ a: Aufgabe) -> Bool {
        a.rechnung.count <= 14 && !a.rechnung.contains("\n")
    }

    // Bei Vergleichsaufgaben steht nach der Antwort das richtige Zeichen in der Mitte
    private func angezeigteRechnung(_ a: Aufgabe) -> String {
        if a.art == "vergleich", bewertet != nil {
            return a.rechnung.replacingOccurrences(of: "?", with: a.antwort)
        }
        return a.rechnung
    }

    private var loesungAngezeigt: Bool { bewertet != nil && bewertung == .loesung }

    private func randFarbe(aktiv: Bool) -> Color {
        if loesungAngezeigt { return Theme.himmel }
        if aktiv && bewertet == nil { return Theme.gelb }
        return Color.clear
    }

    @ViewBuilder
    private func felder(_ a: Aufgabe) -> some View {
        if a.art == "rest" {
            HStack(spacing: 14) {
                feldPaar(titel: "Ergebnis", wert: eingabe, aktiv: aktivesFeld == 1, nummer: 1)
                feldPaar(titel: "Rest", wert: eingabe2, aktiv: aktivesFeld == 2, nummer: 2)
            }
            .modifier(Wackeln(animatableData: CGFloat(wackeln)))
        } else if a.art == "text" {
            // Bei Textaufgaben wird im Eingabefeld unten geschrieben, hier erscheint die Antwort erst nach dem Prüfen
            if bewertet != nil {
                feldPaar(titel: "", wert: eingabe, aktiv: false, nummer: 1)
                    .modifier(Wackeln(animatableData: CGFloat(wackeln)))
            }
        } else if a.art != "vergleich" {
            feldPaar(titel: "", wert: eingabe, aktiv: true, nummer: 1)
                .modifier(Wackeln(animatableData: CGFloat(wackeln)))
        }
    }

    private func feldPaar(titel: String, wert: String, aktiv: Bool, nummer: Int) -> some View {
        VStack(spacing: 6) {
            Text(wert.isEmpty ? "?" : wert)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 12)
                .foregroundStyle(wert.isEmpty ? Color.white.opacity(0.35)
                                              : (loesungAngezeigt ? Theme.himmel : Color.white))
                .frame(minWidth: 104, minHeight: 62)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(randFarbe(aktiv: aktiv), lineWidth: 2.5)
                )
                .onTapGesture {
                    if bewertet == nil { aktivesFeld = nummer }
                }
            if !titel.isEmpty {
                Text(titel)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSanft)
            }
        }
    }

    // MARK: Rückmeldung

    @ViewBuilder
    private var rueckmeldung: some View {
        if bewertet != nil {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if bewertung == .loesung {
                        Image(systemName: "eye.fill")
                    }
                    Text(rueckTitel)
                }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(rueckFarbe)
                if !erklaerungText.isEmpty {
                    Text(erklaerungText)
                        .font(.subheadline)
                        .foregroundStyle(Color.white)
                }
                if bewertung == .loesung {
                    Text("Zählt nicht als richtig.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSanft)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(rueckFarbe.opacity(0.20),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else if let k = kurzerHinweis {
            Text(k)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.mint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.green.opacity(0.20),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var rueckTitel: String {
        switch bewertung {
        case .richtig: return lobWort
        case .falsch: return "Noch nicht richtig."
        case .loesung: return "Lösung angezeigt"
        }
    }

    private var rueckFarbe: Color {
        switch bewertung {
        case .richtig: return Theme.mint
        case .falsch: return Theme.koralle
        case .loesung: return Theme.himmel
        }
    }

    // MARK: Eingabebereich unten

    @ViewBuilder
    private func unten(_ a: Aufgabe) -> some View {
        if bewertet != nil {
            GelberKnopf(titel: uebung.istFertig ? "Fertig" : "Weiter") { bewertet = nil }
        } else {
            eingabeBereich(a)
            if !istProbe {
                HStack(spacing: 12) {
                    loesungKnopf
                    JokerKnopf(uebrig: JokerStand.shared.uebrigHeute) { starteJoker(a) }
                }
            }
        }
    }

    @ViewBuilder
    private func eingabeBereich(_ a: Aufgabe) -> some View {
        if a.art == "vergleich" {
            HStack(spacing: 12) {
                ForEach(["<", ">", "="], id: \.self) { z in
                    Button {
                        melde(a, ok: z == a.antwort, erklaerung: a.erklaerung)
                    } label: {
                        Text(z)
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 68)
                            .foregroundStyle(Color.white)
                            .background(Color.white.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(TastenStil())
                }
            }
            .padding(.horizontal, 24)
        } else if a.art == "text" {
            TextAntwortFeld(text: $eingabe) { pruefen(a) }
        } else {
            ZahlenTastatur(text: aktuellerText, maxLaenge: 3) { pruefen(a) }
        }
    }

    private var aktuellerText: Binding<String> {
        Binding(
            get: { aktivesFeld == 2 ? eingabe2 : eingabe },
            set: { if aktivesFeld == 2 { eingabe2 = $0 } else { eingabe = $0 } }
        )
    }

    private func starteJoker(_ a: Aufgabe) {
        guard JokerStand.shared.nutze() else {
            jokerMeldung = "Heute sind alle Joker aufgebraucht. Versuch es noch einmal oder frag im Tab Joker nach neuen Jokern."
            return
        }
        jokerText = Nachricht.jokerMathe(a)
        let kurz = Nachricht.jokerKurzMathe(a)
        let fach = a.uebung?.arbeit?.fach ?? "Mathe"
        let name = a.uebung?.titel ?? ""
        Task {
            if await JokerSender.sende(text: kurz, fach: fach, uebung: name) {
                jokerMeldung = "🃏 Joker abgeschickt! Deine Familie bekommt gleich eine Mitteilung. Die Tipps findest du im Tab Joker."
            } else {
                zeigeJokerSheet = true
            }
        }
    }

    private var loesungKnopf: some View {
        Button { zeigeLoesungDialog = true } label: {
            Label("Lösung zeigen", systemImage: "eye")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.himmel)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(Theme.himmel.opacity(0.14), in: Capsule())
        }
        .buttonStyle(TastenStil())
    }

    // MARK: Zahlenmauer

    @ViewBuilder
    private func mauer(_ a: Aufgabe) -> some View {
        let reihen = a.reihen
        let pos = mauerPosition(a)
        VStack(spacing: 5) {
            ForEach(Array(reihen.indices.reversed()), id: \.self) { i in
                HStack(spacing: 5) {
                    ForEach(reihen[i].indices, id: \.self) { j in
                        stein(reihen: reihen, i: i, j: j, pos: pos)
                    }
                }
            }
        }
    }

    private func stein(reihen: [[Int]], i: Int, j: Int, pos: (reihe: Int, spalte: Int)?) -> some View {
        var text = ""
        var hintergrund = Color.white.opacity(0.06)
        var schrift = Color.white
        var rand = Color.clear
        if i == 0 {
            text = String(reihen[i][j])
            hintergrund = Theme.gelb
            schrift = Theme.navy
        } else if mauerWerte.indices.contains(i),
                  mauerWerte[i].indices.contains(j),
                  let w = mauerWerte[i][j] {
            text = String(w)
            hintergrund = Color.white.opacity(0.18)
        } else if let p = pos, p.reihe == i, p.spalte == j, bewertet == nil {
            text = eingabe
            rand = Theme.gelb
            hintergrund = Color.white.opacity(0.10)
        }
        return Text(text)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(schrift)
            .frame(width: 58, height: 46)
            .background(hintergrund, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(rand, lineWidth: 2.5))
    }

    private func mauerPosition(_ a: Aufgabe) -> (reihe: Int, spalte: Int)? {
        let reihen = a.reihen
        guard reihen.count > 1 else { return nil }
        var n = 0
        for i in 1..<reihen.count {
            for j in 0..<reihen[i].count {
                if n == mauerSchritt { return (i, j) }
                n += 1
            }
        }
        return nil
    }

    private func mauerAnzahl(_ a: Aufgabe) -> Int {
        let reihen = a.reihen
        guard reihen.count > 1 else { return 0 }
        return reihen[1...].reduce(0) { $0 + $1.count }
    }

    // MARK: Logik

    private var probeUhr: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let rest = max(0, 30 * 60 - Int(ctx.date.timeIntervalSince(probeStart)))
            Label(String(format: "%d:%02d", rest / 60, rest % 60), systemImage: "timer")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(rest < 300 ? Theme.koralle : Theme.gelb)
        }
    }

    private var notizSheet: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                NotizblockView(zeichnung: $notiz)
            }
            .navigationTitle("Notizblock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Löschen", role: .destructive) { notiz = PKDrawing() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { zeigeNotiz = false }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
        .presentationDetents([.medium, .large])
    }

    private func bereiteVor() {
        notiz = PKDrawing()
        eingabe = ""
        eingabe2 = ""
        aktivesFeld = 1
        mauerSchritt = 0
        kurzerHinweis = nil
        if let a = aktuell, a.art == "mauer" {
            var start: [[Int?]] = []
            for (i, r) in a.reihen.enumerated() {
                if i == 0 {
                    start.append(r.map { Optional($0) })
                } else {
                    start.append(Array<Int?>(repeating: nil, count: r.count))
                }
            }
            mauerWerte = start
        } else {
            mauerWerte = []
        }
    }

    private func gleich(_ x: String, _ y: String) -> Bool {
        if let i = Int(x), let j = Int(y) { return i == j }
        return x == y
    }

    private func pruefen(_ a: Aufgabe) {
        switch a.art {
        case "mauer":
            pruefeMauer(a)
        case "rest":
            if eingabe.isEmpty || eingabe2.isEmpty {
                if !eingabe.isEmpty && eingabe2.isEmpty { aktivesFeld = 2 }
                return
            }
            melde(a, ok: gleich(eingabe, a.antwort) && gleich(eingabe2, a.antwort2),
                  erklaerung: a.erklaerung)
        case "text":
            let e = normalisiert(eingabe)
            guard !e.isEmpty else { return }
            melde(a, ok: e == normalisiert(a.antwort), erklaerung: a.erklaerung)
        default:
            guard !eingabe.isEmpty else { return }
            melde(a, ok: gleich(eingabe, a.antwort), erklaerung: a.erklaerung)
        }
    }

    // Textantworten: Leerzeichen am Rand und doppelte Leerzeichen ignorieren, Groß und Klein zählt
    private func normalisiert(_ t: String) -> String {
        t.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private func pruefeMauer(_ a: Aufgabe) {
        guard !eingabe.isEmpty, let pos = mauerPosition(a) else { return }
        let reihen = a.reihen
        let soll = reihen[pos.reihe][pos.spalte]
        let unten = reihen[pos.reihe - 1]
        if Int(eingabe) == soll {
            mauerWerte[pos.reihe][pos.spalte] = soll
            mauerSchritt += 1
            eingabe = ""
            Haptik.leicht()
            if mauerSchritt >= mauerAnzahl(a) {
                melde(a, ok: true, erklaerung: "Die Mauer stimmt komplett.")
            } else {
                kurzerHinweis = "Richtig. Weiter nach oben."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { kurzerHinweis = nil }
            }
        } else {
            mauerWerte[pos.reihe][pos.spalte] = soll
            eingabe = ""
            melde(a, ok: false,
                  erklaerung: "Hier gehört \(soll) hin: \(unten[pos.spalte]) + \(unten[pos.spalte + 1]) = \(soll)")
        }
    }

    private func melde(_ a: Aufgabe, ok: Bool, erklaerung: String) {
        a.richtig = ok
        if ok { Spezial.gemeistert(a, in: context) }
        bewertet = a
        bewertung = ok ? .richtig : .falsch
        kurzerHinweis = nil
        lobWort = ["Richtig.", "Stimmt.", "Genau so.", "Sehr gut."].randomElement() ?? "Richtig."
        if ok {
            Haptik.erfolg()
        } else {
            Haptik.fehler()
            withAnimation(.default) { wackeln += 1 }
        }
        if erklaerung.isEmpty {
            erklaerungText = a.art == "zahl"
                ? a.rechnung.replacingOccurrences(of: "\n", with: " ") + " " + a.antwort
                : (a.art == "text" ? "Richtig: \(a.antwort)" : "")
        } else {
            erklaerungText = erklaerung
        }
        if uebung.istFertig { abschliessen() }
    }

    private func zeigeLoesung(_ a: Aufgabe) {
        a.angesehen = true          // richtig bleibt bewusst leer
        bewertet = a
        bewertung = .loesung
        kurzerHinweis = nil
        Haptik.leicht()

        var zeilen: [String] = []
        switch a.art {
        case "rest":
            eingabe = a.antwort
            eingabe2 = a.antwort2
            zeilen.append("Lösung: \(a.antwort) Rest \(a.antwort2)")
        case "vergleich":
            zeilen.append("Lösung: \(a.antwort)")
        case "mauer":
            let reihen = a.reihen
            var voll = mauerWerte
            for i in reihen.indices where i > 0 && voll.indices.contains(i) {
                for j in reihen[i].indices where voll[i].indices.contains(j) {
                    voll[i][j] = reihen[i][j]
                }
            }
            mauerWerte = voll
            eingabe = ""
            zeilen.append("Die Mauer ist jetzt ausgefüllt.")
        default:
            eingabe = a.antwort
            zeilen.append("Lösung: \(a.antwort)")
        }
        if !a.erklaerung.isEmpty && a.art != "mauer" {
            zeilen.append(a.erklaerung)
        }
        erklaerungText = zeilen.joined(separator: "\n")
        if uebung.istFertig { abschliessen() }
    }

    private func abschliessen() {
        let gut = uebung.richtigAnzahl
        if gut > uebung.beste { uebung.beste = gut }
        uebung.sterne = max(uebung.sterne, uebung.sternAnzahl(fuer: gut))
        // Auf dem Kind-Gerät landet jede fertige Runde in der Warteschlange
        if modus == "kind" {
            context.insert(RundenErgebnis(
                klasse: uebung.arbeit?.klasse ?? "",
                fach: uebung.arbeit?.fach ?? "",
                arbeit: uebung.arbeit?.titel ?? "",
                uebung: uebung.titel,
                richtig: gut,
                gesamt: uebung.aufgaben.count,
                angesehen: uebung.angesehenAnzahl,
                quelle: "lokal"))
            CloudSync.anstossen(context)
        }
    }

    private func neuStarten() {
        uebung.aufgaben.forEach {
            $0.richtig = nil
            $0.angesehen = false
        }
        probeStart = Date.now
        bewertet = nil
    }

    // MARK: Ergebnis

    @ViewBuilder
    private var ergebnis: some View {
        let gut = uebung.richtigAnzahl
        let n = uebung.sternAnzahl(fuer: gut)
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < n ? "star.fill" : "star")
                            .font(.system(size: 58))
                            .foregroundStyle(i < n ? Theme.gelb : Color.white.opacity(0.25))
                            .symbolEffect(.bounce, value: n)
                    }
                }
                Text("\(gut) von \(uebung.aufgaben.count)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                if istProbe {
                    Text("Note: \(Spezial.note(gut: gut, gesamt: uebung.aufgaben.count))")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                    Text("Das ist eine Schätzung wie in der Schule.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                }
                if uebung.angesehenAnzahl > 0 {
                    Label("\(uebung.angesehenAnzahl) Lösung\(uebung.angesehenAnzahl == 1 ? "" : "en") angeschaut",
                          systemImage: "eye.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.himmel)
                }
                Text(lob(n))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSanft)
                    .multilineTextAlignment(.center)

                if !neuePokale.isEmpty {
                    VStack(spacing: 8) {
                        Text("Neues Abzeichen!")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        ForEach(neuePokale) { p in
                            HStack(spacing: 10) {
                                Text(p.emoji).font(.system(size: 38))
                                Text(p.titel)
                                    .font(.system(.title3, design: .rounded).weight(.heavy))
                                    .foregroundStyle(Color.white)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .glasKarte(radius: 26)
                    .padding(.horizontal, 24)
                    .transition(.scale.combined(with: .opacity))
                }

                if !uebung.tipp.isEmpty && gut < uebung.aufgaben.count {
                    Text("Tipp: " + uebung.tipp)
                        .font(.subheadline)
                        .foregroundStyle(Color.white)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.gelb.opacity(0.18),
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 24)
                }

                if let weiter = naechsteUebung, let wechsel {
                    GelberKnopf(titel: "Nächste Übung: \(weiter.titel)") { wechsel(weiter) }
                    Button { neuStarten() } label: {
                        Label("Nochmal üben", systemImage: "arrow.counterclockwise")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.gelb)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Theme.gelb.opacity(0.15), in: Capsule())
                            .overlay(Capsule().stroke(Theme.gelb.opacity(0.5), lineWidth: 1.5))
                    }
                    .padding(.horizontal, 24)
                } else {
                    GelberKnopf(titel: "Nochmal üben") { neuStarten() }
                }

                ShareLink(item: Nachricht.ergebnisMathe(uebung)) {
                    Label("Ergebnis an Eltern schicken", systemImage: "paperplane.fill")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.gelb.opacity(0.15), in: Capsule())
                        .overlay(Capsule().stroke(Theme.gelb.opacity(0.5), lineWidth: 1.5))
                }
                .padding(.horizontal, 24)

                Button("Zurück zur Auswahl") { dismiss() }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                    .padding(.top, 4)
            }
            .padding(.top, 50)
            .animation(.smooth, value: neuePokale.count)
        }
        .scrollIndicators(.hidden)
        .onAppear { pruefePokale() }
        .onChange(of: lokaleRunden.count) { pruefePokale() }
    }

    // Zusammenfassung für die Eltern (Stufe 0: manuell über das Teilen-Menü)
    private var ergebnisText: String {
        let gut = uebung.richtigAnzahl
        let n = uebung.sternAnzahl(fuer: gut)
        let sterne = String(repeating: "★", count: n) + String(repeating: "☆", count: 3 - n)
        var zeilen = [
            "YEM1N \(sterne)",
            "\(uebung.titel): \(gut) von \(uebung.aufgaben.count) richtig"
        ]
        if let a = uebung.arbeit {
            zeilen.append("\(a.klasse) · \(a.fach) · \(a.titel)")
        }
        if uebung.angesehenAnzahl > 0 {
            zeilen.append("Lösung angeschaut: \(uebung.angesehenAnzahl)")
        }
        let fehler = uebung.sortierteAufgaben
            .filter { $0.richtig == false }
            .prefix(3)
            .map { aufgabe -> String in
                let roh = aufgabe.rechnung.isEmpty ? aufgabe.frage : aufgabe.rechnung
                return String(roh.replacingOccurrences(of: "\n", with: " ").prefix(40))
            }
        if !fehler.isEmpty {
            zeilen.append("Noch nicht sicher: " + fehler.joined(separator: "; "))
        }
        return zeilen.joined(separator: "\n")
    }

    private func lob(_ sterne: Int) -> String {
        switch sterne {
        case 3: return "Das saß. Weiter so."
        case 2: return "Schon richtig gut."
        case 1: return "Das wird. Übe die Runde nochmal."
        default: return "Kein Problem. Gemeinsam nochmal anschauen."
        }
    }
}
