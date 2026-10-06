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
// MARK: - Erfolge: Serie, Tagesziel, Pokale
// ============================================================

struct Pokal: Identifiable {
    let id: String
    let emoji: String
    let titel: String
    let erreicht: Bool
}

enum Erfolge {
    static func tageMitRunde(_ liste: [RundenErgebnis]) -> Set<Date> {
        let kal = Calendar.current
        var tage = Set<Date>()
        for e in liste { tage.insert(kal.startOfDay(for: e.zeitpunkt)) }
        return tage
    }

    // Aufeinanderfolgende Tage mit mindestens einer Runde, bis heute oder gestern
    static func serie(_ liste: [RundenErgebnis]) -> Int {
        let kal = Calendar.current
        let tage = tageMitRunde(liste)
        var tag = kal.startOfDay(for: Date.now)
        if !tage.contains(tag) {
            tag = kal.date(byAdding: .day, value: -1, to: tag) ?? tag
        }
        var n = 0
        while tage.contains(tag) {
            n += 1
            tag = kal.date(byAdding: .day, value: -1, to: tag) ?? tag.addingTimeInterval(-86400)
        }
        return n
    }

    static func besteSerie(_ liste: [RundenErgebnis]) -> Int {
        let kal = Calendar.current
        let tage = tageMitRunde(liste).sorted()
        var beste = 0
        var aktuell = 0
        var vorher: Date?
        for t in tage {
            if let v = vorher, kal.date(byAdding: .day, value: 1, to: v) == t {
                aktuell += 1
            } else {
                aktuell = 1
            }
            beste = max(beste, aktuell)
            vorher = t
        }
        return beste
    }

    static func rundenHeute(_ liste: [RundenErgebnis]) -> Int {
        liste.filter { Calendar.current.isDateInToday($0.zeitpunkt) }.count
    }

    static func zieltage(_ liste: [RundenErgebnis], ziel: Int) -> Int {
        let kal = Calendar.current
        var zaehler: [Date: Int] = [:]
        for e in liste { zaehler[kal.startOfDay(for: e.zeitpunkt), default: 0] += 1 }
        return zaehler.values.filter { $0 >= ziel }.count
    }

    static func pokale(_ liste: [RundenErgebnis], ziel: Int) -> [Pokal] {
        let n = liste.count
        let sterne = liste.reduce(0) { $0 + $1.sterne }
        let beste = besteSerie(liste)
        let dreiSterne = liste.contains { $0.sterne == 3 }
        let fehlerfrei = liste.contains { $0.gesamt > 0 && $0.richtig == $0.gesamt && $0.angesehen == 0 }
        let zielTage = zieltage(liste, ziel: ziel)
        return [
            Pokal(id: "erste", emoji: "🎯", titel: "Erste Runde", erreicht: n >= 1),
            Pokal(id: "r10", emoji: "🥉", titel: "10 Runden", erreicht: n >= 10),
            Pokal(id: "r50", emoji: "🥈", titel: "50 Runden", erreicht: n >= 50),
            Pokal(id: "r100", emoji: "🥇", titel: "100 Runden", erreicht: n >= 100),
            Pokal(id: "s3", emoji: "🔥", titel: "3 Tage in Folge", erreicht: beste >= 3),
            Pokal(id: "s7", emoji: "⚡", titel: "7 Tage in Folge", erreicht: beste >= 7),
            Pokal(id: "s14", emoji: "👑", titel: "14 Tage in Folge", erreicht: beste >= 14),
            Pokal(id: "s30", emoji: "🏆", titel: "30 Tage in Folge", erreicht: beste >= 30),
            Pokal(id: "stern", emoji: "⭐", titel: "3 Sterne", erreicht: dreiSterne),
            Pokal(id: "st50", emoji: "🌟", titel: "50 Sterne", erreicht: sterne >= 50),
            Pokal(id: "st150", emoji: "💫", titel: "150 Sterne", erreicht: sterne >= 150),
            Pokal(id: "fehlerfrei", emoji: "💯", titel: "Ohne Fehler", erreicht: fehlerfrei),
            Pokal(id: "ziel5", emoji: "🎉", titel: "Tagesziel 5 Tage", erreicht: zielTage >= 5),
            Pokal(id: "m_einmaleins", emoji: "🧮", titel: "Einmaleins-Meister", erreicht: meister(liste, "Einmaleins")),
            Pokal(id: "m_kern", emoji: "🧠", titel: "Kernaufgaben-Profi", erreicht: meister(liste, "Kernaufgaben")),
            Pokal(id: "m_nachbar", emoji: "🏘️", titel: "Nachbar-Meister", erreicht: meister(liste, "Nachbar")),
            Pokal(id: "m_geteilt", emoji: "➗", titel: "Geteilt-Held", erreicht: meister(liste, "Geteilt")),
            Pokal(id: "m_rest", emoji: "🧩", titel: "Rest-Experte", erreicht: meister(liste, "Rest")),
            Pokal(id: "m_mauer", emoji: "🧱", titel: "Mauer-Baumeister", erreicht: meister(liste, "Zahlenmauern")),
            Pokal(id: "m_raetsel", emoji: "🔍", titel: "Rätsel-Knacker", erreicht: meister(liste, "Zahlenrätsel")),
            Pokal(id: "m_sach", emoji: "✏️", titel: "Sachaufgaben-Profi", erreicht: meister(liste, "Sachaufgaben")),
            Pokal(id: "m_gemischt", emoji: "🎓", titel: "Alles-gemischt-Meister", erreicht: meister(liste, "Alles gemischt")),
            Pokal(id: "m_deutsch", emoji: "📚", titel: "Deutsch-Held", erreicht: liste.contains { $0.fach == "Deutsch" && $0.gesamt > 0 && $0.richtig == $0.gesamt }),
            Pokal(id: "frueh", emoji: "🌅", titel: "Frühstarter", erreicht: liste.contains { Calendar.current.component(.hour, from: $0.zeitpunkt) < 9 })
        ]
    }

    // Eine Übung, deren Titel das Stichwort enthält, wurde einmal komplett richtig gelöst
    static func meister(_ liste: [RundenErgebnis], _ stichwort: String) -> Bool {
        liste.contains {
            $0.uebung.localizedCaseInsensitiveContains(stichwort) && $0.gesamt > 0 && $0.richtig == $0.gesamt
        }
    }

    // Abzeichen, die seit dem letzten Mal neu dazugekommen sind
    static func neue(_ liste: [RundenErgebnis], ziel: Int) -> [Pokal] {
        let schluessel = "pokaleGesehen"
        let speicher = UserDefaults.standard
        let erreicht = pokale(liste, ziel: ziel).filter { $0.erreicht }
        let ids = Set(erreicht.map { $0.id })
        var gesehen = Set<String>()
        if let alt = speicher.string(forKey: schluessel) {
            gesehen = Set(alt.split(separator: ",").map { String($0) })
        } else if liste.count > 1 {
            // Bestehende Geräte: bisherige Abzeichen still übernehmen
            speicher.set(ids.sorted().joined(separator: ","), forKey: schluessel)
            return []
        }
        let neu = erreicht.filter { !gesehen.contains($0.id) }
        if !neu.isEmpty {
            speicher.set(gesehen.union(ids).sorted().joined(separator: ","), forKey: schluessel)
        }
        return neu
    }
}

struct ErfolgeView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle == "lokal" })
    private var lokale: [RundenErgebnis]
    @AppStorage("tagesziel") private var ziel = 2
    @AppStorage("kindName") private var kindName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        serieKarte
                        zielKarte
                        pokaleKarte
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(kindName.isEmpty ? "Meine Erfolge" : "Erfolge von \(kindName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private var serieKarte: some View {
        let serie = Erfolge.serie(lokale)
        return HStack(spacing: 16) {
            Text("🔥").font(.system(size: 46))
            VStack(alignment: .leading, spacing: 2) {
                Text(serie == 1 ? "1 Tag in Folge" : "\(serie) Tage in Folge")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Text("Beste Serie: \(Erfolge.besteSerie(lokale))")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var zielKarte: some View {
        let heute = Erfolge.rundenHeute(lokale)
        let anteil = min(Double(heute) / Double(max(ziel, 1)), 1)
        return HStack(spacing: 16) {
            ZStack {
                Fortschrittsring(wert: anteil, breite: 8)
                Text("\(heute)/\(ziel)")
                    .font(.system(.footnote, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text("Tagesziel")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Text(heute >= ziel ? "Geschafft! 🎉" : "Noch \(ziel - heute) \(ziel - heute == 1 ? "Runde" : "Runden")")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var pokaleKarte: some View {
        let liste = Erfolge.pokale(lokale, ziel: ziel)
        let geschafft = liste.filter { $0.erreicht }.count
        return VStack(alignment: .leading, spacing: 12) {
            Text("Pokale: \(geschafft) von \(liste.count)")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(liste) { p in
                    VStack(spacing: 4) {
                        Text(p.emoji)
                            .font(.system(size: 34))
                            .opacity(p.erreicht ? 1 : 0.25)
                        Text(p.titel)
                            .font(.system(.caption, design: .rounded).weight(.heavy))
                            .foregroundStyle(p.erreicht ? Color.white : Theme.textSanft)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 92)
                    .padding(6)
                    .background(Color.white.opacity(p.erreicht ? 0.12 : 0.05),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }
}
