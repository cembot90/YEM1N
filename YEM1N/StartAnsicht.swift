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

// MARK: - Startansicht: Klasse > Fach > Klassenarbeit

struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Klassenarbeit.klasse),
                  SortDescriptor(\Klassenarbeit.fach),
                  SortDescriptor(\Klassenarbeit.erstellt)])
    private var alleArbeiten: [Klassenarbeit]

    @State private var fachFilter = "Alle"
    @State private var zuLoeschen: [Klassenarbeit] = []
    @State private var fehler: String?
    @State private var zeigeEinfuegen = false
    @State private var zeigeDatei = false
    @State private var eingabeText = ""
    @State private var infoMeldung: String?
    @State private var zeigeEinstellungen = false
    @State private var zeigeEditor = false
    @State private var zeigePakete = false
    @State private var zeigeErfolge = false
    @State private var pfad = NavigationPath()
    @State private var zwischenPaket: ArbeitPaket?
    @State private var zwischenText = ""
    @State private var zeigeZwischen = false
    @AppStorage("modus") private var modus = ""
    @AppStorage("kindName") private var kindName = ""
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle == "lokal" })
    private var lokale: [RundenErgebnis]

    private var normale: [Klassenarbeit] {
        alleArbeiten.filter { $0.spezial.isEmpty && $0.fach != "Vorschule" }
    }

    private var alleFaecher: [String] { Array(Set(normale.map(\.fach))).sorted() }
    private var aktuellerFilter: String { alleFaecher.contains(fachFilter) ? fachFilter : "Alle" }

    private var offeneFehler: Int {
        var n = 0
        for k in normale {
            for u in k.uebungen {
                for a in u.aufgaben where a.richtig == false && !a.gemeistert { n += 1 }
            }
        }
        return n
    }

    private func oeffneSpezial(_ art: String) {
        if let offen = alleArbeiten.first(where: { $0.spezial == art && $0.fertigeUebungen < $0.uebungen.count }) {
            pfad.append(offen)
            return
        }
        let neu: Klassenarbeit?
        switch art {
        case "fehlerheft": neu = Spezial.fehlerheft(alle: normale, in: context)
        case "training": neu = Spezial.training(alle: normale, ergebnisse: lokale, in: context)
        default: neu = Spezial.probe(alle: normale, in: context)
        }
        guard let neu else {
            infoMeldung = "Keine offenen Fehler. Super gemacht! 🎉"
            return
        }
        for alt in alleArbeiten where alt.spezial == art { context.delete(alt) }
        pfad.append(neu)
    }

    private func pruefeZwischenablage() {
        guard let gelesen = PaketAktion.lese(UIPasteboard.general.string ?? "") else {
            infoMeldung = "In der Zwischenablage liegt kein passendes JSON von Claude. Kopiere es im Chat und tippe dann noch einmal hier."
            return
        }
        zwischenPaket = gelesen.paket
        zwischenText = gelesen.text
        zeigeZwischen = true
    }

    private func neueAufgabenHolen() async {
        let code = UserDefaults.standard.string(forKey: "familienCode") ?? ""
        guard Familiencode.istGueltig(code) || CloudDienst.klassenCloudCode != nil else {
            infoMeldung = "Es fehlt noch ein Familiencode oder Klassencode. Bitte im Tab Einstellungen eintragen."
            return
        }
        let n = await CloudSync.holePakete(context)
        if n > 1 { infoMeldung = "\(n) neue Aufgabenpakete geladen." }
        else if n == 1 { infoMeldung = "1 neues Aufgabenpaket geladen." }
        else if n == 0 { infoMeldung = "Alles aktuell. Es gibt nichts Neues." }
        else { infoMeldung = CloudStatus.shared.meldung }
    }

    private var gefiltert: [Klassenarbeit] {
        aktuellerFilter == "Alle" ? normale : normale.filter { $0.fach == aktuellerFilter }
    }

    private var klassen: [String] { Array(Set(gefiltert.map(\.klasse))).sorted() }

    private func faecher(_ klasse: String) -> [String] {
        Array(Set(gefiltert.filter { $0.klasse == klasse }.map(\.fach))).sorted()
    }

    private func arbeiten(_ klasse: String, _ fach: String) -> [Klassenarbeit] {
        normale.filter { $0.klasse == klasse && $0.fach == fach }
    }

    var body: some View {
        NavigationStack(path: $pfad) {
            ZStack {
                HintergrundView()
                VStack(spacing: 0) {
                    kopf
                    if normale.isEmpty { leer } else { liste }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Hinweis",
                   isPresented: Binding(get: { infoMeldung != nil },
                                        set: { if !$0 { infoMeldung = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(infoMeldung ?? "")
            }
            .sheet(isPresented: $zeigeEinstellungen) { EinstellungenView() }
            .sheet(isPresented: $zeigeEditor) {
                NavigationStack { MatheEditorView() }
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
            .sheet(isPresented: $zeigePakete) {
                NavigationStack { PaketeView() }
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
            .sheet(isPresented: $zeigeErfolge) {
                ErfolgeView()
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
            .confirmationDialog("\(zwischenPaket?.arbeit ?? "Paket") veröffentlichen?",
                                isPresented: $zeigeZwischen, titleVisibility: .visible) {
                Button("An meine Familie veröffentlichen") {
                    if let p = zwischenPaket {
                        Task { infoMeldung = await PaketAktion.veroeffentliche(p, text: zwischenText, context: context) }
                    }
                }
                if CloudDienst.klassenCloudCode != nil {
                    Button("An die Klasse veröffentlichen") {
                        if let p = zwischenPaket {
                            Task { infoMeldung = await PaketAktion.veroeffentliche(p, text: zwischenText, context: context, klasse: true) }
                        }
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                if let p = zwischenPaket {
                    Text("\(p.klasse), \(p.fach): \(PaketAktion.anzahl(p)) Aufgaben. Die Kind-Geräte laden das Paket automatisch.")
                }
            }
            .navigationDestination(for: Klassenarbeit.self) { ArbeitView(arbeit: $0) }
            .navigationDestination(for: Uebung.self) { UebungView(uebung: $0) }
            .fileImporter(isPresented: $zeigeDatei,
                          allowedContentTypes: [.json, .plainText]) { ergebnis in
                switch ergebnis {
                case .success(let url):
                    let zugriff = url.startAccessingSecurityScopedResource()
                    defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
                    importiereData(try? Data(contentsOf: url))
                case .failure(let e):
                    fehler = e.localizedDescription
                }
            }
            .sheet(isPresented: $zeigeEinfuegen) { einfuegenSheet }
            .alert("Import nicht möglich",
                   isPresented: Binding(get: { fehler != nil && !zeigeEinfuegen },
                                        set: { if !$0 { fehler = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(fehler ?? "")
            }
        }
    }

    // MARK: Kopf

    private var untertitel: String {
        var text = kindName.isEmpty ? "Schule üben" : "Hallo \(kindName)! Schule üben"
        let serie = Erfolge.serie(lokale)
        if modus != "eltern" && serie > 0 { text += " · 🔥 \(serie)" }
        return text
    }

    private var kopf: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("YEM1N")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                Text(untertitel)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            if modus != "eltern" {
                Button { zeigeErfolge = true } label: {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.gelb)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
            }
            Menu {
                Button("Text einfügen", systemImage: "text.cursor") {
                    fehler = nil
                    zeigeEinfuegen = true
                }
                Button("Aus Zwischenablage einfügen", systemImage: "doc.on.clipboard") {
                    importiereText(UIPasteboard.general.string)
                }
                Button("Datei importieren", systemImage: "folder") { zeigeDatei = true }
                if modus == "kind" {
                    Button("Neue Aufgaben holen", systemImage: "icloud.and.arrow.down") {
                        Task { await neueAufgabenHolen() }
                    }
                }
                if modus == "eltern" {
                    Button("Aufgaben-Editor", systemImage: "square.and.pencil") { zeigeEditor = true }
                    Button("Cloud-Pakete", systemImage: "icloud.and.arrow.up") { zeigePakete = true }
                }
                Divider()
                Button("Einstellungen", systemImage: "gearshape") { zeigeEinstellungen = true }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 48, height: 48)
                    .background(Theme.gelb, in: Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var leer: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.gelb)
                .symbolEffect(.pulse)
            Text("Noch keine Klassenarbeit")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
            Text(modus == "kind"
                 ? "Neue Aufgaben kommen automatisch von deinen Eltern."
                 : "Tippe auf das Plus und füge das JSON von Claude ein.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            if modus == "kind" {
                GelberKnopf(titel: "Neue Aufgaben holen") {
                    Task { await neueAufgabenHolen() }
                }
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Liste

    private var liste: some View {
        List {
            extraZeile
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))

            if alleFaecher.count > 1 {
                fachChips
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 2, leading: 20, bottom: 2, trailing: 20))
            }

            ForEach(klassen, id: \.self) { klasse in
                Text(klasse)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 14, leading: 24, bottom: 2, trailing: 24))

                ForEach(faecher(klasse), id: \.self) { fach in
                    Label(fach, systemImage: "book.closed.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.gelb)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 0, trailing: 24))

                    let treffer = arbeiten(klasse, fach)
                    ForEach(treffer) { a in
                        ZStack {
                            ArbeitKarte(arbeit: a)
                            NavigationLink(value: a) { EmptyView() }.opacity(0)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                    .onDelete { offsets in
                        zuLoeschen = offsets.map { treffer[$0] }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .refreshable { await CloudSync.aktiv(context, erzwingen: true) }
        .confirmationDialog("Möchtest du das wirklich löschen?",
                            isPresented: Binding(get: { !zuLoeschen.isEmpty },
                                                 set: { if !$0 { zuLoeschen = [] } }),
                            titleVisibility: .visible) {
            Button("Ja, löschen", role: .destructive) {
                zuLoeschen.forEach { context.delete($0) }
                try? context.save()
                zuLoeschen = []
            }
            Button("Nein, behalten", role: .cancel) { zuLoeschen = [] }
        } message: {
            Text(zuLoeschen.map(\.titel).joined(separator: ", ") + "\nDabei gehen auch alle Ergebnisse dazu verloren.")
        }
    }

    private var fachChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["Alle"] + alleFaecher, id: \.self) { f in
                    let aktiv = aktuellerFilter == f
                    Button { fachFilter = f } label: {
                        Text(f)
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(aktiv ? Theme.navy : Color.white)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 36)
                            .background(aktiv ? Theme.gelb : Color.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var extraZeile: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Extra")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            HStack(spacing: 10) {
                extraKnopf("📓", "Fehlerheft", offeneFehler > 0 ? "\(offeneFehler) offen" : "alles gut") {
                    oeffneSpezial("fehlerheft")
                }
                extraKnopf("🎯", "Training", "für heute") {
                    oeffneSpezial("training")
                }
                extraKnopf("📝", "Probearbeit", "30 Minuten") {
                    oeffneSpezial("probe")
                }
            }
            if modus == "eltern" {
                Button { pruefeZwischenablage() } label: {
                    Label("JSON aus Zwischenablage veröffentlichen", systemImage: "icloud.and.arrow.up")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.navy)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(Theme.gelb, in: Capsule())
                }
                .buttonStyle(TastenStil())
            }
        }
    }

    private func extraKnopf(_ emoji: String, _ titel: String, _ untertitel: String,
                            aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 28))
                Text(titel)
                    .font(.system(.footnote, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(untertitel)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSanft)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .glasKarte(radius: 20)
        }
        .buttonStyle(TastenStil())
    }

    private var einfuegenSheet: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                VStack(alignment: .leading, spacing: 10) {
                    TextEditor(text: $eingabeText)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(Color.white.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    if let fehler {
                        Text(fehler)
                            .font(.footnote)
                            .foregroundStyle(Theme.koralle)
                    }
                }
                .padding()
            }
            .navigationTitle("JSON einfügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { zeigeEinfuegen = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Importieren") {
                        if importiereText(eingabeText) {
                            eingabeText = ""
                            zeigeEinfuegen = false
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }

    // MARK: Import

    @discardableResult
    private func importiereText(_ text: String?) -> Bool {
        importiereData(text?.data(using: .utf8))
    }

    @discardableResult
    private func importiereData(_ daten: Data?) -> Bool {
        guard let daten, var text = String(data: daten, encoding: .utf8), !text.isEmpty else {
            fehler = "Es wurde kein Text gefunden."
            return false
        }
        // Falls Code-Zaun oder Begleittext mitkopiert wurde: nur das JSON-Objekt nehmen
        if let s = text.firstIndex(of: "{"), let e = text.lastIndex(of: "}"), s < e {
            text = String(text[s...e])
        }
        // Sprachkatalog statt Klassenarbeit: an den Sprachbereich weitergeben
        if text.contains("\"sprachkatalog\"") || (text.contains("\"themen\"") && !text.contains("\"uebungen\"")) {
            if let n = SprachKatalogStore.shared.importiere(text) {
                infoMeldung = "\(n) Sprachthema/Sprachthemen geladen. Du findest sie im Tab Sprachen."
                return true
            }
            fehler = "Das Sprachformat passt nicht. Erwartet wird ein JSON mit einer Liste „themen“."
            return false
        }
        guard let bereinigt = text.data(using: .utf8),
              let paket = try? JSONDecoder().decode(ArbeitPaket.self, from: bereinigt) else {
            fehler = "Das Format passt nicht. Bitte das JSON von Claude komplett kopieren."
            return false
        }
        guard !paket.uebungen.isEmpty, paket.uebungen.allSatisfy({ !$0.aufgaben.isEmpty }) else {
            fehler = "Die Klassenarbeit enthält keine Übungen oder leere Übungen."
            return false
        }
        if alleArbeiten.contains(where: {
            $0.klasse == paket.klasse && $0.fach == paket.fach && $0.titel == paket.arbeit
        }) {
            fehler = "\(paket.arbeit) (\(paket.klasse), \(paket.fach)) ist schon vorhanden. Zum Ersetzen in der Liste nach links wischen und löschen."
            return false
        }

        PaketImport.einfuegen(paket, in: context)
        return true
    }
}

struct ArbeitKarte: View {
    let arbeit: Klassenarbeit

    private var anteil: Double {
        Double(arbeit.fertigeUebungen) / Double(max(arbeit.uebungen.count, 1))
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Fortschrittsring(wert: anteil, breite: 7)
                Text("\(arbeit.fertigeUebungen)/\(arbeit.uebungen.count)")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 5) {
                Text(arbeit.titel)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
                HStack(spacing: 5) {
                    Image(systemName: "star.fill").foregroundStyle(Theme.gelb)
                    Text("\(arbeit.sterne) von \(arbeit.maxSterne)")
                        .foregroundStyle(Theme.textSanft)
                }
                .font(.system(.subheadline, design: .rounded).weight(.medium))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.gelb)
        }
        .padding(18)
        .glasKarte(radius: 28)
    }
}
