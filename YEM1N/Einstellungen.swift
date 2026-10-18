import SwiftUI
import SwiftData

// ============================================================
// MARK: - Einstellungen
// Eine Startseite mit klar sortierten Gruppen. Jede Gruppe öffnet eine eigene
// kleine Seite. Technik wie Cloud-Diagnose oder Gerätemodus liegt gesammelt
// unter "Für Fortgeschrittene", damit im Alltag niemand aus Versehen darauf tippt.
// ============================================================

/// Einstellungen als eigenes Fenster (mit "Fertig") oder als Reiter.
struct EinstellungenView: View {
    @Environment(\.dismiss) private var dismiss
    let eingebettet: Bool

    init(eingebettet: Bool = false) {
        self.eingebettet = eingebettet
    }

    var body: some View {
        NavigationStack {
            EinstellungenInhalt(alsReiter: eingebettet)
                .toolbar {
                    if !eingebettet {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Fertig") { dismiss() }
                        }
                    }
                }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }
}

/// Die Startseite der Einstellungen ohne eigenen Navigationsrahmen.
/// So lässt sie sich auch aus einem anderen Bereich heraus öffnen, zum Beispiel aus "Ich".
struct EinstellungenInhalt: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""
    @AppStorage("klassenCode") private var klassenCode = ""
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @AppStorage("farbwelt") private var farbwelt = "blau"
    @AppStorage("spieleErlaubt") private var spieleErlaubt = true
    @AppStorage("lernzeitAn") private var lernzeitAn = false
    var alsReiter = false

    private var eltern: Bool { modus == "eltern" }

    private var titel: String {
        if eltern { return "Eltern-Gerät" }
        return kindName.isEmpty ? "Kind-Gerät" : kindName
    }

    private var chips: [HeroChip] {
        var c: [HeroChip] = []
        c.append(HeroChip(text: Familiencode.istGueltig(familienCode) ? "👨‍👩‍👧 Familie verbunden" : "Ohne Familie",
                          hervorgehoben: Familiencode.istGueltig(familienCode)))
        if !eltern && !kindKlasse.isEmpty { c.append(HeroChip(text: kindKlasse)) }
        return c
    }

    var body: some View {
        HeroSeite {
            HeroKopf(kicker: "Einstellungen", titel: titel,
                     untertitel: eltern ? "Familie, Aufgaben und alles fürs Eltern-Gerät"
                                        : "Hier stellst du dein YEM1N ein",
                     bild: eltern ? "🧑‍🏫" : "⚙️", chips: chips)

            AbschnittsTitel("Ich")
            ZeilenGruppe {
                zeile(symbol: "person.crop.circle.fill", titel: "Profil",
                      text: eltern ? "Unter welchem Namen du Joker-Tipps schickst"
                                   : "Name, Klasse und Tagesziel") { ProfilEinstellungen() }
            }

            AbschnittsTitel("Familie und Klasse")
            ZeilenGruppe {
                zeile(symbol: "person.2.fill", titel: "Familiencode",
                      text: Familiencode.istGueltig(familienCode) ? familienCode : "Noch nicht verbunden",
                      farbe: Theme.mint) { FamilienEinstellungen() }
                ZeilenTrenner()
                zeile(symbol: "building.columns.fill", titel: "Klassencode",
                      text: klassenCode.isEmpty ? "Aufgaben von der Klasse bekommen" : klassenCode,
                      farbe: Theme.mint) { KlassenEinstellungen() }
            }

            AbschnittsTitel("Lernen und Spielen")
            ZeilenGruppe {
                zeile(symbol: "gamecontroller.fill", titel: "Spiele und Lernzeit",
                      text: spieleText, farbe: Theme.himmel) { LernzeitEinstellungen() }
                ZeilenTrenner()
                zeile(symbol: "globe", titel: "Sprachen", text: "Welche Sprachen erscheinen",
                      farbe: Theme.himmel) { SprachenEinstellungen() }
                ZeilenTrenner()
                zeile(symbol: "speaker.wave.2.fill", titel: "Vorlese-Stimmen",
                      text: "Stimme wählen und bessere Stimmen laden", farbe: Theme.himmel) { StimmenView() }
            }

            if eltern {
                AbschnittsTitel("Aufgaben")
                ZeilenGruppe {
                    zeile(symbol: "icloud.and.arrow.up.fill", titel: "Aufgaben verteilen",
                          text: "Klassenarbeiten an die Kind-Geräte schicken") { PaketeView() }
                }
            }

            AbschnittsTitel("Aussehen")
            ZeilenGruppe {
                zeile(symbol: "paintpalette.fill", titel: "Farben und Darstellung",
                      text: farbwelt == "rosa" ? "Rosa" : "Blau und Gelb") { AussehenEinstellungen() }
            }

            AbschnittsTitel("Hilfe und Rechtliches")
            ZeilenGruppe {
                zeile(symbol: "book.fill", titel: "Anleitung, Info und Feedback",
                      text: "So funktioniert YEM1N") { InfoView() }
                ZeilenTrenner()
                zeile(symbol: "hand.raised.fill", titel: "Datenschutz",
                      text: "Hinweise, Impressum, Daten löschen", farbe: Theme.koralle) { RechtlichesEinstellungen() }
            }

            AbschnittsTitel("Für Fortgeschrittene", text: "Technik und Fehlersuche. Im Alltag brauchst du das nicht.")
            ZeilenGruppe {
                zeile(symbol: "wrench.and.screwdriver.fill", titel: "Technik",
                      text: "Cloud prüfen, Einrichtung, Gerätemodus",
                      farbe: Color.white.opacity(0.75)) { FortgeschrittenEinstellungen() }
            }

            Text("Version \(AppInfo.version) (\(AppInfo.build))")
                .font(Schrift.zeilenText)
                .foregroundStyle(Theme.textSanft)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(alsReiter ? .hidden : .visible, for: .navigationBar)
    }

    private var spieleText: String {
        let spiele = spieleErlaubt ? "Spiele an" : "Spiele aus"
        return spiele + (lernzeitAn ? ", Erinnerung an" : "")
    }

    private func zeile<Ziel: View>(symbol: String, titel: String, text: String = "",
                                   farbe: Color = Theme.gelb,
                                   @ViewBuilder ziel: @escaping () -> Ziel) -> some View {
        NavigationLink {
            ziel()
        } label: {
            EinstellungsZeile(symbol: symbol, titel: titel, text: text, farbe: farbe)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rahmen für die Unterseiten

/// Gemeinsamer Rahmen: dunkler Hintergrund und eine Liste im Stil der App.
struct EinstellungsSeite<Inhalt: View>: View {
    let titel: String
    @ViewBuilder var inhalt: () -> Inhalt

    var body: some View {
        ZStack {
            HintergrundView()
            Form {
                inhalt()
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(titel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

private let zeilenGrund = Color.white.opacity(0.08)

// MARK: Profil

struct ProfilEinstellungen: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @AppStorage("tagesziel") private var tagesziel = 2
    @AppStorage("jokerIch") private var jokerIch = ""
    @State private var nameEntwurf = ""
    @FocusState private var fokus: Bool

    var body: some View {
        EinstellungsSeite(titel: "Profil") {
            if modus == "eltern" {
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
                } footer: {
                    Text("Unter diesem Namen erscheinen deine Antworten auf Joker-Fragen. Weitere Namen legst du im Reiter Joker an.")
                }
                .listRowBackground(zeilenGrund)
            } else {
                Section {
                    TextField("Name, zum Beispiel Yemin", text: $nameEntwurf)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .focused($fokus)
                    Picker("Klasse", selection: $kindKlasse) {
                        Text("Alle").tag("")
                        ForEach(ProfilDaten.klassen, id: \.self) { k in Text(k).tag(k) }
                    }
                    Stepper("Tagesziel: \(tagesziel) \(tagesziel == 1 ? "Runde" : "Runden")",
                            value: $tagesziel, in: 1...10)
                } footer: {
                    Text("Der Name erscheint bei den Eltern und in der App. Ein Vorname oder Spitzname reicht, bitte keinen Nachnamen. Mit einer Klasse lädt das Gerät nur passende Aufgabenpakete, bei Alle bekommt es alle.")
                }
                .listRowBackground(zeilenGrund)
            }
        }
        .onAppear { nameEntwurf = kindName }
        .onChange(of: fokus) { sichereName() }
        .onDisappear { sichereName() }
    }

    private func sichereName() {
        guard modus != "eltern" else { return }
        kindName = nameEntwurf.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: Familiencode

struct FamilienEinstellungen: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""
    @State private var codeEingabe = ""
    @State private var zeigeQR = false

    var body: some View {
        EinstellungsSeite(titel: "Familiencode") {
            if modus == "eltern" {
                Section {
                    Text(familienCode.isEmpty ? "Noch keiner" : familienCode)
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                        .foregroundStyle(Theme.gelb)
                    if !familienCode.isEmpty {
                        ShareLink(item: Nachricht.familiencode(familienCode)) {
                            Label("Code teilen", systemImage: "square.and.arrow.up")
                        }
                        Button { zeigeQR = true } label: {
                            Label("QR-Code für das Kind zeigen", systemImage: "qrcode")
                        }
                    }
                    Button("Neuen Code erzeugen") { familienCode = Familiencode.neu() }
                } header: {
                    Text("Dein Code")
                } footer: {
                    Text("Mit diesem Code verbinden sich Kind-Geräte und das andere Elternteil mit deiner Familie.")
                }
                .listRowBackground(zeilenGrund)
            }
            Section {
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
            } header: {
                Text(modus == "eltern" ? "Vorhandenen Code übernehmen" : "Code eintragen")
            } footer: {
                Text(modus == "eltern"
                     ? "Zum Beispiel den Code vom anderen Elternteil."
                     : "Den Code bekommst du von deinen Eltern. Damit sehen sie deine Ergebnisse und können dir bei Jokern helfen.")
            }
            .listRowBackground(zeilenGrund)
        }
        .sheet(isPresented: $zeigeQR) {
            QRAnzeigeSheet(titel: "Familiencode", art: "familie", code: familienCode,
                           hinweis: "Nur dem Kind oder dem anderen Elternteil zeigen. Wer diesen Code scannt, sieht die Ergebnisse und Joker der Familie.")
        }
        .onAppear { codeEingabe = familienCode }
    }
}

// MARK: Klassencode

struct KlassenEinstellungen: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("klassenCode") private var klassenCode = ""
    @State private var klassenEingabe = ""
    @State private var klassenAdmin = false
    @State private var schluesselPasst: Bool? = nil
    @State private var info = ""
    @State private var zeigeQR = false

    var body: some View {
        EinstellungsSeite(titel: "Klassencode") {
            if modus == "eltern" {
                Section {
                    Text(klassenCode.isEmpty ? "Noch keiner" : klassenCode)
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(Theme.gelb)
                    if !klassenCode.isEmpty {
                        Button { zeigeQR = true } label: {
                            Label("QR-Code für die Klasse zeigen", systemImage: "qrcode")
                        }
                        ShareLink(item: "📚 YEM1N Klassencode: \(klassenCode)\nIn der App unter Einstellungen > Klassencode eintragen, dann erscheinen die Aufgaben der Klasse automatisch.") {
                            Label("Klassencode teilen", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button("Neuen Klassencode erzeugen") { erzeugeNeu() }
                    if klassenAdmin && schluesselPasst == false {
                        Text("Achtung: Der Schlüssel in der Cloud passt nicht zu diesem Gerät. Klassen-Geräte lehnen deine Pakete deshalb ab. Wurde der Code auf einem anderen Gerät zum Admin gemacht? Dann von dort senden oder einen neuen Klassencode erzeugen.")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.koralle)
                    }
                    if !klassenCode.isEmpty {
                        Label(klassenAdmin ? "Dieses Gerät ist Admin" : "Nur Lesen, kein Admin-Schlüssel",
                              systemImage: klassenAdmin ? "checkmark.seal.fill" : "lock.fill")
                            .font(.footnote)
                            .foregroundStyle(klassenAdmin ? Theme.mint : Theme.textSanft)
                    }
                    if !klassenCode.isEmpty && !klassenAdmin {
                        Button("Admin dieses Klassencodes werden") { werdeAdmin() }
                    }
                } header: {
                    Text("Code der Klasse")
                }
                .listRowBackground(zeilenGrund)
            }
            Section {
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
                if !info.isEmpty {
                    Text(info).font(.footnote).foregroundStyle(Theme.textSanft)
                }
            } header: {
                Text("Code eintragen")
            } footer: {
                Text("Über den Klassencode kommen nur Aufgabenpakete an, vom Admin digital unterschrieben. Ergebnisse und Joker bleiben in der Familie.")
            }
            .listRowBackground(zeilenGrund)
        }
        .sheet(isPresented: $zeigeQR) {
            QRAnzeigeSheet(titel: "Klassencode", art: "klasse", code: klassenCode,
                           hinweis: "Über diesen Code kommen nur Aufgabenpakete an. Ergebnisse und Joker bleiben in der Familie.")
        }
        .task {
            klassenEingabe = klassenCode
            klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode)
            schluesselPasst = klassenCode.isEmpty ? nil : await Klassensiegel.adminPasstZurCloud("K-" + klassenCode)
        }
        .onChange(of: klassenCode) { klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode) }
    }

    private func erzeugeNeu() {
        let neu = Familiencode.neu()
        Task {
            do {
                try await CloudDienst.erzeugeKlassenSchluessel("K-" + neu)
                klassenCode = neu
                klassenEingabe = neu
                info = "Klassencode angelegt. Dieses Gerät ist jetzt Admin der Klasse."
            } catch {
                info = "Anlegen nicht möglich: \(CloudDienst.fehlertext(error))"
            }
            klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode)
        }
    }

    private func werdeAdmin() {
        Task {
            do {
                try await CloudDienst.erzeugeKlassenSchluessel("K-" + klassenCode)
                info = "Dieses Gerät ist jetzt Admin."
            } catch {
                info = "Nicht möglich, der Code gehört schon einem anderen Gerät."
            }
            klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode)
        }
    }
}

// MARK: Spiele und Lernzeit

struct LernzeitEinstellungen: View {
    @AppStorage("spieleErlaubt") private var spieleErlaubt = true
    @AppStorage("spieleProTag") private var spieleProTag = 3
    @AppStorage("lernzeitAn") private var lernzeitAn = false
    @AppStorage("lernzeitMinuten") private var lernzeitMinuten = 16 * 60

    private var uhrzeit: Binding<Date> {
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
        EinstellungsSeite(titel: "Spiele und Lernzeit") {
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
            .listRowBackground(zeilenGrund)

            Section {
                Toggle("Täglich erinnern", isOn: $lernzeitAn)
                    .tint(Theme.gelb)
                if lernzeitAn {
                    DatePicker("Uhrzeit", selection: uhrzeit, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Lernzeit")
            } footer: {
                Text("Eine Mitteilung erinnert dieses Gerät jeden Tag ans Üben. Eltern können sie auf dem Kind-Gerät einstellen.")
            }
            .listRowBackground(zeilenGrund)
        }
        .onChange(of: lernzeitAn) { Lernzeit.planen(an: lernzeitAn, minuten: lernzeitMinuten) }
        .onChange(of: lernzeitMinuten) { Lernzeit.planen(an: lernzeitAn, minuten: lernzeitMinuten) }
    }
}

// MARK: Sprachen

struct SprachenEinstellungen: View {
    var body: some View {
        EinstellungsSeite(titel: "Sprachen") {
            Section {
                SprachWahlSchalter()
            } footer: {
                Text("Nur die angehakten Sprachen erscheinen im Bereich Sprachen. Sind alle aus, verschwindet der Bereich auf dem Kind-Gerät.")
            }
            .listRowBackground(zeilenGrund)
        }
    }
}

// MARK: Aussehen

struct AussehenEinstellungen: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("farbwelt") private var farbwelt = "blau"
    @AppStorage("glasEffekt") private var glas = false
    @AppStorage("vorschulTab") private var vorschulKind = true

    var body: some View {
        EinstellungsSeite(titel: "Farben und Darstellung") {
            Section {
                HStack(spacing: 12) {
                    farbKnopf(wert: "blau", name: "Blau und Gelb",
                              oben: Color(red: 0.0, green: 0.125, blue: 0.357),
                              akzent: Color(red: 1.0, green: 0.93, blue: 0.0))
                    farbKnopf(wert: "rosa", name: "Rosa",
                              oben: Color(red: 0.36, green: 0.07, blue: 0.31),
                              akzent: Color(red: 1.0, green: 0.45, blue: 0.74))
                }
                .padding(.vertical, 6)
            } header: {
                Text("Farbwelt")
            }
            .listRowBackground(zeilenGrund)

            Section {
                Toggle("Glas-Effekte", isOn: $glas)
                    .tint(Theme.gelb)
                if modus != "eltern" {
                    Toggle("Reiter Vorschule anzeigen", isOn: $vorschulKind)
                        .tint(Theme.gelb)
                }
            } header: {
                Text("Darstellung")
            } footer: {
                Text(modus == "eltern"
                     ? "Glas-Effekte aus macht die App auf älteren iPhones flüssiger. Die Vorschule findest du im Reiter Lernen."
                     : "Glas-Effekte aus macht die App auf älteren iPhones flüssiger. Das Aussehen wird dann etwas flacher.")
            }
            .listRowBackground(zeilenGrund)
        }
    }

    private func farbKnopf(wert: String, name: String, oben: Color, akzent: Color) -> some View {
        let aktiv = farbwelt == wert
        return Button {
            Theme.rosa = (wert == "rosa")
            farbwelt = wert
            Haptik.leicht()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [oben, oben.opacity(0.6)],
                                             startPoint: .top, endPoint: .bottom))
                    Circle().fill(akzent).frame(width: 34, height: 34)
                }
                .frame(height: 76)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(aktiv ? akzent : Color.white.opacity(0.15), lineWidth: aktiv ? 3 : 1))
                Text(name)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Image(systemName: aktiv ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(aktiv ? akzent : Color.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(TastenStil())
    }
}

// MARK: Datenschutz und Rechtliches

struct RechtlichesEinstellungen: View {
    @AppStorage("familienCode") private var familienCode = ""
    @AppStorage(Einwilligung.versionKey) private var einwilligungVersion = 0
    @State private var zeigeLoeschen = false
    @State private var zeigeWiderruf = false
    @State private var info = ""

    var body: some View {
        EinstellungsSeite(titel: "Datenschutz") {
            Section {
                NavigationLink { DatenschutzView() } label: {
                    Label("Datenschutzhinweise", systemImage: "hand.raised.fill")
                }
                NavigationLink { ImpressumView() } label: {
                    Label("Impressum", systemImage: "person.text.rectangle")
                }
                NavigationLink { BetaHinweisView() } label: {
                    Label("Beta und Haftung", systemImage: "exclamationmark.shield")
                }
            } header: {
                Text("Zum Nachlesen")
            }
            .listRowBackground(zeilenGrund)

            Section {
                Text("Einwilligung: \(Einwilligung.datumText(Einwilligung.datum()))")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
                Button("Meine Cloud-Daten löschen", role: .destructive) { zeigeLoeschen = true }
                Button("Einwilligung widerrufen", role: .destructive) { zeigeWiderruf = true }
                if !info.isEmpty {
                    Text(info).font(.footnote).foregroundStyle(Theme.textSanft)
                }
            } header: {
                Text("Deine Daten")
            } footer: {
                Text("Löscht die Cloud-Einträge des Familiencodes, die dieses Gerät angelegt hat. Auf jedem Gerät der Familie einmal ausführen. Cloud-Einträge löscht die App nach 12 Monaten außerdem selbst.")
            }
            .listRowBackground(zeilenGrund)
        }
        .confirmationDialog("Cloud-Daten wirklich löschen?", isPresented: $zeigeLoeschen,
                            titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                guard Familiencode.istGueltig(familienCode) else {
                    info = "Es ist kein Familiencode eingetragen."
                    return
                }
                info = "Wird gelöscht ..."
                Task {
                    let n = await CloudDienst.loescheEigeneDaten(code: familienCode)
                    info = "\(n) Einträge in der Cloud gelöscht."
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Entfernt die Cloud-Einträge dieses Familiencodes, die dieses Gerät angelegt hat. Ergebnisse auf dem Gerät bleiben.")
        }
        .confirmationDialog("Einwilligung widerrufen?", isPresented: $zeigeWiderruf,
                            titleVisibility: .visible) {
            Button("Widerrufen und Cloud-Daten löschen", role: .destructive) {
                let code = familienCode
                Task {
                    if Familiencode.istGueltig(code) {
                        _ = await CloudDienst.loescheEigeneDaten(code: code)
                    }
                    familienCode = ""
                    Einwilligung.widerrufen()
                    einwilligungVersion = 0
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Die App löscht die Cloud-Einträge, die dieses Gerät angelegt hat, und trennt den Familiencode. Danach fragt sie neu nach der Einwilligung. Ergebnisse auf dem Gerät bleiben.")
        }
    }
}

// MARK: Für Fortgeschrittene

struct FortgeschrittenEinstellungen: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("profilFertig") private var profilFertig = true
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle == "lokal" && $0.gesendet == false })
    private var offene: [RundenErgebnis]
    @State private var zeigeReset = false

    var body: some View {
        EinstellungsSeite(titel: "Technik") {
            Section {
                NavigationLink { CloudDiagnoseView() } label: {
                    Label("Cloud-Diagnose", systemImage: "icloud")
                }
            } header: {
                Text("Cloud")
            } footer: {
                Text("Verbindung testen, Mitteilungen prüfen und die Cloud neu einrichten.")
            }
            .listRowBackground(zeilenGrund)

            if modus != "eltern" {
                Section {
                    Label("Noch nicht gesendet: \(offene.count)", systemImage: "tray.full")
                } header: {
                    Text("Ergebnisse")
                } footer: {
                    Text("Ergebnisse werden automatisch an die Eltern gesendet, sobald das Gerät online ist und ein Familiencode eingetragen ist.")
                }
                .listRowBackground(zeilenGrund)
            }

            Section {
                Button("Einrichtung noch einmal ansehen") { profilFertig = false }
                Button("Gerätemodus ändern (Kind oder Eltern)", role: .destructive) {
                    zeigeReset = true
                }
            } header: {
                Text("Gerät")
            } footer: {
                Text("Beim Gerätemodus erscheint wieder die Auswahl Kind oder Eltern. Familiencode, Klassenarbeiten und Fortschritt bleiben erhalten.")
            }
            .listRowBackground(zeilenGrund)

            Section {
                LabeledContent("Version", value: "\(AppInfo.version) (\(AppInfo.build))")
            }
            .listRowBackground(zeilenGrund)
        }
        .confirmationDialog("Gerätemodus wirklich ändern?", isPresented: $zeigeReset,
                            titleVisibility: .visible) {
            Button("Ändern", role: .destructive) { modus = "" }
            Button("Abbrechen", role: .cancel) {}
        }
    }
}
