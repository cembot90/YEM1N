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

// MARK: - Einstellungen

struct EinstellungenView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle == "lokal" && $0.gesendet == false })
    private var offene: [RundenErgebnis]
    @State private var codeEingabe = ""
    @State private var zeigeReset = false
    @AppStorage("glasEffekt") private var glas = false
    @AppStorage("farbwelt") private var farbwelt = "blau"
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @AppStorage("tagesziel") private var tagesziel = 2
    @AppStorage("klassenCode") private var klassenCode = ""
    @AppStorage("vorschulTab") private var vorschulKind = true
    @AppStorage("vorschulTabEltern") private var vorschulEltern = false
    @AppStorage("jokerIch") private var jokerIch = ""
    @AppStorage("profilFertig") private var profilFertig = true
    @AppStorage("spieleErlaubt") private var spieleErlaubt = true
    @AppStorage("spieleProTag") private var spieleProTag = 3
    @AppStorage("lernzeitAn") private var lernzeitAn = false
    @AppStorage("lernzeitMinuten") private var lernzeitMinuten = 16 * 60
    @State private var zeigeFamilienQR = false
    @State private var zeigeKlassenQR = false
    @State private var klassenEingabe = ""
    @State private var klassenAdmin = false
    @State private var klassenInfo = ""
    @State private var zeigeLoeschen = false
    @State private var datenInfo = ""
    @State private var kindNameEntwurf = ""
    @FocusState private var fokus: String?
    let eingebettet: Bool

    init(eingebettet: Bool = false) {
        self.eingebettet = eingebettet
    }

    private let zeile = Color.white.opacity(0.08)

    private var lernzeitBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: lernzeitMinuten / 60,
                                      minute: lernzeitMinuten % 60,
                                      second: 0, of: Date()) ?? Date()
            },
            set: {
                let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
                lernzeitMinuten = (c.hour ?? 16) * 60 + (c.minute ?? 0)
            })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                Form {
                    Section("Dieses Gerät") {
                        Label(modus == "eltern" ? "Eltern-Gerät" : "Kind-Gerät",
                              systemImage: modus == "eltern" ? "bell.badge.fill" : "graduationcap.fill")
                    }
                    .listRowBackground(zeile)

                    Section("Familiencode") {
                        if modus == "eltern" {
                            Text(familienCode.isEmpty ? "Noch keiner" : familienCode)
                                .font(.system(.title2, design: .monospaced).weight(.bold))
                                .foregroundStyle(Theme.gelb)
                            if !familienCode.isEmpty {
                                ShareLink(item: Nachricht.familiencode(familienCode)) {
                                    Label("Code teilen", systemImage: "square.and.arrow.up")
                                }
                                Button { zeigeFamilienQR = true } label: {
                                    Label("QR-Code für das Kind zeigen", systemImage: "qrcode")
                                }
                                .sheet(isPresented: $zeigeFamilienQR) {
                                    QRAnzeigeSheet(titel: "Familiencode", art: "familie", code: familienCode,
                                                   hinweis: "Nur dem Kind oder dem anderen Elternteil zeigen. Wer diesen Code scannt, sieht die Ergebnisse und Joker der Familie.")
                                }
                            }
                            Button("Neuen Code erzeugen") { familienCode = Familiencode.neu() }
                            Text("Oder einen vorhandenen Code übernehmen, zum Beispiel vom anderen Elternteil:")
                                .font(.footnote)
                                .foregroundStyle(Theme.textSanft)
                        }
                        TextField("XXXXX-XXXXX", text: $codeEingabe)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: codeEingabe) {
                                let b = Familiencode.bereinigt(codeEingabe)
                                if b != codeEingabe { codeEingabe = b }
                            }
                        QRScanKnopf { art, code in
                            if art == "familie" { codeEingabe = code }
                        }
                        Button("Code speichern") {
                            familienCode = Familiencode.bereinigt(codeEingabe)
                        }
                        .disabled(!Familiencode.istGueltig(codeEingabe) || codeEingabe == familienCode)
                    }
                    .listRowBackground(zeile)

                    Section {
                        if modus == "eltern" {
                            Text(klassenCode.isEmpty ? "Noch keiner" : klassenCode)
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .foregroundStyle(Theme.gelb)
                            if !klassenCode.isEmpty {
                                Button { zeigeKlassenQR = true } label: {
                                    Label("QR-Code für die Klasse zeigen", systemImage: "qrcode")
                                }
                                .sheet(isPresented: $zeigeKlassenQR) {
                                    QRAnzeigeSheet(titel: "Klassencode", art: "klasse", code: klassenCode,
                                                   hinweis: "Über diesen Code kommen nur Aufgabenpakete an. Ergebnisse und Joker bleiben in der Familie.")
                                }
                                ShareLink(item: "📚 YEM1N Klassencode: \(klassenCode)\nIn der App unter Einstellungen > Klassencode eintragen, dann erscheinen die Aufgaben der Klasse automatisch.") {
                                    Label("Klassencode teilen", systemImage: "square.and.arrow.up")
                                }
                            }
                            Button("Neuen Klassencode erzeugen") {
                                let neu = Familiencode.neu()
                                Task {
                                    do {
                                        try await CloudDienst.erzeugeKlassenSchluessel("K-" + neu)
                                        klassenCode = neu
                                        klassenInfo = "Klassencode angelegt. Dieses Gerät ist jetzt Admin der Klasse."
                                    } catch {
                                        klassenInfo = "Anlegen nicht möglich: \(CloudDienst.fehlertext(error))"
                                    }
                                    klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode)
                                }
                            }
                            if !klassenCode.isEmpty {
                                Label(klassenAdmin ? "Dieses Gerät ist Admin" : "Nur Lesen, kein Admin-Schlüssel",
                                      systemImage: klassenAdmin ? "checkmark.seal.fill" : "lock.fill")
                                    .font(.footnote)
                                    .foregroundStyle(klassenAdmin ? Theme.mint : Theme.textSanft)
                            }
                            if !klassenCode.isEmpty && !klassenAdmin {
                                Button("Admin dieses Klassencodes werden") {
                                    Task {
                                        do {
                                            try await CloudDienst.erzeugeKlassenSchluessel("K-" + klassenCode)
                                            klassenInfo = "Dieses Gerät ist jetzt Admin."
                                        } catch {
                                            klassenInfo = "Nicht möglich, der Code gehört schon einem anderen Gerät."
                                        }
                                        klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode)
                                    }
                                }
                            }
                        }
                        TextField("Klassencode, XXXXX-XXXXX", text: $klassenEingabe)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: klassenEingabe) {
                                let b = Familiencode.bereinigt(klassenEingabe)
                                if b != klassenEingabe { klassenEingabe = b }
                            }
                        QRScanKnopf { art, code in
                            if art == "klasse" { klassenEingabe = code }
                        }
                        Button("Klassencode speichern") {
                            klassenCode = Familiencode.bereinigt(klassenEingabe)
                            klassenEingabe = klassenCode
                        }
                        .disabled(!Familiencode.istGueltig(klassenEingabe) || klassenEingabe == klassenCode)
                        if !klassenCode.isEmpty && modus != "eltern" {
                            Button("Klassencode entfernen", role: .destructive) {
                                UserDefaults.standard.removeObject(forKey: "klassenPin-K-" + klassenCode)
                                klassenCode = ""
                                klassenEingabe = ""
                            }
                        }
                        if !klassenInfo.isEmpty {
                            Text(klassenInfo).font(.footnote).foregroundStyle(Theme.textSanft)
                        }
                    } header: {
                        Text("Klassencode (nur Aufgaben)")
                    } footer: {
                        Text("Über den Klassencode kommen nur Aufgabenpakete an, vom Admin digital unterschrieben. Ergebnisse und Joker bleiben in der Familie.")
                    }
                    .task { klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode) }
                    .onChange(of: klassenCode) { klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode) }
                    .listRowBackground(zeile)

                    Section {
                        Toggle("Spiele erlauben", isOn: $spieleErlaubt)
                            .tint(Theme.gelb)
                        if spieleErlaubt {
                            Stepper("Höchstens \(spieleProTag) Spiele pro Tag", value: $spieleProTag, in: 1...10)
                        }
                    } header: {
                        Text("Spiele")
                    } footer: {
                        Text("Münzen gibt es für richtig gelöste Aufgaben, nicht für angeschaute Lösungen. Gespielt werden darf erst, wenn an diesem Tag schon eine Übung geschafft wurde.")
                    }
                    .listRowBackground(zeile)

                    Section {
                        Toggle("Täglich erinnern", isOn: $lernzeitAn)
                            .tint(Theme.gelb)
                        if lernzeitAn {
                            DatePicker("Uhrzeit", selection: lernzeitBinding, displayedComponents: .hourAndMinute)
                        }
                    } header: {
                        Text("Lernzeit")
                    } footer: {
                        Text("Eine Mitteilung erinnert dieses Gerät jeden Tag ans Üben. Eltern können sie auf dem Kind-Gerät einstellen.")
                    }
                    .listRowBackground(zeile)
                    .onChange(of: lernzeitAn) { Lernzeit.planen(an: lernzeitAn, minuten: lernzeitMinuten) }
                    .onChange(of: lernzeitMinuten) { Lernzeit.planen(an: lernzeitAn, minuten: lernzeitMinuten) }

                    Section {
                        NavigationLink { DatenschutzView() } label: {
                            Label("Datenschutzhinweise", systemImage: "hand.raised.fill")
                        }
                        Button("Meine Cloud-Daten löschen", role: .destructive) { zeigeLoeschen = true }
                        if !datenInfo.isEmpty {
                            Text(datenInfo).font(.footnote).foregroundStyle(Theme.textSanft)
                        }
                    } header: {
                        Text("Datenschutz")
                    } footer: {
                        Text("Löscht die Cloud-Einträge des Familiencodes, die dieses Gerät angelegt hat. Auf jedem Gerät der Familie einmal ausführen.")
                    }
                    .listRowBackground(zeile)

                    if modus != "eltern" {
                        Section {
                            Label("Noch nicht gesendet: \(offene.count)", systemImage: "tray.full")
                            Text("Ergebnisse werden automatisch an die Eltern gesendet, sobald das Gerät online ist und ein Familiencode eingetragen ist.")
                                .font(.footnote)
                                .foregroundStyle(Theme.textSanft)
                        } header: {
                            Text("Ergebnisse")
                        }
                        .listRowBackground(zeile)
                    }

                    if modus == "eltern" {
                        Section {
                            NavigationLink { PaketeView() } label: {
                                Label("Aufgaben per Cloud verteilen", systemImage: "icloud.and.arrow.up")
                            }
                        } footer: {
                            Text("Klassenarbeiten und Übungssets hochladen. Die Kind-Geräte laden sie automatisch.")
                        }
                        .listRowBackground(zeile)
                    }

                    Section {
                        NavigationLink { CloudDiagnoseView() } label: {
                            Label("Cloud-Diagnose", systemImage: "icloud")
                        }
                    } footer: {
                        Text("Für Eltern: Verbindung testen und die Cloud neu einrichten.")
                    }
                    .listRowBackground(zeile)

                    if modus == "kind" {
                        Section {
                            TextField("Name, zum Beispiel Yemin", text: $kindNameEntwurf)
                                .focused($fokus, equals: "name")
                            Picker("Klasse", selection: $kindKlasse) {
                                Text("Alle").tag("")
                                ForEach(ProfilDaten.klassen, id: \.self) { k in Text(k).tag(k) }
                            }
                            Stepper("Tagesziel: \(tagesziel) \(tagesziel == 1 ? "Runde" : "Runden")",
                                    value: $tagesziel, in: 1...10)
                            Button("Einrichtung noch einmal ansehen") { profilFertig = false }
                        } header: {
                            Text("Profil")
                        } footer: {
                            Text("Der Name erscheint bei den Eltern und in der App. Mit einer Klasse lädt das Gerät nur passende Aufgabenpakete, bei Alle bekommt es alle.")
                        }
                        .listRowBackground(zeile)
                    } else if modus == "eltern" {
                        Section {
                            Picker("Ich bin", selection: Binding(
                                get: {
                                    jokerIch.isEmpty ? (JokerStand.shared.mitglieder.first?.id.uuidString ?? "") : jokerIch
                                },
                                set: { jokerIch = $0 })) {
                                ForEach(JokerStand.shared.mitglieder) { m in
                                    Text("\(m.emoji) \(m.name)").tag(m.id.uuidString)
                                }
                            }
                            Button("Einrichtung noch einmal ansehen") { profilFertig = false }
                        } header: {
                            Text("Profil")
                        } footer: {
                            Text("Unter diesem Namen erscheinen deine Antworten auf Joker-Fragen. Weitere Namen legst du im Tab Joker an.")
                        }
                        .listRowBackground(zeile)
                    }

                    Section {
                        Picker("Farbwelt", selection: Binding(get: { farbwelt },
                                                              set: { neu in
                            Theme.rosa = (neu == "rosa")
                            farbwelt = neu
                        })) {
                            Text("Blau und Gelb").tag("blau")
                            Text("Rosa").tag("rosa")
                        }
                        Toggle("Glas-Effekte", isOn: $glas)
                        if modus == "eltern" {
                            Toggle("Tab Vorschule anzeigen", isOn: $vorschulEltern)
                        } else {
                            Toggle("Tab Vorschule anzeigen", isOn: $vorschulKind)
                        }
                    } header: {
                        Text("Darstellung")
                    } footer: {
                        Text("Aus macht die App auf älteren iPhones flüssiger. Das Aussehen wird dann etwas flacher.")
                    }
                    .listRowBackground(zeile)

                    Section {
                        Button("Gerätemodus ändern (Kind oder Eltern)", role: .destructive) {
                            zeigeReset = true
                        }
                    } footer: {
                        Text("Danach erscheint wieder die Auswahl Kind oder Eltern. Familiencode, Klassenarbeiten und Fortschritt bleiben erhalten.")
                    }
                    .listRowBackground(zeile)

                    // Ganz unten, wie in den meisten Apps
                    Section {
                        NavigationLink { InfoView() } label: {
                            Label("Info, Anleitung und Feedback", systemImage: "info.circle.fill")
                        }
                    } footer: {
                        Text("Version \(AppInfo.version) (\(AppInfo.build))")
                    }
                    .listRowBackground(zeile)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !eingebettet {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fertig") { dismiss() }
                    }
                }
            }
            .confirmationDialog("Gerätemodus wirklich ändern?", isPresented: $zeigeReset,
                                titleVisibility: .visible) {
                Button("Ändern", role: .destructive) {
                    modus = ""
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            }
            .confirmationDialog("Cloud-Daten wirklich löschen?", isPresented: $zeigeLoeschen,
                                titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    guard Familiencode.istGueltig(familienCode) else {
                        datenInfo = "Es ist kein Familiencode eingetragen."
                        return
                    }
                    datenInfo = "Wird gelöscht ..."
                    Task {
                        let n = await CloudDienst.loescheEigeneDaten(code: familienCode)
                        datenInfo = "\(n) Einträge in der Cloud gelöscht."
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Entfernt die Cloud-Einträge dieses Familiencodes, die dieses Gerät angelegt hat. Ergebnisse auf dem Gerät bleiben.")
            }
            .onAppear {
                codeEingabe = familienCode
                klassenEingabe = klassenCode
                kindNameEntwurf = kindName
            }
            .onChange(of: fokus) {
                kindName = kindNameEntwurf.trimmingCharacters(in: .whitespaces)
            }
            .onDisappear {
                kindName = kindNameEntwurf.trimmingCharacters(in: .whitespaces)
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }
}
