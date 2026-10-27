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
    private let familie = FamilienModell.shared
    @AppStorage("klassenCode") private var klassenCode = ""
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @AppStorage("farbwelt") private var farbwelt = "blau"
    @AppStorage("spieleErlaubt") private var spieleErlaubt = true
    @AppStorage("lernzeitAn") private var lernzeitAn = false
    @AppStorage(Sparmodus.key) private var sparmodus = false
    var alsReiter = false

    private var eltern: Bool { modus == "eltern" }

    private var titel: String {
        if eltern { return "Eltern-Gerät" }
        return kindName.isEmpty ? "Kind-Gerät" : kindName
    }

    private var chips: [HeroChip] {
        var c: [HeroChip] = []
        c.append(HeroChip(text: familie.aktiv ? "👨‍👩‍👧 Familie verbunden"
                                 : (familie.wartet ? "⏳ Wartet auf Freigabe" : "Ohne Familie"),
                          hervorgehoben: familie.aktiv))
        if !eltern && !kindKlasse.isEmpty { c.append(HeroChip(text: kindKlasse)) }
        return c
    }

    private var familienText: String {
        guard let z = familie.zugang else { return "Mit QR-Code verbinden" }
        if z.wartet { return "Wartet auf die Freigabe der Eltern" }
        if familie.abgelehnt { return "Nicht erlaubt worden" }
        return z.istEltern ? "Verbunden als Eltern-Gerät" : "Verbunden als Kind-Gerät"
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
            .einblenden(1)

            AbschnittsTitel("Familie und Klasse")
            ZeilenGruppe {
                zeile(symbol: "person.2.fill", titel: "Familie",
                      text: familienText, farbe: Theme.mint) { FamilieAnsicht() }
                ZeilenTrenner()
                zeile(symbol: "building.columns.fill", titel: "Klassencode",
                      text: klassenCode.isEmpty ? "Aufgaben von der Klasse bekommen" : klassenCode,
                      farbe: Theme.mint) { KlassenEinstellungen() }
            }
            .einblenden(2)

            AbschnittsTitel("Lernen und Spielen")
            ZeilenGruppe {
                zeile(symbol: "gamecontroller.fill", titel: "Spiele und Lernzeit",
                      text: spieleText, farbe: Theme.himmel) { LernzeitEinstellungen() }
                ZeilenTrenner()
                zeile(symbol: "square.grid.2x2.fill", titel: "Bereiche",
                      text: "Vorschule und Sprachen ein- und ausschalten",
                      farbe: Theme.himmel) { BereicheEinstellungen() }
                ZeilenTrenner()
                zeile(symbol: "speaker.wave.2.fill", titel: "Vorlese-Stimmen",
                      text: "Stimme wählen und bessere Stimmen laden", farbe: Theme.himmel) { StimmenView() }
            }
            .einblenden(3)

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
                      text: (farbwelt == "rosa" ? "Rosa" : "Blau und Gelb") + (sparmodus ? ", Sparmodus" : "")) { AussehenEinstellungen() }
            }
            .einblenden(4)

            AbschnittsTitel("Hilfe und Rechtliches")
            ZeilenGruppe {
                zeile(symbol: "book.fill", titel: "Anleitung, Info und Feedback",
                      text: "So funktioniert YEM1N") { InfoView() }
                ZeilenTrenner()
                zeile(symbol: "hand.raised.fill", titel: "Datenschutz",
                      text: "Hinweise, Impressum, Daten löschen", farbe: Theme.koralle) { RechtlichesEinstellungen() }
            }
            .einblenden(5)

            AbschnittsTitel("Für Fortgeschrittene", text: "Technik und Fehlersuche. Im Alltag brauchst du das nicht.")
            ZeilenGruppe {
                zeile(symbol: "wrench.and.screwdriver.fill", titel: "Technik",
                      text: "Cloud prüfen, Einrichtung, Gerätemodus",
                      farbe: Color.white.opacity(0.75)) { FortgeschrittenEinstellungen() }
            }
            .einblenden(6)

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
    @AppStorage("familienBelohnung") private var familienBelohnung = ""
    @AppStorage("jokerIch") private var jokerIch = ""
    @AppStorage(Bundesland.key) private var bundesland = ""
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
                    TextField("Vorname des Kindes", text: $nameEntwurf)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .focused($fokus)
                    Picker("Klasse", selection: $kindKlasse) {
                        Text("Alle").tag("")
                        ForEach(ProfilDaten.klassen, id: \.self) { k in Text(k).tag(k) }
                    }
                    Picker("Bundesland", selection: Binding(get: { Bundesland.aus(bundesland).rawValue },
                                                            set: { bundesland = $0 })) {
                        ForEach(Bundesland.allCases) { b in Text(b.name).tag(b.rawValue) }
                    }
                    Stepper("Tagesziel: \(tagesziel) \(tagesziel == 1 ? "Runde" : "Runden")",
                            value: $tagesziel, in: 1...10)
                } footer: {
                    Text("Der Name erscheint bei den Eltern und in der App. Ein Vorname oder Spitzname reicht, bitte keinen Nachnamen. Mit einer Klasse lädt das Gerät nur passende Aufgabenpakete, bei Alle bekommt es alle. Klasse und Bundesland bestimmen auch, welche Themen die Lernwelt zuerst zeigt.")
                }
                .listRowBackground(zeilenGrund)
                Section {
                    TextField("Zum Beispiel: Eis essen gehen", text: $familienBelohnung)
                        .onChange(of: familienBelohnung) {
                            if familienBelohnung.count > 60 { familienBelohnung = String(familienBelohnung.prefix(60)) }
                        }
                } header: {
                    Text("Belohnung zu Hause")
                } footer: {
                    Text("Wer das Wochenziel schafft, bekommt zusätzlich zu den Münzen diese Belohnung von euch. Das Kind sieht den Text bei den Erfolgen. Leer lassen, wenn es keine geben soll.")
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

struct BereicheEinstellungen: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("vorschulTab") private var vorschulAn = true
    @AppStorage(SprachAuswahl.anSchluessel) private var sprachenAn = false
    @AppStorage(VorschulSprache.englischSchluessel) private var vorschulEnglisch = false
    @AppStorage(VorschulSprache.tuerkischSchluessel) private var vorschulTuerkisch = false

    private var eltern: Bool { modus == "eltern" }

    var body: some View {
        EinstellungsSeite(titel: "Bereiche") {
            Section {
                Toggle("🧸 Vorschule anzeigen", isOn: $vorschulAn)
                    .tint(Theme.gelb)
            } header: {
                Text("Vorschule")
            } footer: {
                Text(eltern
                     ? "Zeigt die Vorschule im Reiter Lernen. Auf dem Kind-Gerät stellst du den Reiter dort selbst ein."
                     : "Zählen, Formen, Buchstaben und Spiele für Kinder, die noch nicht in die Schule gehen. Aus heißt: Der Reiter Vorschule verschwindet.")
            }
            .listRowBackground(zeilenGrund)

            if vorschulAn {
                Section {
                    Toggle("🇬🇧 Englisch in der Vorschule", isOn: $vorschulEnglisch)
                        .tint(Theme.gelb)
                    Toggle("🇹🇷 Vorschule auch auf Türkisch", isOn: $vorschulTuerkisch)
                        .tint(Theme.gelb)
                } header: {
                    Text("Vorschule in anderen Sprachen (Versuch)")
                } footer: {
                    Text("Die Vorschule spricht Deutsch. Englisch bringt den Bereich Englisch für Kleine: Wörter hören und Bilder antippen. Mit Englisch oder Türkisch erscheint außerdem oben in der Vorschule ein Umschalter, dann liest die App die übrigen Spiele auch in dieser Sprache vor. Reime, Silben und Anfangsbuchstaben bleiben auf Deutsch.")
                }
                .listRowBackground(zeilenGrund)
            }

            Section {
                Toggle("🌍 Sprachen anzeigen", isOn: $sprachenAn)
                    .tint(Theme.gelb)
                if sprachenAn {
                    SprachWahlSchalter()
                }
            } header: {
                Text("Sprachen (Versuch)")
            } footer: {
                Text("Wörter lernen mit Bildern und Vorlesen. Der Bereich ist noch ein Versuch: Es gibt erst wenige Themen und Wörter, und er kann sich noch ändern. Nur die angehakten Sprachen erscheinen.")
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
    @AppStorage(Sparmodus.key) private var spar = false

    var body: some View {
        EinstellungsSeite(titel: "Farben und Darstellung") {
            Section {
                Toggle("🔋 Sparmodus", isOn: $spar)
                    .tint(Theme.gelb)
                if Sparmodus.stromsparen && !spar {
                    Text("Gerade ist der iOS-Stromsparmodus an. Solange gilt der Sparmodus von selbst.")
                        .font(.footnote)
                        .foregroundStyle(Theme.gelb)
                }
            } header: {
                Text("Leistung")
            } footer: {
                Text(Sparmodus.empfohlen
                     ? "Für dieses Gerät empfohlen. Der Sparmodus macht die App auf älteren iPhones und iPads flüssiger und schont den Akku: keine schwebenden und wackelnden Bilder, kein Konfetti, kein Neigen, keine Glas-Effekte, das Haustier bewegt sich ruhiger und die Vorlesestimme gibt ihren Speicher schneller frei. Üben, Stimmen und Spiele bleiben gleich."
                     : "Macht die App auf älteren iPhones und iPads flüssiger und schont den Akku: keine schwebenden und wackelnden Bilder, kein Konfetti, kein Neigen, keine Glas-Effekte, das Haustier bewegt sich ruhiger und die Vorlesestimme gibt ihren Speicher schneller frei. Üben, Stimmen und Spiele bleiben gleich.")
            }
            .listRowBackground(zeilenGrund)

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
            } header: {
                Text("Darstellung")
            } footer: {
                Text("Glas-Effekte aus macht die App auf älteren iPhones flüssiger. Das Aussehen wird dann etwas flacher. Vorschule und Sprachen schaltest du unter Einstellungen > Bereiche ein und aus.")
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
    private let familie = FamilienModell.shared
    @AppStorage("modus") private var modus = ""
    @AppStorage(Einwilligung.versionKey) private var einwilligungVersion = 0
    @State private var zeigeLoeschen = false
    @State private var zeigeWiderruf = false
    @State private var info = ""

    private var eltern: Bool { modus == "eltern" }

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
                if familie.zugang != nil {
                    Button(eltern ? "Dieses Gerät aus der Familie nehmen"
                                  : "Familie verlassen und meine Einträge löschen", role: .destructive) {
                        zeigeLoeschen = true
                    }
                }
                Button("Einwilligung widerrufen", role: .destructive) { zeigeWiderruf = true }
                if !info.isEmpty {
                    Text(info).font(.footnote).foregroundStyle(Theme.textSanft)
                }
            } header: {
                Text("Deine Daten")
            } footer: {
                Text(eltern
                     ? "Die ganze Familie mit allen Einträgen löschst du unter Einstellungen > Familie. Der Familien-Dienst löscht alte Einträge nach 12 Monaten außerdem selbst."
                     : "Dann gehören dieses Gerät und seine Einträge nicht mehr zur Familie. Der Familien-Dienst löscht alte Einträge nach 12 Monaten außerdem selbst.")
            }
            .listRowBackground(zeilenGrund)
        }
        .confirmationDialog(eltern ? "Gerät wirklich aus der Familie nehmen?" : "Wirklich verlassen und löschen?",
                            isPresented: $zeigeLoeschen, titleVisibility: .visible) {
            Button(eltern ? "Ja, Gerät entfernen" : "Verlassen und löschen", role: .destructive) {
                info = "Wird erledigt ..."
                Task {
                    let fehler = await familie.verlassen(eintraegeLoeschen: !eltern)
                    info = fehler ?? "Erledigt. Dieses Gerät gehört nicht mehr zur Familie."
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text(eltern
                 ? "Dieses Gerät verlässt die Familie. Die Einträge der Familie bleiben für die anderen Geräte erhalten. Ist es das letzte Eltern-Gerät, löschst du stattdessen die ganze Familie."
                 : "Alle Ergebnisse, Fragen und Duelle, die dieses Gerät an die Familie geschickt hat, werden im Familien-Fach gelöscht. Auf dem Gerät bleibt alles.")
        }
        .confirmationDialog("Einwilligung widerrufen?", isPresented: $zeigeWiderruf,
                            titleVisibility: .visible) {
            Button("Widerrufen und Familie verlassen", role: .destructive) {
                Task {
                    if familie.zugang != nil {
                        if await familie.verlassen(eintraegeLoeschen: !eltern) != nil {
                            // Geht es nicht online (zum Beispiel ohne Netz), vergisst dieses Gerät die Familie trotzdem.
                            familie.lokalVergessen()
                        }
                    }
                    Einwilligung.widerrufen()
                    einwilligungVersion = 0
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Dieses Gerät verlässt die Familie, und die App fragt danach neu nach der Einwilligung. Ohne Einwilligung geht nichts in die Cloud. Ergebnisse auf dem Gerät bleiben.")
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
                Text("Verbindung zum Familien-Dienst testen und Mitteilungen prüfen.")
            }
            .listRowBackground(zeilenGrund)

            if modus != "eltern" {
                Section {
                    Label("Noch nicht gesendet: \(offene.count)", systemImage: "tray.full")
                } header: {
                    Text("Ergebnisse")
                } footer: {
                    Text("Ergebnisse werden automatisch an die Eltern gesendet, sobald das Gerät online und mit der Familie verbunden ist.")
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
                Text("Beim Gerätemodus erscheint wieder die Auswahl Kind oder Eltern. Die Familie, die Klassenarbeiten und der Fortschritt bleiben erhalten.")
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
