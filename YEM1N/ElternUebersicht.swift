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

// MARK: - Eltern: Übersicht und Üben

struct ElternTabs: View {
    @AppStorage("vorschulTabEltern") private var vorschul = false
    /// Das Widget springt mit "yem1n://haustier" zum Haustier.
    @State private var tab = "uebersicht"

    var body: some View {
        TabView(selection: $tab) {
            ElternDashboardView()
                .tabItem { Label("Übersicht", systemImage: "chart.bar.fill") }
                .tag("uebersicht")
            StartView()
                .tabItem { Label("Schule", systemImage: "books.vertical.fill") }
                .tag("schule")
            SprachStartView()
                .tabItem { Label("Sprachen", systemImage: "globe") }
                .tag("sprachen")
            if vorschul {
                VorschuleView()
                    .tabItem { Label("Vorschule", systemImage: "sparkles") }
                    .tag("vorschule")
            }
            ElternHaustierView()
                .tabItem { Label("Haustier", systemImage: "pawprint.fill") }
                .tag("haustier")
            JokerLigaView()
                .tabItem { Label("Joker", systemImage: "suit.spade.fill") }
                .tag("joker")
            EinstellungenView(eingebettet: true)
                .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
                .tag("einstellungen")
        }
        .onOpenURL { url in
            if url.scheme == "yem1n", url.host == "haustier" { tab = "haustier" }
        }
    }
}

struct SchwaecheEintrag: Identifiable {
    let titel: String
    let anteil: Double
    let runden: Int
    var angesehen: Int = 0
    var trend: Int = 0
    var id: String { titel }
}

struct StatKachel: View {
    let titel: String
    let wert: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.gelb)
            Text(wert)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(titel)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSanft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glasKarte(radius: 22)
    }
}

struct ElternDashboardView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("familienCode") private var familienCode = ""
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle != "lokal" },
           sort: \RundenErgebnis.zeitpunkt, order: .reverse)
    private var alleErgebnisse: [RundenErgebnis]
    @State private var kindFilter = ""
    @State private var zeigeEinstellungen = false
    @State private var radarTage = 7
    @State private var pdfURL: URL?
    @State private var zeigePDF = false

    @State private var kindZuEntfernen: KindEintrag?

    private var ergebnisse: [RundenErgebnis] {
        kindFilter.isEmpty ? alleErgebnisse : alleErgebnisse.filter { Kinder.gleich($0.kind, kindFilter) }
    }

    private var kinderListe: [KindEintrag] {
        Kinder.liste(aus: alleErgebnisse.map { (name: $0.kind, zeitpunkt: $0.zeitpunkt) })
    }

    private var kinder: [String] { kinderListe.map { $0.name } }

    private func entferne(_ kind: KindEintrag) {
        Kinder.entfernen(kind.name)
        for e in alleErgebnisse where Kinder.gleich(e.kind, kind.name) {
            context.delete(e)
        }
        try? context.save()
        if Kinder.gleich(kindFilter, kind.name) { kindFilter = "" }
    }

    private var kinderKarte: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kinder in der Familie")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            ForEach(kinderListe) { kind in
                let alt = Kinder.tageSeit(kind.zuletzt) >= Kinder.langeInaktivTage
                HStack(spacing: 12) {
                    Image(systemName: alt ? "moon.zzz.fill" : "person.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(alt ? Theme.textSanft : Theme.navy)
                        .frame(width: 38, height: 38)
                        .background(alt ? Color.white.opacity(0.12) : Theme.gelb, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kind.name)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.white)
                        Text("\(kind.runden) \(kind.runden == 1 ? "Runde" : "Runden"), zuletzt \(Kinder.zuletztText(kind.zuletzt))")
                            .font(.caption)
                            .foregroundStyle(alt ? Theme.koralle : Theme.textSanft)
                    }
                    Spacer()
                    Button { kindZuEntfernen = kind } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.koralle)
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel("\(kind.name) entfernen")
                }
            }
            Text("Hier stehen alle Kinder, von denen Ergebnisse angekommen sind. Entfernen löscht nur die Einträge auf diesem Gerät. Spielt das Kind später weiter, erscheint es wieder.")
                .font(.caption)
                .foregroundStyle(Theme.textSanft)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var kindWahl: some View {
        Picker("Kind", selection: $kindFilter) {
            Text("Alle").tag("")
            ForEach(kinder, id: \.self) { name in
                Text(name).tag(name)
            }
        }
        .pickerStyle(.segmented)
    }

    private var berichtText: String {
        let kal = Calendar.current
        let grenze = kal.date(byAdding: .day, value: -6, to: kal.startOfDay(for: Date.now)) ?? Date.distantPast
        let diese = alleErgebnisse.filter { $0.zeitpunkt >= grenze }
        let namen: [String] = kinder.isEmpty ? [""] : kinder
        var zeilen: [String] = ["📊 YEM1N Wochenbericht"]
        for name in namen {
            let l = diese.filter { name.isEmpty || Kinder.gleich($0.kind, name) }
            let titel = name.isEmpty ? "Diese Woche" : name
            if l.isEmpty {
                zeilen.append("")
                zeilen.append("\(titel): keine Runden")
                continue
            }
            let r = l.reduce(0) { $0 + $1.richtig }
            let g = l.reduce(0) { $0 + $1.gesamt }
            let st = l.reduce(0) { $0 + $1.sterne }
            var tage = Set<Date>()
            for e in l { tage.insert(kal.startOfDay(for: e.zeitpunkt)) }
            let prozent = g > 0 ? Int((Double(r) / Double(g) * 100).rounded()) : 0
            zeilen.append("")
            zeilen.append("⭐ \(titel)")
            zeilen.append("Runden: \(l.count) an \(tage.count) Tagen")
            zeilen.append("Richtig: \(r) von \(g) (\(prozent) %)")
            zeilen.append("Sterne: \(st)")
            let gruppiert = Dictionary(grouping: l, by: { $0.uebung })
            var bereiche: [(String, Double)] = []
            for (u, liste) in gruppiert {
                let rr = liste.reduce(0) { $0 + $1.richtig }
                let gg = liste.reduce(0) { $0 + $1.gesamt }
                if gg > 0 { bereiche.append((u, Double(rr) / Double(gg))) }
            }
            bereiche.sort { $0.1 > $1.1 }
            if let stark = bereiche.first { zeilen.append("💪 Stark: \(stark.0)") }
            if bereiche.count > 1, let schwach = bereiche.last { zeilen.append("🎯 Üben: \(schwach.0)") }
        }
        return zeilen.joined(separator: "\n")
    }

    private var wochenberichtKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wochenbericht")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text(berichtText)
                .font(.footnote)
                .foregroundStyle(Color.white)
            ShareLink(item: berichtText) {
                Label("Bericht teilen", systemImage: "square.and.arrow.up")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
            }
            Button {
                pdfURL = BerichtPDF.erstellen(berichtText)
                zeigePDF = pdfURL != nil
            } label: {
                Label("Als PDF teilen", systemImage: "doc.richtext")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
            }
            .sheet(isPresented: $zeigePDF) {
                if let url = pdfURL { ShareSheet(items: [url]) }
            }
            Text("Jeden Sonntag um 18 Uhr erinnert dich eine Mitteilung daran.")
                .font(.caption)
                .foregroundStyle(Theme.textSanft)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var heute: [RundenErgebnis] {
        ergebnisse.filter { Calendar.current.isDateInToday($0.zeitpunkt) }
    }

    private var woche: [RundenErgebnis] {
        let kal = Calendar.current
        let grenze = kal.date(byAdding: .day, value: -6, to: kal.startOfDay(for: Date.now)) ?? Date.distantPast
        return ergebnisse.filter { $0.zeitpunkt >= grenze }
    }

    private var radarBasis: [RundenErgebnis] {
        if radarTage == 0 { return ergebnisse }
        let kal = Calendar.current
        let grenze = kal.date(byAdding: .day, value: -(radarTage - 1), to: kal.startOfDay(for: Date.now)) ?? Date.distantPast
        return ergebnisse.filter { $0.zeitpunkt >= grenze }
    }

    private var schwaechste: [SchwaecheEintrag] {
        let gruppiert = Dictionary(grouping: radarBasis, by: \.uebung)
        let alle = gruppiert.map { titel, liste -> SchwaecheEintrag in
            let r = liste.reduce(0) { $0 + $1.richtig }
            let g = liste.reduce(0) { $0 + $1.gesamt }
            let angesehen = liste.reduce(0) { $0 + $1.angesehen }
            let sortiert = liste.sorted { $0.zeitpunkt < $1.zeitpunkt }
            var trend = 0
            if sortiert.count >= 2, let letzte = sortiert.last, letzte.gesamt > 0 {
                let frueher = Array(sortiert.dropLast())
                let fr = frueher.reduce(0) { $0 + $1.richtig }
                let fg = frueher.reduce(0) { $0 + $1.gesamt }
                if fg > 0 {
                    let alt = Double(fr) / Double(fg)
                    let neu = Double(letzte.richtig) / Double(letzte.gesamt)
                    trend = neu > alt + 0.05 ? 1 : (neu < alt - 0.05 ? -1 : 0)
                }
            }
            return SchwaecheEintrag(titel: titel,
                                    anteil: g > 0 ? Double(r) / Double(g) : 0,
                                    runden: liste.count,
                                    angesehen: angesehen,
                                    trend: trend)
        }
        let schwach = alle.filter { $0.anteil < 0.95 || $0.angesehen > 0 }
        return Array(schwach.sorted { $0.anteil < $1.anteil }.prefix(5))
    }

    private func radarZeile(_ e: SchwaecheEintrag) -> String {
        var t = "\(e.runden) \(e.runden == 1 ? "Runde" : "Runden")"
        if e.angesehen > 0 { t += ", \(e.angesehen) Lösungen angeschaut" }
        if e.trend > 0 { t += ", wird besser" }
        if e.trend < 0 { t += ", zuletzt schlechter" }
        return t
    }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    kopf
                    if kinder.count > 1 { kindWahl }
                    if ergebnisse.isEmpty {
                        leer
                    } else {
                        kacheln
                        wochenbalken
                        abzeichenKarte
                        wochenberichtKarte
                        schwaecheKarte
                        letzteRunden
                    }
                    if !kinderListe.isEmpty { kinderKarte }
                    demoKnoepfe
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .refreshable { await CloudSync.aktiv(context, erzwingen: true) }
        }
        .task { await CloudSync.aktiv(context) }
        .task { await Wochenbericht.planen() }
        .sheet(isPresented: $zeigeEinstellungen) { EinstellungenView() }
        .confirmationDialog(
            "Kind entfernen?",
            isPresented: Binding(get: { kindZuEntfernen != nil },
                                 set: { if !$0 { kindZuEntfernen = nil } }),
            titleVisibility: .visible,
            presenting: kindZuEntfernen
        ) { kind in
            Button("\(kind.name) entfernen", role: .destructive) { entferne(kind) }
            Button("Abbrechen", role: .cancel) {}
        } message: { kind in
            Text("Die \(kind.runden) Runden von \(kind.name) verschwinden von diesem Gerät. Beim Kind selbst bleibt alles erhalten.")
        }
    }

    // MARK: Teile

    private var kopf: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("YEM1N Eltern")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                Text(familienCode.isEmpty ? "Noch kein Familiencode" : "Familiencode: \(familienCode)")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            Button { zeigeEinstellungen = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 44, height: 44)
                    .background(Theme.gelb, in: Circle())
            }
        }
    }

    private var leer: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gelb)
            Text("Noch keine Ergebnisse")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
            Text("Sobald dein Kind eine Runde beendet, erscheint sie hier und du bekommst eine Mitteilung. Zum Ausprobieren kannst du Beispieldaten laden.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 28)
    }

    private var kacheln: some View {
        let r = heute.reduce(0) { $0 + $1.richtig }
        let g = heute.reduce(0) { $0 + $1.gesamt }
        let s = heute.reduce(0) { $0 + $1.sterne }
        return HStack(spacing: 12) {
            StatKachel(titel: "Runden heute", wert: "\(heute.count)", symbol: "flag.checkered")
            StatKachel(titel: "Richtig", wert: g > 0 ? "\(r)/\(g)" : "-", symbol: "checkmark.circle.fill")
            StatKachel(titel: "Sterne", wert: "\(s)", symbol: "star.fill")
        }
    }

    private var wochenbalken: some View {
        let kal = Calendar.current
        let start = kal.startOfDay(for: Date.now)
        let tage = (0..<7).reversed().map { kal.date(byAdding: .day, value: -$0, to: start) ?? start }
        let zahlen = tage.map { tag in
            ergebnisse.filter { kal.isDate($0.zeitpunkt, inSameDayAs: tag) }.count
        }
        let maximum = max(zahlen.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Letzte 7 Tage")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(tage.enumerated()), id: \.offset) { i, tag in
                    VStack(spacing: 6) {
                        Text("\(zahlen[i])")
                            .font(.caption2.bold())
                            .foregroundStyle(zahlen[i] > 0 ? Theme.gelb : Theme.textSanft)
                        Capsule()
                            .fill(zahlen[i] > 0 ? Theme.gelb : Color.white.opacity(0.14))
                            .frame(height: 8 + 56 * CGFloat(zahlen[i]) / CGFloat(maximum))
                        Text(tag.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption2)
                            .foregroundStyle(Theme.textSanft)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110, alignment: .bottom)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func schwaecheFarbe(_ anteil: Double) -> Color {
        if anteil < 0.6 { return Theme.koralle }
        if anteil < 0.8 { return Theme.gelb }
        return Theme.mint
    }

    private var abzeichenKarte: some View {
        let liste = Erfolge.pokale(ergebnisse, ziel: 2)
        let geschafft = liste.filter { $0.erreicht }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Abzeichen: \(geschafft.count) von \(liste.count)")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            if geschafft.isEmpty {
                Text("Noch keine Abzeichen. Das erste gibt es nach der ersten Runde.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSanft)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 46), spacing: 8)], spacing: 8) {
                    ForEach(geschafft) { p in
                        Text(p.emoji)
                            .font(.system(size: 30))
                            .frame(width: 46, height: 46)
                            .background(Color.white.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var schwaecheKarte: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Schwächen-Radar")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Picker("Zeitraum", selection: $radarTage) {
                Text("7 Tage").tag(7)
                Text("30 Tage").tag(30)
                Text("Alles").tag(0)
            }
            .pickerStyle(.segmented)
            if schwaechste.isEmpty {
                Text(radarBasis.isEmpty ? "Noch keine Daten in diesem Zeitraum." : "Keine Schwächen gefunden. Alles sitzt.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSanft)
            } else {
                ForEach(schwaechste) { eintrag in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(eintrag.titel)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.white)
                            Spacer()
                            Text("\(Int((eintrag.anteil * 100).rounded())) %")
                                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                                .foregroundStyle(schwaecheFarbe(eintrag.anteil))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.14))
                                Capsule()
                                    .fill(schwaecheFarbe(eintrag.anteil))
                                    .frame(width: geo.size.width * eintrag.anteil)
                            }
                        }
                        .frame(height: 7)
                        Text(radarZeile(eintrag))
                            .font(.caption)
                            .foregroundStyle(Theme.textSanft)
                    }
                }
                if let erste = schwaechste.first {
                    Text("Tipp: Übt als Nächstes \(erste.titel). Das Training im Tab Schule wählt die schwächsten Übungen automatisch.")
                        .font(.footnote)
                        .foregroundStyle(Color.white)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var letzteRunden: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Letzte Runden")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            ForEach(Array(ergebnisse.prefix(8)), id: \.eintragID) { e in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(e.uebung)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.white)
                        Text((e.kind.isEmpty ? "" : e.kind + " · ") + "\(e.arbeit) · " + e.zeitpunkt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(Theme.textSanft)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(e.richtig) von \(e.gesamt)")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(i < e.sterne ? Theme.gelb : Color.white.opacity(0.22))
                            }
                            if e.angesehen > 0 {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.himmel)
                                Text("\(e.angesehen)")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.himmel)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    @ViewBuilder
    private var demoKnoepfe: some View {
        if ergebnisse.contains(where: { $0.quelle == "demo" }) {
            Button("Beispieldaten löschen") { Beispieldaten.loeschen(in: context) }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.himmel)
        } else if ergebnisse.isEmpty {
            Button("Beispieldaten laden") { Beispieldaten.laden(in: context) }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.himmel)
        }
    }
}
