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

// MARK: - Vokabel-Editor

struct EditorWort: Codable, Identifiable, Equatable {
    var id = UUID()
    var emoji = ""
    var de = ""
    var en = ""
    var tr = ""
    var it = ""
    var altEn = ""
    var altTr = ""
    var altIt = ""
    var hinweis = ""
    /// Hinweise nur für eine Sprache. Der Editor zeigt sie nicht an, behält sie aber.
    var hinweise: [String: String] = [:]

    init(id: UUID = UUID(), emoji: String = "", de: String = "", en: String = "", tr: String = "",
         it: String = "", altEn: String = "", altTr: String = "", altIt: String = "",
         hinweis: String = "", hinweise: [String: String] = [:]) {
        self.id = id
        self.emoji = emoji
        self.de = de
        self.en = en
        self.tr = tr
        self.it = it
        self.altEn = altEn
        self.altTr = altTr
        self.altIt = altIt
        self.hinweis = hinweis
        self.hinweise = hinweise
    }

    // Ältere gespeicherte Entwürfe kennen Italienisch noch nicht
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        emoji = (try? c.decode(String.self, forKey: .emoji)) ?? ""
        de = (try? c.decode(String.self, forKey: .de)) ?? ""
        en = (try? c.decode(String.self, forKey: .en)) ?? ""
        tr = (try? c.decode(String.self, forKey: .tr)) ?? ""
        it = (try? c.decode(String.self, forKey: .it)) ?? ""
        altEn = (try? c.decode(String.self, forKey: .altEn)) ?? ""
        altTr = (try? c.decode(String.self, forKey: .altTr)) ?? ""
        altIt = (try? c.decode(String.self, forKey: .altIt)) ?? ""
        hinweis = (try? c.decode(String.self, forKey: .hinweis)) ?? ""
        hinweise = (try? c.decode([String: String].self, forKey: .hinweise)) ?? [:]
    }

    static func liste(_ s: String) -> [String] {
        s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var gueltig: Bool {
        !de.trimmingCharacters(in: .whitespaces).isEmpty
            && !en.trimmingCharacters(in: .whitespaces).isEmpty
            && !tr.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func katalogDict() -> [String: Any] {
        var d: [String: Any] = ["de": de, "en": en, "tr": tr]
        if !it.trimmingCharacters(in: .whitespaces).isEmpty { d["it"] = it }
        if !emoji.isEmpty { d["emoji"] = emoji }
        var alt: [String: [String]] = [:]
        let e = EditorWort.liste(altEn)
        let t = EditorWort.liste(altTr)
        if !e.isEmpty { alt["en"] = e }
        let i = EditorWort.liste(altIt)
        if !t.isEmpty { alt["tr"] = t }
        if !i.isEmpty { alt["it"] = i }
        if !alt.isEmpty { d["alt"] = alt }
        if !hinweis.isEmpty { d["hinweis"] = hinweis }
        let echte = hinweise.filter { !$0.value.isEmpty }
        if !echte.isEmpty { d["hinweise"] = echte }
        return d
    }
}

struct EditorThema: Codable, Identifiable, Equatable {
    var id: String
    var titel: String
    var emoji: String
    var stufe: Int
    var bilder: Bool
    var woerter: [EditorWort]

    func katalogDict() -> [String: Any] {
        ["id": id, "titel": titel, "emoji": emoji, "stufe": stufe, "bilder": bilder,
         "typ": "woerter", "woerter": woerter.map { $0.katalogDict() }]
    }

    func jsonText() -> String {
        let d: [String: Any] = ["themen": [katalogDict()]]
        guard let data = try? JSONSerialization.data(withJSONObject: d,
                                                     options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
              let s = String(data: data, encoding: .utf8) else { return "" }
        return s
    }

    static func aus(_ t: Thema) -> EditorThema {
        EditorThema(id: t.id, titel: t.titel, emoji: t.emoji, stufe: t.stufe, bilder: t.bilder,
                    woerter: t.woerter.map { w in
                        EditorWort(emoji: w.emoji ?? "", de: w.texte["de"] ?? "", en: w.texte["en"] ?? "",
                                   tr: w.texte["tr"] ?? "", it: w.texte["it"] ?? "",
                                   altEn: (w.alt["en"] ?? []).joined(separator: ", "),
                                   altTr: (w.alt["tr"] ?? []).joined(separator: ", "),
                                   altIt: (w.alt["it"] ?? []).joined(separator: ", "),
                                   hinweis: w.hinweis ?? "", hinweise: w.hinweise)
                    })
    }
}

@Observable
final class SprachEditorStore {
    static let shared = SprachEditorStore()
    var themen: [EditorThema] = []
    private let key = "sprachEditorThemenV1"

    init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let t = try? JSONDecoder().decode([EditorThema].self, from: d) {
            themen = t
        }
    }

    func hat(_ id: String) -> Bool { themen.contains { $0.id == id } }

    func katalogDaten() -> Data? {
        if themen.isEmpty { return nil }
        let d: [String: Any] = ["themen": themen.map { $0.katalogDict() }]
        return try? JSONSerialization.data(withJSONObject: d)
    }

    private func sichere() {
        if let d = try? JSONEncoder().encode(themen) { UserDefaults.standard.set(d, forKey: key) }
        SprachKatalogStore.shared.baueNeu()
    }

    func speichere(_ t: EditorThema) {
        if let i = themen.firstIndex(where: { $0.id == t.id }) {
            themen[i] = t
        } else {
            themen.append(t)
        }
        sichere()
    }

    func loesche(_ id: String) {
        themen.removeAll { $0.id == id }
        sichere()
    }
}

struct SprachEditorListeView: View {
    private let store = SprachKatalogStore.shared
    private let editor = SprachEditorStore.shared
    @State private var geheZu: String? = nil

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Button { neuesThema() } label: {
                        Label("Neues Thema anlegen", systemImage: "plus.circle.fill")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.navy)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Theme.gelb, in: Capsule())
                    }
                    .buttonStyle(TastenStil())

                    Text("Eingebaute Themen kannst du ändern, zum Beispiel um ein Wort zu korrigieren. Die geänderte Fassung gilt dann auf diesem Gerät.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)

                    ForEach(store.katalog.themen) { t in
                        NavigationLink { SprachThemaEditorView(themaID: t.id) } label: { zeile(t) }
                            .buttonStyle(TastenStil())
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Themen bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $geheZu) { id in SprachThemaEditorView(themaID: id) }
    }

    private func neuesThema() {
        let kurz = String(UUID().uuidString.prefix(6)).lowercased()
        let t = EditorThema(id: "eigen-" + kurz, titel: "Neues Thema", emoji: "✨", stufe: 2, bilder: true, woerter: [])
        editor.speichere(t)
        geheZu = t.id
    }

    private func zeile(_ t: Thema) -> some View {
        let eigen = t.id.hasPrefix("eigen-")
        let geaendert = editor.hat(t.id) && !eigen
        return HStack(spacing: 12) {
            Text(t.emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(t.titel)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
                Text("\(t.woerter.count) Wörter · Stufe \(t.stufe)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            if eigen {
                Text("eigen").font(.caption2.weight(.heavy)).foregroundStyle(Theme.navy)
                    .padding(.horizontal, 8).padding(.vertical, 3).background(Theme.gelb, in: Capsule())
            } else if geaendert {
                Text("geändert").font(.caption2.weight(.heavy)).foregroundStyle(Theme.navy)
                    .padding(.horizontal, 8).padding(.vertical, 3).background(Theme.himmel, in: Capsule())
            }
            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.gelb)
        }
        .padding(14)
        .glasKarte(radius: 22)
    }
}

struct SprachThemaEditorView: View {
    let themaID: String
    @Environment(\.dismiss) private var dismiss
    @State private var entwurf = EditorThema(id: "", titel: "", emoji: "✨", stufe: 2, bilder: true, woerter: [])
    @State private var geladen = false
    @State private var original = EditorThema(id: "", titel: "", emoji: "✨", stufe: 2, bilder: true, woerter: [])
    @State private var meldung: String? = nil
    @State private var zeigeLoeschen = false
    private let store = SprachKatalogStore.shared
    private let editor = SprachEditorStore.shared
    private var feld: Color { Color.white.opacity(0.08) }

    private var istEigen: Bool { themaID.hasPrefix("eigen-") }

    private var probleme: [String] {
        var p: [String] = []
        if entwurf.titel.trimmingCharacters(in: .whitespaces).isEmpty { p.append("Der Titel fehlt.") }
        if entwurf.woerter.isEmpty { p.append("Das Thema hat noch keine Wörter.") }
        for w in entwurf.woerter where !w.gueltig {
            p.append("Beim Wort „\(w.de.isEmpty ? "?" : w.de)“ fehlt Deutsch, Englisch oder Türkisch.")
        }
        let en = entwurf.woerter.map { $0.en.lowercased().trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if Set(en).count != en.count { p.append("Ein englisches Wort kommt doppelt vor.") }
        return p
    }

    var body: some View {
        ZStack {
            HintergrundView()
            List {
                Section("Thema") {
                    TextField("Titel", text: $entwurf.titel)
                    TextField("Emoji", text: $entwurf.emoji)
                    Picker("Stufe", selection: $entwurf.stufe) {
                        Text("Stufe 1").tag(1)
                        Text("Stufe 2").tag(2)
                        Text("Stufe 3").tag(3)
                    }
                    Toggle("Bilder (Emoji) in Fragen zeigen", isOn: $entwurf.bilder)
                }
                .listRowBackground(feld)

                Section("Wörter (\(entwurf.woerter.count))") {
                    ForEach($entwurf.woerter) { $w in
                        NavigationLink {
                            WortEditorView(wort: $w)
                        } label: {
                            HStack(spacing: 10) {
                                Text(w.emoji.isEmpty ? "·" : w.emoji).font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(w.de.isEmpty ? "Neues Wort" : w.de)
                                        .font(.system(.body, design: .rounded).weight(.bold))
                                    Text("\(w.en) · \(w.tr)")
                                        .font(.caption)
                                        .foregroundStyle(w.gueltig ? Theme.textSanft : Theme.koralle)
                                }
                            }
                        }
                    }
                    .onDelete { entwurf.woerter.remove(atOffsets: $0) }
                    Button {
                        entwurf.woerter.append(EditorWort())
                    } label: {
                        Label("Wort hinzufügen", systemImage: "plus.circle.fill")
                    }
                }
                .listRowBackground(feld)

                if !probleme.isEmpty {
                    Section("Noch zu tun") {
                        ForEach(probleme, id: \.self) { p in
                            Text(p).font(.footnote).foregroundStyle(Theme.koralle)
                        }
                    }
                    .listRowBackground(feld)
                }

                Section {
                    Button { speichere() } label: {
                        Label("Speichern", systemImage: "checkmark.circle.fill")
                    }
                    .disabled(!probleme.isEmpty)
                    ShareLink(item: entwurf.jsonText()) {
                        Label("Als JSON teilen (für das Kind-Gerät)", systemImage: "square.and.arrow.up")
                    }
                    if istEigen {
                        Button(role: .destructive) { zeigeLoeschen = true } label: {
                            Label("Thema löschen", systemImage: "trash")
                        }
                    } else if editor.hat(themaID) {
                        Button(role: .destructive) { zeigeLoeschen = true } label: {
                            Label("Auf die eingebaute Fassung zurücksetzen", systemImage: "arrow.uturn.backward")
                        }
                    }
                } footer: {
                    Text("Auf dem Kind-Gerät fügst du das JSON unter Sprachen, Einstellungen, Weitere Themen laden ein (oder mit Plus, Text einfügen im Mathe-Tab).")
                }
                .listRowBackground(feld)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(entwurf.titel.isEmpty ? "Thema" : entwurf.titel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .primaryAction) { EditButton() } }
        .onAppear { lade() }
        .onDisappear {
            if geladen && entwurf != original && probleme.isEmpty { editor.speichere(entwurf) }
        }
        .alert("Thema", isPresented: Binding(get: { meldung != nil }, set: { if !$0 { meldung = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(meldung ?? "")
        }
        .confirmationDialog(istEigen ? "Thema löschen?" : "Zurücksetzen?", isPresented: $zeigeLoeschen, titleVisibility: .visible) {
            Button(istEigen ? "Löschen" : "Zurücksetzen", role: .destructive) {
                editor.loesche(themaID)
                original = entwurf
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private func lade() {
        if geladen { return }
        if let vorhanden = editor.themen.first(where: { $0.id == themaID }) {
            entwurf = vorhanden
        } else if let t = store.katalog.themen.first(where: { $0.id == themaID }) {
            entwurf = EditorThema.aus(t)
        }
        original = entwurf
        geladen = true
    }

    private func speichere() {
        editor.speichere(entwurf)
        original = entwurf
        meldung = "Gespeichert. Das Thema ist jetzt im Sprachbereich dieses Geräts zu sehen."
    }
}

struct WortEditorView: View {
    @Binding var wort: EditorWort
    private var feld: Color { Color.white.opacity(0.08) }

    var body: some View {
        ZStack {
            HintergrundView()
            List {
                Section("Wort") {
                    TextField("Emoji (optional)", text: $wort.emoji)
                    TextField("Deutsch, zum Beispiel der Hund", text: $wort.de)
                    TextField("Englisch, zum Beispiel dog", text: $wort.en)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Türkisch, zum Beispiel köpek", text: $wort.tr)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Italienisch, zum Beispiel cane (kann leer bleiben)", text: $wort.it)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack(spacing: 6) {
                        ForEach(["ç", "ğ", "ı", "ö", "ş", "ü", "İ"], id: \.self) { z in
                            Button { wort.tr += z } label: {
                                Text(z)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listRowBackground(feld)

                Section {
                    TextField("Englisch, zum Beispiel mom, mummy", text: $wort.altEn)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Türkisch, zum Beispiel bere", text: $wort.altTr)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Italienisch, zum Beispiel il cane", text: $wort.altIt)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Weitere richtige Schreibweisen")
                } footer: {
                    Text("Mit Komma trennen. Diese Varianten zählen beim Tippen auch als richtig.")
                }
                .listRowBackground(feld)

                Section("Hinweis (optional)") {
                    TextField("zum Beispiel Mamas Mutter heißt anneanne", text: $wort.hinweis, axis: .vertical)
                }
                .listRowBackground(feld)

                if !wort.gueltig {
                    Section {
                        Text("Deutsch, Englisch und Türkisch müssen ausgefüllt sein.")
                            .font(.footnote)
                            .foregroundStyle(Theme.koralle)
                    }
                    .listRowBackground(feld)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(wort.de.isEmpty ? "Neues Wort" : wort.de)
        .navigationBarTitleDisplayMode(.inline)
    }
}
