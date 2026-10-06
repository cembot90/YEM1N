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

// ============================================================
// MARK: - Vorschule (Zählen, Zuordnen, Muster, Memory für die Kleinen)
// ============================================================

enum VorschulArt: String, CaseIterable, Identifiable, Hashable {
    case mix, zaehlen, zahlen, plus, mehr, nachbar, formen, anlaut, anders, muster, memory

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .mix: return "Alles gemischt"
        case .zaehlen: return "Zählen"
        case .zahlen: return "Zahlen"
        case .plus: return "Plus"
        case .mehr: return "Mehr oder weniger"
        case .nachbar: return "Davor und danach"
        case .formen: return "Formen und Farben"
        case .anlaut: return "Anfangsbuchstaben"
        case .anders: return "Was passt nicht?"
        case .muster: return "Muster"
        case .memory: return "Memory"
        }
    }

    var emoji: String {
        switch self {
        case .mix: return "🎲"
        case .zaehlen: return "🍎"
        case .zahlen: return "🔢"
        case .plus: return "➕"
        case .mehr: return "⚖️"
        case .nachbar: return "↔️"
        case .formen: return "🎨"
        case .anlaut: return "🔤"
        case .anders: return "🧐"
        case .muster: return "🧩"
        case .memory: return "🃏"
        }
    }
}

struct VorschulText {
    let de: String
    let tr: String?
}

struct VorschulFrage: Identifiable {
    let id = UUID()
    var text: VorschulText
    var zeige: [String] = []
    var zeigeZwei: [String] = []
    var plus = false
    var gross = ""
    var folge: [String] = []
    var optionen: [String]
    var richtig: Int
    var gruppenOptionen = false

    var schluessel: String {
        text.de + "|" + zeige.joined() + "|" + zeigeZwei.joined() + "|" + gross + "|"
            + folge.joined() + "|" + optionen.joined(separator: ",")
    }
}

enum VorschulGenerator {
    static let dinge = ["🍎", "⭐", "🐶", "🎈", "🚗", "🐟", "🌸", "🍪", "🐱", "🍓"]

    static let formen: [(frageDe: String, frageTr: String, emoji: String)] = [
        ("Wo ist der Kreis?", "Daire hangisi?", "🔵"),
        ("Wo ist das Quadrat?", "Kare hangisi?", "🟩"),
        ("Wo ist das Dreieck?", "Üçgen hangisi?", "🔺"),
        ("Wo ist der Stern?", "Yıldız hangisi?", "⭐"),
        ("Wo ist das Herz?", "Kalp hangisi?", "💜")
    ]

    static let farben: [(frageDe: String, frageTr: String, emoji: String)] = [
        ("Tippe auf Rot.", "Kırmızı olanı bul.", "🔴"),
        ("Tippe auf Blau.", "Mavi olanı bul.", "🔵"),
        ("Tippe auf Gelb.", "Sarı olanı bul.", "🟡"),
        ("Tippe auf Grün.", "Yeşil olanı bul.", "🟢"),
        ("Tippe auf Lila.", "Mor olanı bul.", "🟣"),
        ("Tippe auf Orange.", "Turuncu olanı bul.", "🟠")
    ]

    static let anlaute: [(emoji: String, wort: String, buchstabe: String)] = [
        ("🍎", "Apfel", "A"), ("🚗", "Auto", "A"), ("🐻", "Bär", "B"), ("🍌", "Banane", "B"),
        ("🎈", "Ballon", "B"), ("🪁", "Drachen", "D"), ("🐘", "Elefant", "E"), ("🦆", "Ente", "E"),
        ("🐟", "Fisch", "F"), ("🐸", "Frosch", "F"), ("🐶", "Hund", "H"), ("🏠", "Haus", "H"),
        ("🦔", "Igel", "I"), ("🐱", "Katze", "K"), ("🐄", "Kuh", "K"), ("🦁", "Löwe", "L"),
        ("🐭", "Maus", "M"), ("🌙", "Mond", "M"), ("👃", "Nase", "N"), ("🍊", "Orange", "O"),
        ("🐴", "Pferd", "P"), ("🐧", "Pinguin", "P"), ("🌹", "Rose", "R"), ("🌈", "Regenbogen", "R"),
        ("🌞", "Sonne", "S"), ("🧦", "Socke", "S"), ("🐯", "Tiger", "T"), ("🍅", "Tomate", "T"),
        ("⏰", "Uhr", "U"), ("🐳", "Wal", "W"), ("☁️", "Wolke", "W"), ("🦓", "Zebra", "Z"),
        ("🚂", "Zug", "Z")
    ]

    static let gruppen: [[String]] = [
        ["🐶", "🐱", "🐭", "🐰", "🐻", "🦁"],
        ["🍎", "🍌", "🍓", "🍇", "🍊", "🍐"],
        ["🚗", "🚌", "🚲", "✈️", "🚂", "🚢"],
        ["🌹", "🌻", "🌷", "🌼"],
        ["⚽", "🏀", "🎾", "🏐"]
    ]

    static func grenze(_ stufe: Int) -> Int { stufe == 1 ? 5 : (stufe == 2 ? 10 : 20) }

    // Drei verschiedene Zahlen, eine davon ist richtig
    static func zahlenOptionen(richtig: Int, von: Int, bis: Int) -> (optionen: [String], index: Int) {
        var menge: Set<Int> = [richtig]
        var versuche = 0
        while menge.count < 3 && versuche < 200 {
            versuche += 1
            let abstand = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
            let z = richtig + abstand
            if z >= von && z <= bis { menge.insert(z) }
        }
        if menge.count < 3 {
            for z in von...bis where menge.count < 3 { menge.insert(z) }
        }
        let liste = Array(menge).shuffled()
        let idx = liste.firstIndex(of: richtig) ?? 0
        return (liste.map { String($0) }, idx)
    }

    // Emoji-Gruppe als Text, nach fünf Stück ein Zeilenumbruch
    static func gruppe(_ n: Int, _ emoji: String) -> String {
        var teile: [String] = []
        for i in 0..<n {
            teile.append(emoji)
            if (i + 1) % 5 == 0 && i + 1 < n { teile.append("\n") }
        }
        return teile.joined()
    }

    static func fragen(_ art: VorschulArt, stufe: Int, anzahl: Int = 8) -> [VorschulFrage] {
        let arten = VorschulArt.allCases.filter { $0 != .mix && $0 != .memory }
        var liste: [VorschulFrage] = []
        var gesehen = Set<String>()
        for _ in 0..<anzahl {
            var f = eine(art == .mix ? (arten.randomElement() ?? .zaehlen) : art, stufe: stufe)
            var versuche = 0
            while gesehen.contains(f.schluessel) && versuche < 10 {
                versuche += 1
                f = eine(art == .mix ? (arten.randomElement() ?? .zaehlen) : art, stufe: stufe)
            }
            gesehen.insert(f.schluessel)
            liste.append(f)
        }
        return liste
    }

    static func eine(_ art: VorschulArt, stufe: Int) -> VorschulFrage {
        switch art {
        case .zaehlen:
            let m = stufe == 1 ? 5 : 10
            let n = Int.random(in: 1...m)
            let e = dinge.randomElement() ?? "⭐"
            let o = zahlenOptionen(richtig: n, von: 1, bis: m)
            return VorschulFrage(text: VorschulText(de: "Wie viele siehst du?", tr: "Kaç tane görüyorsun?"),
                                 zeige: Array(repeating: e, count: n),
                                 optionen: o.optionen, richtig: o.index)

        case .zahlen:
            let m = grenze(stufe)
            let n = Int.random(in: 1...m)
            let o = zahlenOptionen(richtig: n, von: 1, bis: m)
            return VorschulFrage(text: VorschulText(de: "Tippe auf die \(n).", tr: "\(n) sayısına dokun."),
                                 optionen: o.optionen, richtig: o.index)

        case .plus:
            let m = grenze(stufe)
            var x = 1
            var y = 1
            if stufe == 3 {
                x = Int.random(in: 2...10)
                y = Int.random(in: 1...min(10, m - x))
            } else {
                x = Int.random(in: 1...(m - 1))
                y = Int.random(in: 1...(m - x))
            }
            let paar = dinge.shuffled()
            let o = zahlenOptionen(richtig: x + y, von: 1, bis: m)
            return VorschulFrage(text: VorschulText(de: "\(x) plus \(y). Wie viel ist das?", tr: "\(x) artı \(y) kaç eder?"),
                                 zeige: Array(repeating: paar[0], count: x),
                                 zeigeZwei: Array(repeating: paar[1], count: y),
                                 plus: true,
                                 optionen: o.optionen, richtig: o.index)

        case .mehr:
            let m = stufe == 1 ? 5 : 10
            let x = Int.random(in: 1...m)
            var y = Int.random(in: 1...m)
            while y == x { y = Int.random(in: 1...m) }
            let e = dinge.randomElement() ?? "🍎"
            let fragtMehr = Int.random(in: 0..<10) < 7
            let tausch = Bool.random()
            let a = tausch ? y : x
            let b = tausch ? x : y
            let idx: Int
            if fragtMehr { idx = a > b ? 0 : 1 } else { idx = a < b ? 0 : 1 }
            let text = fragtMehr
                ? VorschulText(de: "Wo sind mehr?", tr: "Hangisi daha fazla?")
                : VorschulText(de: "Wo sind weniger?", tr: "Hangisi daha az?")
            return VorschulFrage(text: text,
                                 optionen: [gruppe(a, e), gruppe(b, e)], richtig: idx,
                                 gruppenOptionen: true)

        case .nachbar:
            let m = grenze(stufe)
            let danach = Bool.random()
            let n = danach ? Int.random(in: 1...(m - 1)) : Int.random(in: 2...m)
            let ziel = danach ? n + 1 : n - 1
            let o = zahlenOptionen(richtig: ziel, von: 0, bis: m)
            let text = danach
                ? VorschulText(de: "Welche Zahl kommt nach der \(n)?", tr: "\(n) sayısından sonra hangi sayı gelir?")
                : VorschulText(de: "Welche Zahl kommt vor der \(n)?", tr: "\(n) sayısından önce hangi sayı gelir?")
            return VorschulFrage(text: text, gross: String(n), optionen: o.optionen, richtig: o.index)

        case .formen:
            let quelle = Bool.random() ? formen : farben
            let drei = Array(quelle.shuffled().prefix(3))
            let r = Int.random(in: 0..<3)
            return VorschulFrage(text: VorschulText(de: drei[r].frageDe, tr: drei[r].frageTr),
                                 optionen: drei.map { $0.emoji }, richtig: r)

        case .anlaut:
            let item = anlaute.randomElement() ?? anlaute[0]
            var buchstaben = Array(Set(anlaute.map { $0.buchstabe })).filter { $0 != item.buchstabe }
            buchstaben.shuffle()
            var optionen = Array(buchstaben.prefix(2)) + [item.buchstabe]
            optionen.shuffle()
            return VorschulFrage(text: VorschulText(de: "Womit fängt \(item.wort) an?", tr: nil),
                                 gross: item.emoji,
                                 optionen: optionen, richtig: optionen.firstIndex(of: item.buchstabe) ?? 0)

        case .anders:
            let g = gruppen.shuffled()
            let eigene = Array(g[0].shuffled().prefix(3))
            let fremd = g[1].randomElement() ?? "🍎"
            var optionen = eigene + [fremd]
            optionen.shuffle()
            return VorschulFrage(text: VorschulText(de: "Was passt nicht dazu?", tr: "Hangisi diğerlerine uymuyor?"),
                                 optionen: optionen, richtig: optionen.firstIndex(of: fremd) ?? 0)

        default:
            let p = ["🔴", "🔵", "🟡", "🟢", "🟣", "🟠", "⭐", "❤️", "🍎", "🐟"].shuffled()
            let a = p[0]
            let b = p[1]
            let c = p[2]
            let muster: [String]
            switch stufe {
            case 1: muster = [a, b]
            case 2: muster = Bool.random() ? [a, a, b] : [a, b, b]
            default: muster = [a, b, c]
            }
            let l = muster.count
            let anzahl = Int.random(in: (l + 1)...(2 * l + 1))
            let folge = (0..<anzahl).map { muster[$0 % l] }
            let richtig = muster[anzahl % l]
            var optionen = [richtig]
            for e in p where optionen.count < 3 && e != richtig { optionen.append(e) }
            optionen.shuffle()
            return VorschulFrage(text: VorschulText(de: "Wie geht es weiter?", tr: "Sıradaki hangisi?"),
                                 folge: folge,
                                 optionen: optionen, richtig: optionen.firstIndex(of: richtig) ?? 0)
        }
    }
}

enum VorschulTon {
    static func sag(_ t: VorschulText) {
        let sprache = UserDefaults.standard.string(forKey: "vorschulSprache") ?? "de"
        if sprache == "tr", let tr = t.tr {
            Sprecher.shared.sprich(tr, code: "tr-TR")
        } else {
            Sprecher.shared.sprich(t.de, code: "de-DE")
        }
    }

    static func lob() {
        let lob: [VorschulText] = [
            VorschulText(de: "Super!", tr: "Harika!"),
            VorschulText(de: "Toll gemacht!", tr: "Aferin!"),
            VorschulText(de: "Richtig!", tr: "Doğru!"),
            VorschulText(de: "Prima!", tr: "Bravo!")
        ]
        sag(lob.randomElement() ?? lob[0])
    }

    static func nochmal() {
        sag(VorschulText(de: "Probier es noch einmal.", tr: "Bir daha dene."))
    }
}

struct EmojiReihen: View {
    let emojis: [String]
    var groesse: CGFloat = 38

    var body: some View {
        let reihen = stride(from: 0, to: emojis.count, by: 5).map {
            Array(emojis[$0..<min($0 + 5, emojis.count)])
        }
        VStack(spacing: 6) {
            ForEach(Array(reihen.enumerated()), id: \.offset) { _, reihe in
                HStack(spacing: 6) {
                    ForEach(Array(reihe.enumerated()), id: \.offset) { _, e in
                        Text(e).font(.system(size: groesse))
                    }
                }
            }
        }
    }
}

enum VorschulPaket {
    // Aufgaben aus einem importierten Vorschul-Paket in Fragen für die Runde umwandeln
    static func fragen(_ u: Uebung) -> [VorschulFrage] {
        var liste: [VorschulFrage] = []
        for a in u.sortierteAufgaben where a.art == "wahl" {
            guard let d = a.reihenJSON.data(using: .utf8),
                  let opt = try? JSONDecoder().decode([String].self, from: d),
                  opt.count >= 2, opt.contains(a.antwort) else { continue }
            let gemischt = opt.shuffled()
            guard let richtig = gemischt.firstIndex(of: a.antwort) else { continue }
            var f = VorschulFrage(text: VorschulText(de: a.frage, tr: a.hinweis.isEmpty ? nil : a.hinweis),
                                  optionen: gemischt, richtig: richtig)
            f.gross = a.erklaerung
            f.folge = a.antwort2.split(separator: " ").map(String.init)
            let teile = a.rechnung.components(separatedBy: "+")
            func zeichen(_ t: String) -> [String] {
                t.filter { !$0.isWhitespace }.map { String($0) }
            }
            if teile.count == 2 {
                f.plus = true
                f.zeige = zeichen(teile[0])
                f.zeigeZwei = zeichen(teile[1])
            } else {
                f.zeige = zeichen(a.rechnung)
            }
            f.gruppenOptionen = opt.contains { $0.count > 2 }
            liste.append(f)
        }
        return liste.shuffled()
    }
}

struct VorschulPaketListe: View {
    let arbeit: Klassenarbeit

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(arbeit.sortierteUebungen) { u in
                        NavigationLink(value: u) {
                            HStack(spacing: 14) {
                                Text(u.symbol).font(.system(size: 40))
                                Text(u.titel)
                                    .font(.system(.title3, design: .rounded).weight(.heavy))
                                    .foregroundStyle(Color.white)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.gelb)
                            }
                            .padding(16)
                            .glasKarte(radius: 24)
                        }
                        .buttonStyle(TastenStil())
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(arbeit.titel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VorschuleView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Klassenarbeit.erstellt) private var alleArbeiten: [Klassenarbeit]
    @State private var loeschen: Klassenarbeit?
    @AppStorage("vorschulStufe") private var stufe = 2
    @AppStorage("vorschulSprache") private var sprache = "de"
    @AppStorage("kindName") private var kindName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kopf
                        auswahl
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                            ForEach(VorschulArt.allCases) { art in
                                NavigationLink(value: art) { karte(art) }
                                    .buttonStyle(TastenStil())
                            }
                        }
                        pakete
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: VorschulArt.self) { art in
                if art == .memory {
                    VorschulMemory()
                } else {
                    VorschulRunde(art: art)
                }
            }
            .navigationDestination(for: Klassenarbeit.self) { VorschulPaketListe(arbeit: $0) }
            .navigationDestination(for: Uebung.self) { VorschulRunde(art: .mix, quelle: $0) }
            .confirmationDialog("Paket löschen?", isPresented: Binding(get: { loeschen != nil },
                                                                     set: { if !$0 { loeschen = nil } }),
                                titleVisibility: .visible) {
                Button("Ja, löschen", role: .destructive) {
                    if let a = loeschen { context.delete(a); try? context.save() }
                    loeschen = nil
                }
                Button("Nein, behalten", role: .cancel) { loeschen = nil }
            }
        }
    }

    private var eigenePakete: [Klassenarbeit] {
        alleArbeiten.filter { $0.fach == "Vorschule" && $0.spezial.isEmpty }
    }

    @ViewBuilder
    private var pakete: some View {
        if !eigenePakete.isEmpty {
            Text("Eigene Pakete")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
                .padding(.top, 8)
            ForEach(eigenePakete) { a in
                NavigationLink(value: a) {
                    HStack(spacing: 14) {
                        Text("📦").font(.system(size: 36))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.titel)
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Color.white)
                            Text("\(a.uebungen.count) Übungen")
                                .font(.footnote)
                                .foregroundStyle(Theme.textSanft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.gelb)
                    }
                    .padding(16)
                    .glasKarte(radius: 24)
                }
                .buttonStyle(TastenStil())
                .contextMenu {
                    Button("Paket löschen", systemImage: "trash", role: .destructive) { loeschen = a }
                }
            }
        }
    }

    private var kopf: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Vorschule")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gelb)
            Text(kindName.isEmpty ? "Spielen und lernen" : "Hallo \(kindName)! Spielen und lernen")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSanft)
        }
    }

    private var auswahl: some View {
        VStack(spacing: 10) {
            Picker("Zahlenraum", selection: $stufe) {
                Text("Bis 5").tag(1)
                Text("Bis 10").tag(2)
                Text("Bis 20").tag(3)
            }
            .pickerStyle(.segmented)
            Picker("Sprache", selection: $sprache) {
                Text("Deutsch").tag("de")
                Text("Türkçe").tag("tr")
            }
            .pickerStyle(.segmented)
        }
    }

    private func karte(_ art: VorschulArt) -> some View {
        VStack(spacing: 8) {
            Text(art.emoji).font(.system(size: 52))
            Text(art.titel)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(8)
        .glasKarte(radius: 26)
    }
}

struct VorschulRunde: View {
    let art: VorschulArt
    var quelle: Uebung? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("modus") private var modus = ""
    @AppStorage("vorschulStufe") private var stufe = 2
    @AppStorage("vorschulSprache") private var sprache = "de"
    @State private var fragen: [VorschulFrage] = []
    @State private var nr = 0
    @State private var perfekt = 0
    @State private var falsch: Set<Int> = []
    @State private var richtigGewaehlt: Int?
    @State private var schuettel: Int?
    @State private var sperre = false
    @State private var gespeichert = false

    var body: some View {
        ZStack {
            HintergrundView()
            if fragen.isEmpty {
                ProgressView()
            } else if nr >= fragen.count {
                ergebnis
            } else {
                frage(fragen[nr])
            }
        }
        .navigationTitle(quelle?.titel ?? art.titel)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if fragen.isEmpty { neu() } }
    }

    private func frage(_ f: VorschulFrage) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                ProgressView(value: Double(nr), total: Double(fragen.count))
                    .tint(Theme.gelb)

                Button { VorschulTon.sag(f.text) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(Theme.gelb)
                        Text(sprache == "tr" ? (f.text.tr ?? f.text.de) : f.text.de)
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .glasKarte(radius: 22)
                }
                .buttonStyle(TastenStil())

                bild(f)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 14)], spacing: 14) {
                    ForEach(Array(f.optionen.enumerated()), id: \.offset) { i, o in
                        optionKnopf(i, o, f)
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func bild(_ f: VorschulFrage) -> some View {
        if !f.gross.isEmpty {
            Text(f.gross)
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
        }
        if !f.zeige.isEmpty {
            EmojiReihen(emojis: f.zeige)
        }
        if f.plus {
            Text("+")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gelb)
            EmojiReihen(emojis: f.zeigeZwei)
        }
        if !f.folge.isEmpty {
            Text(f.folge.joined(separator: " ") + " ❓")
                .font(.system(size: 40))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
    }

    private func optionKnopf(_ i: Int, _ o: String, _ f: VorschulFrage) -> some View {
        let istRichtig = richtigGewaehlt == i
        let istFalsch = falsch.contains(i)
        let farbe: Color = istRichtig ? Theme.mint.opacity(0.6)
            : (istFalsch ? Theme.koralle.opacity(0.35) : Color.white.opacity(0.14))
        return Button { wahl(i, f) } label: {
            Text(o)
                .font(.system(size: f.gruppenOptionen ? 30 : 54, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 112)
                .padding(6)
                .background(farbe, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(istRichtig ? Theme.mint : Color.white.opacity(0.18), lineWidth: istRichtig ? 4 : 1.5)
                )
                .opacity(istFalsch ? 0.45 : 1)
                .scaleEffect(istRichtig ? 1.06 : 1)
                .offset(x: schuettel == i ? 9 : 0)
                .animation(.spring(response: 0.18, dampingFraction: 0.25), value: schuettel)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: richtigGewaehlt)
        }
        .buttonStyle(TastenStil())
    }

    private var ergebnis: some View {
        let sterne = sterneFuer(gut: perfekt, gesamt: fragen.count)
        return VStack(spacing: 18) {
            Text(sterne == 3 ? "🎉" : (sterne >= 1 ? "👏" : "💪"))
                .font(.system(size: 90))
            Text("\(perfekt) von \(fragen.count) gleich richtig!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < sterne ? "star.fill" : "star")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.gelb)
                }
            }
            Button { neu() } label: {
                Label("Nochmal", systemImage: "arrow.clockwise")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: 280, minHeight: 56)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            Button("Fertig") { dismiss() }
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
        }
        .padding(24)
    }

    private func neu() {
        if let u = quelle {
            fragen = VorschulPaket.fragen(u)
        } else {
            fragen = VorschulGenerator.fragen(art, stufe: stufe)
        }
        nr = 0
        perfekt = 0
        zuruecksetzen()
        gespeichert = false
        if let f = fragen.first { VorschulTon.sag(f.text) }
    }

    private func zuruecksetzen() {
        falsch = []
        richtigGewaehlt = nil
        schuettel = nil
        sperre = false
    }

    private func wahl(_ i: Int, _ f: VorschulFrage) {
        guard !sperre, richtigGewaehlt == nil, !falsch.contains(i) else { return }
        if i == f.richtig {
            richtigGewaehlt = i
            if falsch.isEmpty { perfekt += 1 }
            sperre = true
            Haptik.erfolg()
            VorschulTon.lob()
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                weiter()
            }
        } else {
            falsch.insert(i)
            schuettel = i
            Haptik.fehler()
            VorschulTon.nochmal()
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                schuettel = nil
            }
        }
    }

    private func weiter() {
        nr += 1
        zuruecksetzen()
        if nr < fragen.count {
            VorschulTon.sag(fragen[nr].text)
        } else {
            abschliessen()
        }
    }

    private func abschliessen() {
        guard !gespeichert else { return }
        gespeichert = true
        VorschulTon.sag(VorschulText(de: "Das hast du toll gemacht!", tr: "Çok güzel yaptın!"))
        guard modus == "kind" else { return }
        let arbeitName = quelle?.arbeit?.titel ?? "Übungen"
        let uebungName = quelle.map { "\($0.symbol) \($0.titel)" } ?? "\(art.emoji) \(art.titel)"
        context.insert(RundenErgebnis(klasse: "Vorschule", fach: "Vorschule", arbeit: arbeitName,
                                      uebung: uebungName,
                                      richtig: perfekt, gesamt: fragen.count, angesehen: 0,
                                      quelle: "lokal"))
        try? context.save()
        CloudSync.anstossen(context)
    }
}

struct VorschulKarte: Identifiable {
    let id = UUID()
    let paar: Int
    let emoji: String
    var offen = false
    var weg = false
}

struct VorschulMemory: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("modus") private var modus = ""
    @AppStorage("vorschulStufe") private var stufe = 2
    @State private var karten: [VorschulKarte] = []
    @State private var erste: Int?
    @State private var zuege = 0
    @State private var sperre = false
    @State private var fertig = false

    private var paare: Int { stufe == 1 ? 3 : (stufe == 2 ? 4 : 6) }

    var body: some View {
        ZStack {
            HintergrundView()
            if fertig {
                geschafft
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Finde zwei gleiche Bilder")
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 12)], spacing: 12) {
                            ForEach(Array(karten.enumerated()), id: \.element.id) { i, k in
                                kartenKnopf(i, k)
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if karten.isEmpty { neu() } }
    }

    private func kartenKnopf(_ i: Int, _ k: VorschulKarte) -> some View {
        let zeigen = k.offen || k.weg
        return Button { tippe(i) } label: {
            Text(zeigen ? k.emoji : "❔")
                .font(.system(size: 44))
                .frame(maxWidth: .infinity, minHeight: 96)
                .background(zeigen ? Color.white.opacity(0.16) : Theme.gelb.opacity(0.85),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .opacity(k.weg ? 0.3 : 1)
        }
        .buttonStyle(TastenStil())
    }

    private var geschafft: some View {
        VStack(spacing: 18) {
            Text("🎉").font(.system(size: 90))
            Text("Alle Paare gefunden!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
            Text("In \(zuege) Zügen")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.gelb)
            Button { neu() } label: {
                Label("Nochmal", systemImage: "arrow.clockwise")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: 280, minHeight: 56)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            Button("Fertig") { dismiss() }
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
        }
        .padding(24)
    }

    private func neu() {
        let pool = (VorschulGenerator.dinge + ["🐰", "🦁", "🐸", "🍌", "🚌", "🌻"]).shuffled()
        var liste: [VorschulKarte] = []
        for (i, e) in pool.prefix(paare).enumerated() {
            liste.append(VorschulKarte(paar: i, emoji: e))
            liste.append(VorschulKarte(paar: i, emoji: e))
        }
        karten = liste.shuffled()
        erste = nil
        zuege = 0
        sperre = false
        fertig = false
    }

    private func tippe(_ i: Int) {
        guard !sperre, karten.indices.contains(i), !karten[i].offen, !karten[i].weg else { return }
        Haptik.leicht()
        withAnimation(.snappy) { karten[i].offen = true }
        guard let e = erste else {
            erste = i
            return
        }
        zuege += 1
        erste = nil
        if karten[e].paar == karten[i].paar {
            Haptik.erfolg()
            withAnimation(.snappy) {
                karten[e].weg = true
                karten[i].weg = true
            }
            if karten.allSatisfy({ $0.weg }) { abschliessen() }
        } else {
            sperre = true
            Task {
                try? await Task.sleep(for: .seconds(0.9))
                withAnimation(.snappy) {
                    karten[e].offen = false
                    karten[i].offen = false
                }
                sperre = false
            }
        }
    }

    private func abschliessen() {
        VorschulTon.lob()
        fertig = true
        guard modus == "kind" else { return }
        context.insert(RundenErgebnis(klasse: "Vorschule", fach: "Vorschule", arbeit: "Übungen",
                                      uebung: "🃏 Memory",
                                      richtig: paare, gesamt: max(paare, zuege), angesehen: 0,
                                      quelle: "lokal"))
        try? context.save()
        CloudSync.anstossen(context)
    }
}
