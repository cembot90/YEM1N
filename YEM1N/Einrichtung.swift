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
    @AppStorage("familienCode") private var familienCode = ""
    @AppStorage("jokerIch") private var jokerIch = ""
    @AppStorage("farbwelt") private var farbwelt = "blau"
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
        .task(id: CloudDienst.marke(modus: modus, code: familienCode) + (brauchtEinwilligung ? "-offen" : "")) { await cloudStart() }
        .onChange(of: phase) {
            if phase == .active, !brauchtEinwilligung { Task { await CloudSync.aktiv(context) } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
            guard !brauchtEinwilligung else { return }
            Task { await CloudSync.aktiv(context, erzwingen: true) }
        }
    }

    private func cloudStart() async {
        guard !modus.isEmpty, Familiencode.istGueltig(familienCode), !brauchtEinwilligung else { return }
        await CloudDienst.raeumeAufWennNoetig(code: familienCode)
        let marke = CloudDienst.marke(modus: modus, code: familienCode)
        if UserDefaults.standard.string(forKey: "cloudEingerichtet") == marke {
            CloudStatus.shared.meldung = "Cloud ist bereit. Mitteilungen sind eingerichtet."
            await CloudSync.aktiv(context)
            return
        }
        CloudStatus.shared.meldung = "Cloud wird eingerichtet ..."
        let ergebnis = await CloudDienst.einrichten(code: familienCode, rolle: modus)
        CloudStatus.shared.meldung = ergebnis
        if ergebnis.hasPrefix("Cloud ist bereit") {
            UserDefaults.standard.set(marke, forKey: "cloudEingerichtet")
        }
        await CloudSync.aktiv(context, erzwingen: true)
    }
}

struct ModusAuswahlView: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""
    @AppStorage("klassenCode") private var klassenCode = ""
    @State private var schritt = 0          // 0 Auswahl, 1 Kind, 2 Eltern
    @State private var codeEingabe = ""
    @State private var klassenEingabe = ""
    @State private var neuerCode = ""
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

                    switch schritt {
                    case 1: kindSchritt
                    case 2: elternSchritt
                    case 3: elternBeitreten
                    default: auswahl
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
        .animation(.smooth, value: schritt)
    }

    // MARK: Auswahl

    @ViewBuilder
    private var auswahl: some View {
        VStack(spacing: 14) {
            wahlKarte(titel: "Kind", text: "Ich übe für die Schule.", symbol: "graduationcap.fill") {
                codeEingabe = familienCode
                klassenEingabe = klassenCode
                schritt = 1
            }
            wahlKarte(titel: "Eltern", text: "Ich sehe den Fortschritt.", symbol: "bell.badge.fill") {
                neuerCode = familienCode.isEmpty ? Familiencode.neu() : familienCode
                schritt = 2
            }
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

    // MARK: Kind

    @ViewBuilder
    private var kindSchritt: some View {
        let famLeer = codeEingabe.isEmpty
        let klaLeer = klassenEingabe.isEmpty
        let famOK = famLeer || Familiencode.istGueltig(codeEingabe)
        let klaOK = klaLeer || Familiencode.istGueltig(klassenEingabe)
        let gueltig = famOK && klaOK && !(famLeer && klaLeer)
        VStack(spacing: 16) {
            Text("Code eingeben")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("Trage den Familiencode (vom Eltern-Gerät), den Klassencode oder beide ein. Ein Code reicht. Du kannst alles auch später in den Einstellungen eintragen.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)

            codeFeld("Familiencode", $codeEingabe)
            codeFeld("Klassencode", $klassenEingabe)

            QRScanKnopf { art, code in
                if art == "klasse" { klassenEingabe = code } else { codeEingabe = code }
            }
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Theme.gelb)

            GelberKnopf(titel: "Weiter") {
                familienCode = Familiencode.bereinigt(codeEingabe)
                klassenCode = Familiencode.bereinigt(klassenEingabe)
                modus = "kind"
            }
            .disabled(!gueltig)
            .opacity(gueltig ? 1 : 0.4)

            Button("Ohne Code starten") { modus = "kind" }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.gelb)
            Button("Zurück") { schritt = 0 }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSanft)
        }
    }

    private func codeFeld(_ titel: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titel)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.gelb)
            TextField("XXXXX-XXXXX", text: text)
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(16)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onChange(of: text.wrappedValue) {
                    let b = Familiencode.bereinigt(text.wrappedValue)
                    if b != text.wrappedValue { text.wrappedValue = b }
                }
        }
    }

    // MARK: Eltern

    @ViewBuilder
    private var elternSchritt: some View {
        VStack(spacing: 16) {
            Text("Euer Familiencode")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text(neuerCode)
                .font(.system(size: 34, weight: .black, design: .monospaced))
                .foregroundStyle(Theme.gelb)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .glasKarte(radius: 24)
            Text("Gib diesen Code auf dem Gerät deines Kindes ein. Nur damit gehören die Ergebnisse zu euch.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)

            ShareLink(item: Nachricht.familiencode(neuerCode)) {
                Label("Code teilen", systemImage: "square.and.arrow.up")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.gelb)
            }

            GelberKnopf(titel: "Fertig") {
                familienCode = neuerCode
                modus = "eltern"
            }
            Button("Ich habe schon einen Code") {
                codeEingabe = ""
                schritt = 3
            }
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Theme.gelb)
            Button("Zurück") { schritt = 0 }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSanft)
        }
    }

    // MARK: Zweites Elternteil

    @ViewBuilder
    private var elternBeitreten: some View {
        let gueltig = Familiencode.istGueltig(codeEingabe)
        VStack(spacing: 16) {
            Text("Code vom anderen Elternteil")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("Gib den Familiencode ein, den das andere Eltern-Gerät anzeigt. Dann siehst du dieselben Ergebnisse.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)

            TextField("XXXXX-XXXXX", text: $codeEingabe)
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(16)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onChange(of: codeEingabe) {
                    let b = Familiencode.bereinigt(codeEingabe)
                    if b != codeEingabe { codeEingabe = b }
                }

            QRScanKnopf { art, code in
                if art == "familie" { codeEingabe = code }
            }
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Theme.gelb)

            GelberKnopf(titel: "Verbinden") {
                familienCode = Familiencode.bereinigt(codeEingabe)
                modus = "eltern"
            }
            .disabled(!gueltig)
            .opacity(gueltig ? 1 : 0.4)

            Button("Zurück") { schritt = 2 }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSanft)
        }
    }
}
