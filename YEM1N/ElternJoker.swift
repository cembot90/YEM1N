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

// MARK: - Eltern-Joker

enum JokerPunkteArt: String, CaseIterable, Codable {
    case schnell, zweite, hilfreich, verraten

    var titel: String {
        switch self {
        case .schnell: return "Erste Antwort"
        case .zweite: return "Zweite Antwort"
        case .hilfreich: return "Hilfreich (Daumen vom Kind)"
        case .verraten: return "Lösung verraten"
        }
    }

    var emoji: String {
        switch self {
        case .schnell: return "⚡"
        case .zweite: return "🥈"
        case .hilfreich: return "👍"
        case .verraten: return "🙈"
        }
    }

    var punkte: Int {
        switch self {
        case .schnell: return 3
        case .zweite: return 1
        case .hilfreich: return 2
        case .verraten: return -2
        }
    }
}

struct JokerMitglied: Codable, Identifiable {
    var id = UUID()
    var name: String
    var emoji: String
}

struct JokerEreignis: Codable, Identifiable {
    var id = UUID()
    var ts: Date
    var mitgliedID: UUID
    var art: JokerPunkteArt
}

@Observable
final class JokerStand {
    static let shared = JokerStand()
    var mitglieder: [JokerMitglied] = []
    var ereignisse: [JokerEreignis] = []
    var nutzungen: [Date] = []
    var limitProTag = 3
    var ligaAn = true
    private let key = "jokerStandV1"

    private struct Speicher: Codable {
        var mitglieder: [JokerMitglied]
        var ereignisse: [JokerEreignis]
        var nutzungen: [Date]
        var limitProTag: Int
        var ligaAn: Bool
    }

    init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode(Speicher.self, from: d) {
            mitglieder = s.mitglieder
            ereignisse = s.ereignisse
            nutzungen = s.nutzungen
            limitProTag = s.limitProTag
            ligaAn = s.ligaAn
        }
        if mitglieder.isEmpty {
            mitglieder = [JokerMitglied(name: "Papa", emoji: "👨"),
                          JokerMitglied(name: "Mama", emoji: "👩"),
                          JokerMitglied(name: "Geschwister", emoji: "🧑")]
        }
    }

    func sichere() {
        let s = Speicher(mitglieder: mitglieder, ereignisse: ereignisse, nutzungen: nutzungen,
                         limitProTag: limitProTag, ligaAn: ligaAn)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: key) }
    }

    var heuteGenutzt: Int {
        nutzungen.filter { Calendar.current.isDateInToday($0) }.count
    }

    var uebrigHeute: Int { max(0, limitProTag - heuteGenutzt) }

    // Verbraucht einen Joker. Gibt false zurück, wenn heute keiner mehr übrig ist.
    func nutze() -> Bool {
        if uebrigHeute <= 0 { return false }
        nutzungen.append(Date.now)
        if nutzungen.count > 200 { nutzungen = Array(nutzungen.suffix(200)) }
        sichere()
        return true
    }

    // Setzt die heutigen Joker auf das volle Limit zurück
    func auffuellen() {
        nutzungen.removeAll { Calendar.current.isDateInToday($0) }
        sichere()
    }

    func vergib(_ art: JokerPunkteArt, an id: UUID) {
        ereignisse.append(JokerEreignis(ts: Date.now, mitgliedID: id, art: art))
        sichere()
    }

    func letztesRueckgaengig() {
        if !ereignisse.isEmpty {
            ereignisse.removeLast()
            sichere()
        }
    }

    func punkte(_ id: UUID, seit: Date?) -> Int {
        ereignisse.filter { $0.mitgliedID == id && (seit == nil || $0.ts >= seit!) }
            .reduce(0) { $0 + $1.art.punkte }
    }

    func anzahl(_ art: JokerPunkteArt, _ id: UUID) -> Int {
        ereignisse.filter { $0.mitgliedID == id && $0.art == art }.count
    }

    func mitglied(_ id: UUID) -> JokerMitglied? { mitglieder.first { $0.id == id } }
}

// Texte für den Joker: nie die Lösung verraten
enum JokerText {
    static func mathe(_ a: Aufgabe) -> String {
        let kern: String
        if a.art == "mauer" {
            let basis = (a.reihen.first ?? []).map { String($0) }.joined(separator: " ")
            kern = "Zahlenmauer, unterste Reihe: \(basis)"
        } else {
            kern = a.rechnung.replacingOccurrences(of: "\n", with: " ")
        }
        return "🃏 YEM1N Joker! Ich brauche einen Tipp (bitte nicht die Lösung verraten):\n\(a.frage)\n\(kern)"
    }

    static func sprache(_ f: Frage, sprache: String) -> String {
        let info = SprachKatalogStore.shared.sprache(sprache)
        let de = f.wort.texte["de"] ?? ""
        let fremd = f.wort.texte[sprache] ?? ""
        let b = SprachHelfer.bild(f.wort)
        let kern: String
        switch f.typ {
        case .de2f, .tipp:
            kern = "Wie heißt „\(de)“ auf \(info.name)?"
        case .bild:
            kern = "Wie heißt \(b) auf \(info.name)?"
        case .f2de:
            kern = "Was bedeutet „\(fremd)“?"
        case .hoer:
            kern = "Ich habe „\(fremd)“ gehört. Was bedeutet das?"
        }
        return "🃏 YEM1N Joker! \(info.flagge) Ich brauche einen Tipp (bitte nicht die Lösung verraten):\n\(kern)"
    }
}

struct JokerKnopf: View {
    let uebrig: Int
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            Label("Joker (\(uebrig))", systemImage: "suit.spade.fill")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.gelb)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(Theme.gelb.opacity(0.14), in: Capsule())
        }
        .buttonStyle(TastenStil())
    }
}

// MARK: Eltern-Liga (Punkte werden vorerst von Hand eingetragen)

struct LigaZeile: Identifiable {
    let mitglied: JokerMitglied
    let punkte: Int
    var id: UUID { mitglied.id }
}

struct JokerLigaView: View {
    private let joker = JokerStand.shared
    @AppStorage("jokerIch") private var jokerIch = ""
    @State private var gesamt = false
    @State private var gewaehlt: UUID? = nil
    @State private var neuerName = ""
    @State private var neuesEmoji = "🙂"
    @State private var letzteMeldung = ""

    private var wochenStart: Date? {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date.now)?.start
    }

    private var rangliste: [LigaZeile] {
        let seit: Date? = gesamt ? nil : wochenStart
        var liste: [LigaZeile] = []
        for m in joker.mitglieder {
            liste.append(LigaZeile(mitglied: m, punkte: joker.punkte(m.id, seit: seit) + JokerCloud.shared.punkte(name: m.name, seit: seit)))
        }
        return liste.sorted { $0.punkte > $1.punkte }
    }

    private func platzText(_ platz: Int) -> String {
        let medaillen = ["🥇", "🥈", "🥉"]
        return medaillen.indices.contains(platz) ? medaillen[platz] : "\(platz + 1)."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kopf
                        JokerPostfachView()
                        JokerNachschubView()
                        if joker.ligaAn { liga }
                        eintragen
                        einstellungen
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var kopf: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Eltern-Joker")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gelb)
            Text("Wer dem Kind zuerst hilft, bekommt Punkte.")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSanft)
        }
    }

    private var liga: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Zeitraum", selection: $gesamt) {
                Text("Diese Woche").tag(false)
                Text("Gesamt").tag(true)
            }
            .pickerStyle(.segmented)
            ForEach(Array(rangliste.enumerated()), id: \.element.id) { platz, eintrag in
                HStack(spacing: 12) {
                    Text(platzText(platz))
                        .font(.system(size: 24))
                        .frame(width: 36)
                    Text(eintrag.mitglied.emoji).font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(eintrag.mitglied.name)
                            .font(.system(.body, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                        Text(abzeichen(eintrag.mitglied.id))
                            .font(.caption)
                            .foregroundStyle(Theme.textSanft)
                    }
                    Spacer()
                    Text("\(eintrag.punkte)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                }
            }
        }
        .padding(16)
        .glasKarte(radius: 26)
    }

    private func abzeichen(_ id: UUID) -> String {
        var a: [String] = []
        if joker.anzahl(.schnell, id) >= 3 { a.append("⚡ Blitz-Helfer") }
        if joker.anzahl(.hilfreich, id) >= 3 { a.append("👍 Lieblingshelfer") }
        if joker.anzahl(.verraten, id) >= 2 { a.append("🙈 Verräter") }
        if joker.punkte(id, seit: nil) >= 20 { a.append("🏅 Joker-Profi") }
        return a.isEmpty ? "noch keine Abzeichen" : a.joined(separator: " · ")
    }

    private var eintragen: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Punkte eintragen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text("Tipps aus dem Joker-Postfach zählen automatisch. Hier trägst du Sonderfälle ein, zum Beispiel wenn jemand die Lösung verraten hat.")
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
            HStack(spacing: 8) {
                ForEach(joker.mitglieder) { m in
                    let aktiv = (gewaehlt ?? joker.mitglieder.first?.id) == m.id
                    Button { gewaehlt = m.id } label: {
                        Text("\(m.emoji) \(m.name)")
                            .font(.system(.footnote, design: .rounded).weight(.heavy))
                            .foregroundStyle(aktiv ? Theme.navy : Color.white)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(aktiv ? Theme.gelb : Color.white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(TastenStil())
                }
            }
            ForEach(JokerPunkteArt.allCases, id: \.self) { art in
                Button { vergib(art) } label: {
                    HStack {
                        Text("\(art.emoji) \(art.titel)")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.white)
                        Spacer()
                        Text(art.punkte > 0 ? "+\(art.punkte)" : "\(art.punkte)")
                            .font(.system(.body, design: .rounded).weight(.heavy))
                            .foregroundStyle(art.punkte > 0 ? Theme.mint : Theme.koralle)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(TastenStil())
            }
            if !letzteMeldung.isEmpty {
                HStack {
                    Text(letzteMeldung)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.himmel)
                    Spacer()
                    Button("Rückgängig") {
                        joker.letztesRueckgaengig()
                        letzteMeldung = ""
                    }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.gelb)
                }
            }
        }
        .padding(16)
        .glasKarte(radius: 26)
    }

    private func vergib(_ art: JokerPunkteArt) {
        guard let id = gewaehlt ?? joker.mitglieder.first?.id, let m = joker.mitglied(id) else { return }
        joker.vergib(art, an: id)
        Haptik.leicht()
        letzteMeldung = "\(m.emoji) \(m.name): \(art.punkte > 0 ? "+" : "")\(art.punkte) (\(art.titel))"
    }

    private var einstellungen: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Einstellungen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text("Dieses Gerät gehört zu")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.textSanft)
            HStack(spacing: 8) {
                ForEach(joker.mitglieder) { m in
                    let ich = joker.mitglieder.first(where: { $0.id.uuidString == jokerIch }) ?? joker.mitglieder.first
                    let aktiv = (ich?.id == m.id)
                    Button { jokerIch = m.id.uuidString } label: {
                        Text("\(m.emoji) \(m.name)")
                            .font(.system(.footnote, design: .rounded).weight(.heavy))
                            .foregroundStyle(aktiv ? Theme.navy : Color.white)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(aktiv ? Theme.gelb : Color.white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(TastenStil())
                }
            }
            Stepper("Joker pro Tag fürs Kind: \(joker.limitProTag)",
                    value: Binding(get: { joker.limitProTag },
                                   set: { joker.limitProTag = $0; joker.sichere() }),
                    in: 1...10)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
            Toggle("Liga anzeigen", isOn: Binding(get: { joker.ligaAn },
                                                  set: { joker.ligaAn = $0; joker.sichere() }))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
                .tint(Theme.gelb)

            Text("Mitspieler")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.textSanft)
            ForEach(joker.mitglieder) { m in
                HStack {
                    Text("\(m.emoji) \(m.name)")
                        .foregroundStyle(Color.white)
                    Spacer()
                    if joker.mitglieder.count > 1 {
                        Button(role: .destructive) {
                            joker.mitglieder.removeAll { $0.id == m.id }
                            joker.ereignisse.removeAll { $0.mitgliedID == m.id }
                            joker.sichere()
                        } label: {
                            Image(systemName: "trash").foregroundStyle(Theme.koralle)
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                TextField("🙂", text: $neuesEmoji)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                TextField("Name hinzufügen", text: $neuerName)
                    .padding(10)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button {
                    let n = neuerName.trimmingCharacters(in: .whitespaces)
                    if n.isEmpty { return }
                    joker.mitglieder.append(JokerMitglied(name: n, emoji: neuesEmoji.isEmpty ? "🙂" : neuesEmoji))
                    joker.sichere()
                    neuerName = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Theme.navy)
                        .frame(width: 40, height: 40)
                        .background(Theme.gelb, in: Circle())
                }
            }
            Text(RechtHinweise.name)
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }
}
