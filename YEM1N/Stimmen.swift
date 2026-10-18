import SwiftUI
import UIKit
import AVFoundation

// MARK: Vorlese-Stimmen
// Auswahl der Stimme je Sprache und eine Anleitung, wie man bessere Stimmen lädt.
// Die Stimmen liegen auf dem Gerät selbst, deshalb gibt es das auf Kind- und Eltern-Geräten.

struct StimmSprache: Identifiable {
    let kurz: String
    let name: String
    let flagge: String
    let code: String
    var id: String { kurz }

    var probeSatz: String {
        switch kurz {
        case "de": return "Hallo! So klinge ich, wenn ich dir vorlese."
        case "tr": return "Merhaba! Sana böyle kitap okurum."
        case "en": return "Hello! This is how I sound when I read to you."
        case "it": return "Ciao! Così leggo per te."
        default: return "Hallo!"
        }
    }

    /// Deutsch immer, dazu die Lernsprachen aus dem Sprachkatalog.
    static var alle: [StimmSprache] {
        let store = SprachKatalogStore.shared
        var liste = [StimmSprache(kurz: "de", name: "Deutsch", flagge: "🇩🇪", code: "de-DE")]
        for c in store.katalog.lernsprachen where c != "de" {
            let info = store.sprache(c)
            liste.append(StimmSprache(kurz: c, name: info.name, flagge: info.flagge, code: info.sprachcode))
        }
        return liste
    }
}

enum StimmText {
    static func qualitaet(_ q: AVSpeechSynthesisVoiceQuality?) -> String {
        switch q {
        case .premium?: return "Premium"
        case .enhanced?: return "Erweitert"
        case nil: return "Fehlt"
        default: return "Einfach"
        }
    }

    static func farbe(_ q: AVSpeechSynthesisVoiceQuality?) -> Color {
        switch q {
        case .premium?, .enhanced?: return .green
        case nil: return .red
        default: return Theme.gelb
        }
    }

    static func geschlecht(_ v: AVSpeechSynthesisVoice) -> String {
        switch v.gender {
        case .female: return "Frau"
        case .male: return "Mann"
        default: return "Stimme"
        }
    }
}

/// Kurze Übersicht in den Sprach-Einstellungen, führt zur Auswahl.
struct StimmenKarte: View {
    @State private var stand = 0

    var body: some View {
        NavigationLink {
            StimmenView()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Vorlese-Stimmen")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Color.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.gelb)
                }
                ForEach(StimmSprache.alle) { s in
                    let v = Sprecher.shared.stimme(s.code)
                    HStack {
                        Text("\(s.flagge) \(s.name)").foregroundStyle(Color.white)
                        Spacer()
                        if NatuerlicheStimme.an, let p = GeraeteStimmen.shared.bereit(s.kurz) {
                            Text(p.name)
                                .foregroundStyle(Theme.textSanft)
                            Text("Natürlich")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.green)
                        } else {
                            if let v {
                                Text(v.name)
                                    .foregroundStyle(Theme.textSanft)
                            }
                            Text(StimmText.qualitaet(v?.quality))
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(StimmText.farbe(v?.quality))
                        }
                    }
                    .font(.subheadline)
                }
                .id(stand)
                Text("Natürliche Stimmen laden, Stimme wählen, Mann oder Frau")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glasKarte(radius: 22)
        }
        .buttonStyle(TastenStil())
        .onReceive(NotificationCenter.default.publisher(for: .stimmenGeladen)) { _ in
            stand += 1
        }
    }
}

/// Alle geladenen Stimmen je Sprache, mit Probehören und Auswahl.
struct StimmenView: View {
    @State private var stand = 0
    @State private var zeigeAnleitung = false
    @Environment(\.scenePhase) private var phase
    private let zeile = Color.white.opacity(0.08)

    var body: some View {
        ZStack {
            HintergrundView()
            Form {
                NatuerlicheStimmenAbschnitt(hintergrund: zeile)

                Section {
                    Button {
                        zeigeAnleitung = true
                    } label: {
                        Label("Bessere Stimme laden", systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Theme.gelb)
                    }
                } header: {
                    Text("iOS-Stimmen")
                } footer: {
                    Text("Die iOS-Stimmen lesen alles vor, wofür es keine natürliche Stimme gibt, zum Beispiel Englisch. Premium- und erweiterte Stimmen klingen viel natürlicher. Sie werden einmal auf dieses Gerät geladen und gehen dann auch ohne Internet.")
                }
                .listRowBackground(zeile)

                ForEach(StimmSprache.alle) { s in
                    abschnitt(s)
                }
            }
            .scrollContentBackground(.hidden)
            .id(stand)
        }
        .navigationTitle("Vorlese-Stimmen")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $zeigeAnleitung) { StimmenAnleitung() }
        .onReceive(NotificationCenter.default.publisher(for: .stimmenGeladen)) { _ in
            stand += 1
        }
        .onChange(of: phase) {
            // Zurück aus den iPhone-Einstellungen: Liste im Hintergrund neu laden.
            // Die Seite zeigt so lange den alten Stand und bleibt bedienbar.
            if phase == .active { Sprecher.shared.neuLaden() }
        }
    }

    private func abschnitt(_ s: StimmSprache) -> some View {
        let liste = Sprecher.shared.installierte(s.code)
        let gewaehlt = Sprecher.shared.gewaehlteID(s.code)
        let aktiv = Sprecher.shared.stimme(s.code)
        return Section {
            Button {
                Sprecher.shared.waehle(nil, fuer: s.code)
                if let v = Sprecher.shared.stimme(s.code) { Sprecher.shared.probe(s.probeSatz, stimme: v) }
                stand += 1
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automatisch").foregroundStyle(Color.white)
                        Text("Immer die beste geladene Stimme")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                    }
                    Spacer()
                    if gewaehlt.isEmpty || !liste.contains(where: { $0.identifier == gewaehlt }) {
                        Image(systemName: "checkmark").foregroundStyle(Theme.gelb)
                    }
                }
            }
            ForEach(liste, id: \.identifier) { v in
                Button {
                    Sprecher.shared.waehle(v, fuer: s.code)
                    Sprecher.shared.probe(s.probeSatz, stimme: v)
                    stand += 1
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(v.name).foregroundStyle(Color.white)
                            Text("\(StimmText.geschlecht(v)) · \(StimmText.qualitaet(v.quality))")
                                .font(.footnote)
                                .foregroundStyle(StimmText.farbe(v.quality))
                        }
                        Spacer()
                        if v.identifier == gewaehlt {
                            Image(systemName: "checkmark").foregroundStyle(Theme.gelb)
                        }
                    }
                }
            }
            if liste.isEmpty {
                Text("Für diese Sprache ist noch keine Stimme geladen.")
                    .foregroundStyle(Theme.textSanft)
            }
        } header: {
            Text("\(s.flagge) \(s.name)")
        } footer: {
            if let aktiv, aktiv.quality != .premium, aktiv.quality != .enhanced {
                Text("Jetzt liest \(aktiv.name) in einfacher Qualität vor. Mit „Bessere Stimme laden“ klingt es natürlicher.")
            } else {
                Text("Antippen wählt die Stimme und spielt eine Probe.")
            }
        }
        .listRowBackground(zeile)
    }
}

/// Schritt für Schritt zur besseren Stimme. Apple erlaubt keinen direkten Sprung
/// in die Stimmen-Einstellungen, deshalb öffnet der Knopf die Einstellungen-App.
struct StimmenAnleitung: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let schritte: [(String, String, String)] = [
        ("1", "gearshape.fill", "Die App „Einstellungen“ öffnen. Oben links auf „Einstellungen“ zurück, falls YEM1N offen ist."),
        ("2", "accessibility", "„Bedienungshilfen“ antippen, dann „Gesprochene Inhalte“."),
        ("3", "waveform", "„Stimmen“ antippen und die Sprache wählen, zum Beispiel Deutsch."),
        ("4", "icloud.and.arrow.down", "Eine Stimme antippen und bei „Premium“ oder „Erweitert“ auf die Wolke tippen. Am besten im WLAN, das sind einige hundert MB."),
        ("5", "arrow.uturn.backward", "Zurück zu YEM1N. Die neue Stimme erscheint von selbst und wird automatisch benutzt.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("So lädst du eine bessere Stimme")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        ForEach(schritte, id: \.0) { nr, symbol, text in
                            HStack(alignment: .top, spacing: 14) {
                                Text(nr)
                                    .font(.system(.title3, design: .rounded).weight(.black))
                                    .foregroundStyle(Theme.navy)
                                    .frame(width: 36, height: 36)
                                    .background(Theme.gelb, in: Circle())
                                VStack(alignment: .leading, spacing: 4) {
                                    Image(systemName: symbol)
                                        .foregroundStyle(Theme.gelb)
                                    Text(text)
                                        .font(.body)
                                        .foregroundStyle(Color.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .glasKarte(radius: 20)
                        }
                        Text("Nicht jede Stimme gibt es als Premium. Am natürlichsten klingen meist die Premium-Stimmen. Für Türkisch und Englisch geht es genauso, dort die jeweilige Sprache wählen.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        } label: {
                            Label("Einstellungen öffnen", systemImage: "gearshape.fill")
                                .font(.headline)
                                .foregroundStyle(Theme.navy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.gelb, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
