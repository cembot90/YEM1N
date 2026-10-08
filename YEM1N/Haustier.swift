import SwiftUI
import UserNotifications

// ============================================================
// MARK: - Haustier (Tamagotchi)
// Das Haustier wird satt und froh, wenn das Kind übt. Es stirbt nie und
// läuft nie weg: Wer ein paar Tage nicht kommt, findet ein hungriges, aber
// freundliches Tier. Alles bleibt auf dem Gerät, es wird nichts übertragen.
// ============================================================

struct HaustierArt: Identifiable, Equatable {
    let id: String
    let emoji: String
    let name: String

    static let alle: [HaustierArt] = [
        HaustierArt(id: "katze", emoji: "🐱", name: "Katze"),
        HaustierArt(id: "hund", emoji: "🐶", name: "Hund"),
        HaustierArt(id: "hase", emoji: "🐰", name: "Hase"),
        HaustierArt(id: "fuchs", emoji: "🦊", name: "Fuchs"),
        HaustierArt(id: "drache", emoji: "🐲", name: "Drache"),
        HaustierArt(id: "einhorn", emoji: "🦄", name: "Einhorn")
    ]

    static func finde(_ id: String) -> HaustierArt {
        alle.first(where: { $0.id == id }) ?? alle[0]
    }
}

struct HaustierHut: Identifiable, Equatable {
    let id: String
    let emoji: String
    let name: String
    let preis: Int

    static let alle: [HaustierHut] = [
        HaustierHut(id: "brille", emoji: "🕶️", name: "Sonnenbrille", preis: 30),
        HaustierHut(id: "schleife", emoji: "🎀", name: "Schleife", preis: 30),
        HaustierHut(id: "kappe", emoji: "🧢", name: "Kappe", preis: 30),
        HaustierHut(id: "zylinder", emoji: "🎩", name: "Zylinder", preis: 45),
        HaustierHut(id: "doktor", emoji: "🎓", name: "Doktorhut", preis: 45),
        HaustierHut(id: "krone", emoji: "👑", name: "Krone", preis: 80)
    ]

    static func finde(_ id: String) -> HaustierHut? {
        alle.first(where: { $0.id == id })
    }
}

enum HaustierStufe: Int, CaseIterable {
    case ei, baby, kind, gross, meister

    var name: String {
        switch self {
        case .ei: return "Ei"
        case .baby: return "Baby"
        case .kind: return "Kind"
        case .gross: return "Großes Tier"
        case .meister: return "Meister"
        }
    }

    /// Ab so vielen Wachstumspunkten ist die Stufe erreicht.
    var schwelle: Int {
        switch self {
        case .ei: return 0
        case .baby: return 1
        case .kind: return 60
        case .gross: return 250
        case .meister: return 700
        }
    }

    var groesse: CGFloat {
        switch self {
        case .ei: return 70
        case .baby: return 78
        case .kind: return 100
        case .gross: return 126
        case .meister: return 148
        }
    }

    static func fuer(xp: Int) -> HaustierStufe {
        allCases.last(where: { xp >= $0.schwelle }) ?? .ei
    }

    var naechste: HaustierStufe? {
        HaustierStufe(rawValue: rawValue + 1)
    }
}

enum HaustierStimmung: Equatable {
    case froh, zufrieden, hungrig, traurig

    var emoji: String {
        switch self {
        case .froh: return "❤️"
        case .zufrieden: return "🙂"
        case .hungrig: return "🍽️"
        case .traurig: return "💧"
        }
    }
}

struct HaustierEreignis: Equatable {
    var geschluepft = false
    var aufgestiegen = false
    var stufe: HaustierStufe = .ei
}

struct Haustier: Codable, Equatable {
    var name: String
    var art: String
    var xp: Int
    var satt: Double
    var laune: Double
    var zuletzt: Date
    var hut: String
    var huete: [String]
    var geschenkTag: String

    // MARK: Zahlen zum Einstellen

    /// Unter diesem Wert ist das Tier hungrig.
    static let hungrigGrenze = 30.0
    static let sattProStunde = 2.5
    static let launeProStunde = 1.2
    /// Wenn das Tier hungrig ist, sinkt die Laune schneller.
    static let launeProStundeHungrig = 3.0
    static let leckerliPreis = 5
    static let spielzeugPreis = 8
    static let geschenkMuenzen = 2
    static let namenslaenge = 14

    init(name: String, art: String, jetzt: Date = Date.now) {
        self.name = Haustier.sauber(name, art: art)
        self.art = art
        self.xp = 0
        self.satt = 80
        self.laune = 80
        self.zuletzt = jetzt
        self.hut = ""
        self.huete = []
        self.geschenkTag = ""
    }

    // Fehlende Felder (spätere Versionen) führen nicht dazu, dass das Tier verschwindet
    enum CodingKeys: String, CodingKey {
        case name, art, xp, satt, laune, zuletzt, hut, huete, geschenkTag
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        art = try c.decodeIfPresent(String.self, forKey: .art) ?? "katze"
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Pip"
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        satt = try c.decodeIfPresent(Double.self, forKey: .satt) ?? 80
        laune = try c.decodeIfPresent(Double.self, forKey: .laune) ?? 80
        zuletzt = try c.decodeIfPresent(Date.self, forKey: .zuletzt) ?? Date.now
        hut = try c.decodeIfPresent(String.self, forKey: .hut) ?? ""
        huete = try c.decodeIfPresent([String].self, forKey: .huete) ?? []
        geschenkTag = try c.decodeIfPresent(String.self, forKey: .geschenkTag) ?? ""
    }

    /// Leerer Name wird "Pip", zu lange Namen werden gekürzt.
    static func sauber(_ roh: String, art: String) -> String {
        let t = roh.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "Pip" }
        return String(t.prefix(namenslaenge))
    }

    // MARK: Zustand

    var stufe: HaustierStufe { HaustierStufe.fuer(xp: xp) }

    var stimmung: HaustierStimmung {
        if satt < Haustier.hungrigGrenze { return .hungrig }
        if laune < 30 { return .traurig }
        if satt >= 60 && laune >= 60 { return .froh }
        return .zufrieden
    }

    var emoji: String {
        stufe == .ei ? "🥚" : HaustierArt.finde(art).emoji
    }

    /// Anteil auf dem Weg zur nächsten Stufe, 1 beim Meister.
    var fortschritt: Double {
        guard let weiter = stufe.naechste else { return 1 }
        let von = Double(stufe.schwelle)
        let bis = Double(weiter.schwelle)
        return min(max((Double(xp) - von) / (bis - von), 0), 1)
    }

    // MARK: Zeit vergeht

    /// Rechnet Hunger und Laune bis zum Zeitpunkt `jetzt` aus. Das Ei hat keinen Hunger.
    mutating func aktualisiere(jetzt: Date = Date.now) {
        let stunden = jetzt.timeIntervalSince(zuletzt) / 3600
        guard stunden > 0 else {
            if jetzt < zuletzt { zuletzt = jetzt }
            return
        }
        defer { zuletzt = jetzt }
        guard stufe != .ei else { return }
        let bisHungrig = satt > Haustier.hungrigGrenze
            ? (satt - Haustier.hungrigGrenze) / Haustier.sattProStunde
            : 0
        let normal = min(stunden, bisHungrig)
        let hungrig = stunden - normal
        laune -= normal * Haustier.launeProStunde + hungrig * Haustier.launeProStundeHungrig
        satt -= stunden * Haustier.sattProStunde
        satt = min(max(satt, 0), 100)
        laune = min(max(laune, 0), 100)
    }

    // MARK: Üben macht satt

    @discardableResult
    mutating func lernrunde(richtig: Int, gesamt: Int, angesehen: Int,
                            jetzt: Date = Date.now) -> HaustierEreignis {
        aktualisiere(jetzt: jetzt)
        let vorher = stufe
        // Wie bei den Münzen: Wer die Lösung ansieht, bekommt keinen Sternbonus
        let sterne = angesehen == 0 ? sterneFuer(gut: richtig, gesamt: gesamt) : 0
        xp += max(1, richtig + 2 * sterne)
        satt = min(satt + 30, 100)
        laune = min(laune + (sterne >= 3 ? 25 : 10), 100)
        return HaustierEreignis(geschluepft: vorher == .ei && stufe != .ei,
                                aufgestiegen: vorher != .ei && stufe != vorher,
                                stufe: stufe)
    }

    // MARK: Mit Münzen versorgen

    @discardableResult
    mutating func leckerli(bezahlen: (Int) -> Bool) -> Bool {
        guard stufe != .ei, satt < 95 else { return false }
        guard bezahlen(Haustier.leckerliPreis) else { return false }
        satt = min(satt + 25, 100)
        laune = min(laune + 3, 100)
        return true
    }

    @discardableResult
    mutating func spielen(bezahlen: (Int) -> Bool) -> Bool {
        guard stufe != .ei, laune < 95 else { return false }
        guard bezahlen(Haustier.spielzeugPreis) else { return false }
        laune = min(laune + 30, 100)
        return true
    }

    // MARK: Hüte

    @discardableResult
    mutating func kaufe(hut id: String, bezahlen: (Int) -> Bool) -> Bool {
        guard stufe != .ei, let h = HaustierHut.finde(id), !huete.contains(id) else { return false }
        guard bezahlen(h.preis) else { return false }
        huete.append(id)
        hut = id
        return true
    }

    /// Setzt einen gekauften Hut auf. Eine leere Kennung nimmt den Hut ab.
    mutating func trage(hut id: String) {
        if id.isEmpty || huete.contains(id) { hut = id }
    }

    // MARK: Tagesgeschenk

    static func tagKennung(_ datum: Date, kalender: Calendar = .current) -> String {
        let t = kalender.dateComponents([.year, .month, .day], from: datum)
        return "\(t.year ?? 0)-\(t.month ?? 0)-\(t.day ?? 0)"
    }

    func geschenkOffen(jetzt: Date = Date.now, kalender: Calendar = .current) -> Bool {
        geschenkTag != Haustier.tagKennung(jetzt, kalender: kalender)
    }

    /// Gibt die Münzen zurück, 0 wenn heute schon abgeholt wurde.
    mutating func holeGeschenk(jetzt: Date = Date.now, kalender: Calendar = .current) -> Int {
        guard geschenkOffen(jetzt: jetzt, kalender: kalender) else { return 0 }
        geschenkTag = Haustier.tagKennung(jetzt, kalender: kalender)
        return Haustier.geschenkMuenzen
    }

    // MARK: Worte

    var spruch: String {
        if stufe == .ei { return "Löse eine Runde, dann schlüpfe ich." }
        let liste: [String]
        switch stimmung {
        case .froh:
            liste = ["Mir geht es super!", "Heute lernen wir zusammen!", "Du bist klasse.", "Ich bin satt und froh."]
        case .zufrieden:
            liste = ["Ich bin zufrieden.", "Eine Runde wäre schön.", "Schön, dass du da bist."]
        case .hungrig:
            liste = ["Mein Bauch knurrt. Eine Runde macht mich satt!", "Ich habe Hunger. Üben macht satt."]
        case .traurig:
            liste = ["Mir ist langweilig. Spielst du mit mir?", "Ich vermisse dich."]
        }
        return liste[(xp / 3) % liste.count]
    }
}

extension HaustierEreignis {
    func text(fuer h: Haustier) -> String {
        if geschluepft { return "🐣 \(h.name) ist geschlüpft!" }
        if aufgestiegen { return "🎉 \(h.name) ist gewachsen: \(stufe.name)!" }
        return "\(h.emoji) \(h.name) ist satt und freut sich."
    }
}

// ============================================================
// MARK: - Speicher und Anbindung an die Runden
// ============================================================

enum HaustierSpeicher {
    static let key = "haustier"

    static func dekodiere(_ daten: Data) -> Haustier? {
        guard !daten.isEmpty else { return nil }
        return try? JSONDecoder().decode(Haustier.self, from: daten)
    }

    static func kodiere(_ h: Haustier) -> Data {
        (try? JSONEncoder().encode(h)) ?? Data()
    }

    static func laden(speicher: UserDefaults = .standard) -> Haustier? {
        guard let d = speicher.data(forKey: key) else { return nil }
        return dekodiere(d)
    }

    static func sichern(_ h: Haustier, speicher: UserDefaults = .standard) {
        speicher.set(kodiere(h), forKey: key)
    }

    static func entfernen(speicher: UserDefaults = .standard) {
        speicher.removeObject(forKey: key)
    }
}

enum HaustierDienst {
    /// Wird nach jeder fertigen Runde auf dem Kind-Gerät aufgerufen.
    /// Ohne Haustier passiert nichts. Gibt den Text für die Ergebnisseite zurück.
    @discardableResult
    static func rundeGeschafft(richtig: Int, gesamt: Int, angesehen: Int,
                               speicher: UserDefaults = .standard,
                               jetzt: Date = Date.now,
                               erinnern: Bool = true) -> String? {
        guard var h = HaustierSpeicher.laden(speicher: speicher) else { return nil }
        let ereignis = h.lernrunde(richtig: richtig, gesamt: gesamt, angesehen: angesehen, jetzt: jetzt)
        HaustierSpeicher.sichern(h, speicher: speicher)
        if erinnern { Task { await HaustierErinnerung.aktualisieren() } }
        return ereignis.text(fuer: h)
    }

    /// true, wenn das Tier Aufmerksamkeit braucht. Auch wenn es noch keins gibt.
    static func braucheAufmerksamkeit(_ daten: Data, jetzt: Date = Date.now) -> Bool {
        guard var h = HaustierSpeicher.dekodiere(daten) else { return true }
        h.aktualisiere(jetzt: jetzt)
        return h.stufe != .ei && (h.stimmung == .hungrig || h.stimmung == .traurig)
    }
}

// ============================================================
// MARK: - Erinnerung
// Eine einzige Mitteilung auf dem Gerät, am späten Nachmittag, und nur dann,
// wenn das Tier bis dahin hungrig wäre. Wer vorher übt, hört nichts davon.
// ============================================================

enum HaustierErinnerung {
    static let kennung = "haustier"
    static let uhrzeit = 17
    static let schalterKey = "haustierErinnerung"

    static func zeitpunkt(fuer h: Haustier, jetzt: Date, kalender: Calendar = .current) -> Date {
        let stunden: Double
        if h.stufe == .ei {
            stunden = 20
        } else {
            stunden = max(0, (h.satt - Haustier.hungrigGrenze) / Haustier.sattProStunde)
        }
        let ziel = jetzt.addingTimeInterval(min(stunden, 72) * 3600)
        return kalender.nextDate(after: ziel,
                                 matching: DateComponents(hour: uhrzeit, minute: 0),
                                 matchingPolicy: .nextTime) ?? ziel
    }

    /// Mit `fragen` bittet die Funktion einmal um die Erlaubnis für Mitteilungen,
    /// falls iOS noch nicht gefragt hat. Das passiert nur, wenn das Kind es selbst
    /// auslöst (Haustier aussuchen, Schalter einschalten), nie heimlich beim Start.
    static func aktualisieren(speicher: UserDefaults = .standard, jetzt: Date = Date.now,
                              fragen: Bool = false) async {
        let zentrale = UNUserNotificationCenter.current()
        zentrale.removePendingNotificationRequests(withIdentifiers: [kennung])
        let an = (speicher.object(forKey: schalterKey) as? Bool) ?? true
        guard an, speicher.string(forKey: "modus") == "kind",
              var h = HaustierSpeicher.laden(speicher: speicher) else { return }
        var einstellungen = await zentrale.notificationSettings()
        if einstellungen.authorizationStatus == .notDetermined && fragen {
            _ = try? await zentrale.requestAuthorization(options: [.alert, .sound])
            einstellungen = await zentrale.notificationSettings()
        }
        guard einstellungen.authorizationStatus == .authorized else { return }
        h.aktualisiere(jetzt: jetzt)
        let inhalt = UNMutableNotificationContent()
        if h.stufe == .ei {
            inhalt.title = "🥚 Dein Ei wartet"
            inhalt.body = "Löse eine Runde, damit es schlüpft."
        } else {
            inhalt.title = "\(h.emoji) \(h.name) hat Hunger"
            inhalt.body = "Eine Übungsrunde macht \(h.name) wieder satt."
        }
        inhalt.sound = .default
        let zeit = zeitpunkt(fuer: h, jetzt: jetzt)
        let teile = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: zeit)
        let ausloeser = UNCalendarNotificationTrigger(dateMatching: teile, repeats: false)
        let anfrage = UNNotificationRequest(identifier: kennung, content: inhalt, trigger: ausloeser)
        try? await zentrale.add(anfrage)
    }
}

// ============================================================
// MARK: - Ansicht
// ============================================================

struct HaustierView: View {
    @AppStorage(HaustierSpeicher.key) private var daten = Data()
    @AppStorage("muenzen") private var muenzen = 0
    @AppStorage(HaustierErinnerung.schalterKey) private var erinnerung = true
    @State private var wahlArt = "katze"
    @State private var wahlName = ""
    @State private var antippSpruch: String?
    @State private var huepf = false
    @State private var zeigeWechsel = false

    private var gespeichert: Haustier? { HaustierSpeicher.dekodiere(daten) }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(spacing: 16) {
                        if gespeichert == nil {
                            auswahl
                        } else {
                            TimelineView(.periodic(from: Date.now, by: 30)) { zeit in
                                inhalt(jetzt: zeit.date)
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Haustier")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: erinnerung) {
                Task { await HaustierErinnerung.aktualisieren(fragen: erinnerung) }
            }
            .confirmationDialog("Anderes Haustier aussuchen?", isPresented: $zeigeWechsel,
                                titleVisibility: .visible) {
                Button("Ja, mein Haustier geht", role: .destructive) {
                    HaustierSpeicher.entfernen()
                    daten = Data()
                    antippSpruch = nil
                    Task { await HaustierErinnerung.aktualisieren() }
                }
                Button("Nein, behalten", role: .cancel) {}
            } message: {
                Text("Dein jetziges Haustier und alle Hüte sind dann weg.")
            }
        }
    }

    // MARK: Aussuchen

    private var auswahl: some View {
        VStack(spacing: 16) {
            Text("🥚")
                .font(.system(size: 80))
            Text("Such dir ein Haustier aus")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("Es schlüpft, wenn du die erste Runde übst. Mit jeder Übung wird es satt und wächst.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                ForEach(HaustierArt.alle) { art in
                    Button { wahlArt = art.id } label: {
                        VStack(spacing: 4) {
                            Text(art.emoji).font(.system(size: 44))
                            Text(art.name)
                                .font(.system(.caption, design: .rounded).weight(.heavy))
                                .foregroundStyle(Color.white)
                        }
                        .frame(maxWidth: .infinity, minHeight: 90)
                        .background(Color.white.opacity(wahlArt == art.id ? 0.22 : 0.08),
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(wahlArt == art.id ? Theme.gelb : Color.clear, lineWidth: 3)
                        )
                    }
                    .buttonStyle(TastenStil())
                }
            }
            TextField("Name, zum Beispiel Pip", text: $wahlName)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .padding(14)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text("Der Name bleibt auf diesem Gerät. Dein Haustier läuft nie weg, auch wenn du mal ein paar Tage nicht übst.")
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)
            GelberKnopf(titel: "Ei bekommen") {
                let neu = Haustier(name: wahlName, art: wahlArt)
                HaustierSpeicher.sichern(neu)
                daten = HaustierSpeicher.kodiere(neu)
                Haptik.erfolg()
                Task { await HaustierErinnerung.aktualisieren(fragen: true) }
            }
            .padding(.horizontal, -24)
        }
        .padding(18)
        .glasKarte(radius: 30)
    }

    // MARK: Das Tier

    /// Das gespeicherte Tier, auf den Zeitpunkt `jetzt` hochgerechnet (nur zur Anzeige).
    private func aktuell(_ jetzt: Date) -> Haustier? {
        guard var h = gespeichert else { return nil }
        h.aktualisiere(jetzt: jetzt)
        return h
    }

    @ViewBuilder
    private func inhalt(jetzt: Date) -> some View {
        if let h = aktuell(jetzt) {
            muenzenKarte
            buehne(h)
            werte(h)
            if h.stufe != .ei { versorgen(h) }
            if h.geschenkOffen(jetzt: jetzt) { geschenk }
            if h.stufe != .ei { huete(h) }
            fuss
        }
    }

    private var muenzenKarte: some View {
        HStack(spacing: 12) {
            Image("muenze")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
            Text("\(muenzen) Münzen")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
                .contentTransition(.numericText())
            Spacer()
        }
        .padding(14)
        .glasKarte(radius: 22)
    }

    private func buehne(_ h: Haustier) -> some View {
        VStack(spacing: 10) {
            Text(h.name)
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundStyle(Theme.gelb)
            ZStack(alignment: .top) {
                Text(h.emoji)
                    .font(.system(size: h.stufe.groesse))
                    .scaleEffect(huepf ? 1.14 : 1.0)
                    .rotationEffect(.degrees(huepf ? 4 : 0))
                    .padding(.top, h.hut.isEmpty ? 0 : h.stufe.groesse * 0.22)
                if let hut = HaustierHut.finde(h.hut) {
                    Text(hut.emoji)
                        .font(.system(size: h.stufe.groesse * 0.45))
                        .offset(y: -h.stufe.groesse * 0.02)
                }
            }
            .onTapGesture { antippen(h) }
            Text("\(h.stimmung.emoji) \(antippSpruch ?? h.spruch)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12), in: Capsule())
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 30)
    }

    private func antippen(_ h: Haustier) {
        Haptik.leicht()
        withAnimation(.spring(duration: 0.25, bounce: 0.6)) { huepf = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(duration: 0.25)) { huepf = false }
        }
        let freude = ["Hihi, das kitzelt!", "Schön, dass du da bist.", "Weiter so!", "Ich hab dich lieb."]
        antippSpruch = h.stufe == .ei ? "Es wackelt im Ei." : freude.randomElement()
    }

    private func werte(_ h: Haustier) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(h.stufe.name)")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            if let weiter = h.stufe.naechste {
                ProgressView(value: h.fortschritt)
                    .tint(Theme.gelb)
                Text("Noch \(max(weiter.schwelle - h.xp, 0)) Punkte bis: \(weiter.name). Punkte gibt es für richtige Aufgaben und Sterne.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            } else {
                Text("Größer geht es nicht. \(h.name) ist ein Meister.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            if h.stufe != .ei {
                balken("Satt", wert: h.satt, farbe: Theme.mint)
                balken("Laune", wert: h.laune, farbe: Theme.himmel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func balken(_ titel: String, wert: Double, farbe: Color) -> some View {
        HStack(spacing: 10) {
            Text(titel)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
                .frame(width: 60, alignment: .leading)
            ProgressView(value: wert, total: 100)
                .tint(farbe)
        }
    }

    private func versorgen(_ h: Haustier) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verwöhnen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            HStack(spacing: 10) {
                versorgenKnopf("🍎 Leckerli", preis: Haustier.leckerliPreis,
                               moeglich: h.satt < 95 && muenzen >= Haustier.leckerliPreis) {
                    aendere { x in
                        if x.leckerli(bezahlen: { Muenzen.bezahlen($0) }) {
                            antippSpruch = "Lecker! Danke."
                        }
                    }
                }
                versorgenKnopf("🎾 Spielen", preis: Haustier.spielzeugPreis,
                               moeglich: h.laune < 95 && muenzen >= Haustier.spielzeugPreis) {
                    aendere { x in
                        if x.spielen(bezahlen: { Muenzen.bezahlen($0) }) {
                            antippSpruch = "Das macht Spaß!"
                        }
                    }
                }
            }
            Text("Satt wird dein Haustier auch gratis, wenn du eine Runde übst.")
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func versorgenKnopf(_ titel: String, preis: Int, moeglich: Bool,
                                aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            VStack(spacing: 2) {
                Text(titel)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                Text("\(preis) Münzen")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(Theme.navy)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Theme.gelb, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(TastenStil())
        .disabled(!moeglich)
        .opacity(moeglich ? 1 : 0.4)
    }

    private var geschenk: some View {
        Button {
            aendere { x in
                let m = x.holeGeschenk()
                if m > 0 {
                    Muenzen.gutschreiben(m)
                    antippSpruch = "Ein Geschenk für dich!"
                    Haptik.erfolg()
                }
            }
        } label: {
            Label("Tagesgeschenk abholen: \(Haustier.geschenkMuenzen) Münzen", systemImage: "gift.fill")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.navy)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Theme.mint, in: Capsule())
        }
        .buttonStyle(TastenStil())
    }

    private func huete(_ h: Haustier) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hüte und Brillen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HaustierHut.alle) { hut in
                        hutKarte(hut, h)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func hutKarte(_ hut: HaustierHut, _ h: Haustier) -> some View {
        let besitz = h.huete.contains(hut.id)
        let traegt = h.hut == hut.id
        let kannKaufen = muenzen >= hut.preis
        return Button {
            aendere { x in
                if besitz {
                    x.trage(hut: traegt ? "" : hut.id)
                } else if x.kaufe(hut: hut.id, bezahlen: { Muenzen.bezahlen($0) }) {
                    Haptik.erfolg()
                    antippSpruch = "Der steht mir!"
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(hut.emoji).font(.system(size: 36))
                Text(hut.name)
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Text(besitz ? (traegt ? "Abnehmen" : "Aufsetzen") : "\(hut.preis) Münzen")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(besitz ? Theme.gelb : Theme.textSanft)
            }
            .frame(width: 96, height: 98)
            .background(Color.white.opacity(traegt ? 0.22 : 0.08),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(traegt ? Theme.gelb : Color.clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(TastenStil())
        .disabled(!besitz && !kannKaufen)
        .opacity(besitz || kannKaufen ? 1 : 0.45)
    }

    private var fuss: some View {
        VStack(spacing: 10) {
            Toggle("Erinnere mich, wenn mein Haustier Hunger hat", isOn: $erinnerung)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
                .tint(Theme.gelb)
            Button("Anderes Haustier aussuchen") { zeigeWechsel = true }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 26)
    }

    // MARK: Ändern und speichern

    private func aendere(_ block: (inout Haustier) -> Void) {
        guard var h = HaustierSpeicher.dekodiere(daten) else { return }
        h.aktualisiere()
        block(&h)
        daten = HaustierSpeicher.kodiere(h)
        muenzen = Muenzen.stand
        Task { await HaustierErinnerung.aktualisieren() }
    }
}
