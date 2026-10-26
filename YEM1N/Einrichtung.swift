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

// MARK: - Einstieg: Modus wählen (Kind oder Eltern)

struct WurzelView: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("jokerIch") private var jokerIch = ""
    @AppStorage("farbwelt") private var farbwelt = "blau"
    @AppStorage(AlterFamilienweg.hinweisKey) private var umzugHinweis = false
    private let familie = FamilienModell.shared
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @State private var offenesPaket: ArbeitPaket?
    @State private var offenerText = ""
    @State private var zeigeOffen = false
    @State private var offenMeldung: String?
    @AppStorage("profilFertig") private var profilFertig = false
    @AppStorage(Einwilligung.versionKey) private var einwilligungVersion = 0

    private var brauchtEinwilligung: Bool {
        Einwilligung.erforderlich(gespeicherteVersion: einwilligungVersion)
    }

    var body: some View {
        Group {
            switch modus {
            case "kind": KindTabs()
            case "eltern": ElternTabs()
            default: ModusAuswahlView()
            }
        }
        .id(farbwelt)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .background(HintergrundView())
        .tint(Theme.gelb)
        .onOpenURL { url in
            guard url.isFileURL else { return }
            let zugriff = url.startAccessingSecurityScopedResource()
            defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
            guard let daten = try? Data(contentsOf: url),
                  let roh = String(data: daten, encoding: .utf8),
                  let gelesen = PaketAktion.lese(roh) else {
                offenMeldung = "Diese Datei ist kein YEM1N-Paket."
                return
            }
            offenesPaket = gelesen.paket
            offenerText = gelesen.text
            zeigeOffen = true
        }
        .confirmationDialog("\(offenesPaket?.arbeit ?? "Paket") importieren?",
                            isPresented: $zeigeOffen, titleVisibility: .visible) {
            if modus == "eltern" {
                Button("An meine Familie veröffentlichen") {
                    if let p = offenesPaket {
                        Task { offenMeldung = await PaketAktion.veroeffentliche(p, text: offenerText, context: context) }
                    }
                }
                if CloudDienst.klassenCloudCode != nil {
                    Button("An die Klasse veröffentlichen") {
                        if let p = offenesPaket {
                            Task { offenMeldung = await PaketAktion.veroeffentliche(p, text: offenerText, context: context, klasse: true) }
                        }
                    }
                }
            }
            Button("Nur auf diesem Gerät importieren") {
                if let p = offenesPaket { offenMeldung = PaketAktion.lokal(p, context: context) }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            if let p = offenesPaket {
                Text("\(p.klasse), \(p.fach): \(PaketAktion.anzahl(p)) Aufgaben")
            }
        }
        .alert("Hinweis", isPresented: Binding(get: { offenMeldung != nil },
                                              set: { if !$0 { offenMeldung = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(offenMeldung ?? "")
        }
        .fullScreenCover(isPresented: Binding(get: { !modus.isEmpty && (brauchtEinwilligung || !profilFertig) },
                                              set: { _ in })) {
            Group {
                if brauchtEinwilligung {
                    EinwilligungView()
                } else {
                    ProfilAssistent()
                }
            }
            .preferredColorScheme(.dark)
        }
        .alert("Die Familie ist jetzt sicherer", isPresented: Binding(
            get: { umzugHinweis && !brauchtEinwilligung && profilFertig },
            set: { if !$0 { umzugHinweis = false } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(modus == "eltern"
                 ? "Jede Familie hat jetzt ein eigenes, abgetrenntes Fach, und neue Geräte kommen nur mit einem QR-Code dazu. Der alte Familiencode gilt nicht mehr. Lege bitte unter Einstellungen > Familie eine neue Familie an und verbinde die anderen Geräte mit dem QR-Code."
                 : "Jede Familie hat jetzt ein eigenes, abgetrenntes Fach. Der alte Familiencode gilt nicht mehr. Bitte deine Eltern, dich unter Einstellungen > Familie mit einem QR-Code zu verbinden.")
        }
        .task(id: aufgabenKennung) { await cloudStart() }
        .onChange(of: phase) {
            guard phase == .active else { return }
            familie.ablaufPruefen()
            if !brauchtEinwilligung { Task { await CloudSync.aktiv(context) } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
            guard !brauchtEinwilligung else { return }
            Task { await CloudSync.aktiv(context, erzwingen: true) }
        }
    }

    /// Ändert sich etwas davon, startet die Anbindung an die Familie neu.
    private var aufgabenKennung: String {
        modus + "|" + (familie.zugang?.geraet ?? "-") + "|" + (familie.zugang?.status ?? "-")
            + (brauchtEinwilligung ? "|offen" : "")
    }

    private func cloudStart() async {
        guard !modus.isEmpty, !brauchtEinwilligung else { return }
        // Einmalig: Reste vom alten Familiencode in CloudKit aufräumen
        if await AlterFamilienweg.aufraeumen() { umzugHinweis = true }
        guard familie.zugang != nil || CloudDienst.klassenCloudCode != nil else { return }
        if familie.aktiv { await Mitteilungen.erlaubnisFragen() }
        await CloudSync.aktiv(context, erzwingen: true)
    }
}

/// Räumt einmal auf, wenn dieses Gerät noch den alten Familiencode (CloudKit) hatte.
/// Die Einträge, die dieses Gerät dort angelegt hat, werden gelöscht, dann ist der Code weg.
/// Klappt das wegen fehlender Verbindung nicht, versucht es die App beim nächsten Start noch einmal,
/// nach drei Versuchen gibt sie auf (zum Beispiel ohne iCloud-Konto) und vergisst den Code trotzdem.
enum AlterFamilienweg {
    static let codeKey = "familienCode"
    static let hinweisKey = "familienUmzugHinweis"
    static let versucheKey = "familienUmzugVersuche"

    /// true, wenn gerade aufgeräumt wurde (dann gibt es einen Hinweis für die Eltern).
    static func aufraeumen(speicher: UserDefaults = .standard) async -> Bool {
        let code = speicher.string(forKey: codeKey) ?? ""
        guard !code.isEmpty else { return false }
        if Familiencode.istGueltig(code) {
            if await CloudDienst.loescheAlteFamilienDaten(code: code) == nil {
                let versuche = speicher.integer(forKey: versucheKey) + 1
                speicher.set(versuche, forKey: versucheKey)
                if versuche < 3 { return false }
            }
        }
        for k in [codeKey, "cloudEingerichtet", versucheKey] { speicher.removeObject(forKey: k) }
        speicher.set(true, forKey: hinweisKey)
        return true
    }
}

struct ModusAuswahlView: View {
    @AppStorage("modus") private var modus = ""
    @State private var zeigeAnleitung = false

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("YEM1N")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.gelb)
                        Text("Wer benutzt dieses Gerät?")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textSanft)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 14) {
                        wahlKarte(titel: "Kind", text: "Ich übe für die Schule.", symbol: "graduationcap.fill") {
                            modus = "kind"
                        }
                        wahlKarte(titel: "Eltern", text: "Ich sehe den Fortschritt.", symbol: "bell.badge.fill") {
                            modus = "eltern"
                        }
                        Text("Mit der Familie verbindest du dieses Gerät gleich danach, mit einem QR-Code. Das geht auch später in den Einstellungen.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                        Button {
                            zeigeAnleitung = true
                        } label: {
                            Label("Anleitung ansehen", systemImage: "book.fill")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.gelb)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .padding(.top, 4)
                    }
                    .sheet(isPresented: $zeigeAnleitung) {
                        NavigationStack {
                            AnleitungView()
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Fertig") { zeigeAnleitung = false }
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func wahlKarte(titel: String, text: String, symbol: String,
                           aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 62, height: 62)
                    .background(Theme.gelb, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(titel)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(Color.white)
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSanft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.gelb)
            }
            .padding(18)
            .glasKarte(radius: 28)
        }
        .buttonStyle(TastenStil())
    }
}
