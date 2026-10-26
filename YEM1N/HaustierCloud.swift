import SwiftUI

// ============================================================
// MARK: - Das Haustier der Familie
// Das Kind-Gerät besitzt das Tier und legt seinen Stand in die Cloud.
// Das Eltern-Gerät zeigt dieses Tier an und kann es füttern oder mit ihm
// spielen, gratis, je einmal am Tag. Das Tier gehört dem Kind-Gerät, also schickt das
// Eltern-Gerät seine Fürsorge als kleinen eigenen Eintrag. Das Kind-Gerät wendet ihn an.
// ============================================================

/// Ein Eintrag der Eltern: "heute ein Leckerli".
struct PflegeEintrag: Equatable {
    var name: String
    var art: String
    var tag: String
}

enum HaustierPflege {
    static let leckerli = "leckerli"
    static let spielen = "spielen"
    static let arten = [leckerli, spielen]

    static let angewandtKey = "haustierPflegeAngewandt"
    static let hochgeladenKey = "haustierCloudStand"

    /// Der Name sorgt für das Tageslimit: Es gibt je Tag und Art nur einen Eintrag.
    static func eintragName(art: String, tag: String) -> String {
        "\(tag):\(art)"
    }

    static func gegeben(_ art: String, heute: String, vorhandene: [PflegeEintrag]) -> Bool {
        vorhandene.contains { $0.art == art && $0.tag == heute }
    }

    /// Noch nicht angewendete Einträge von heute und gestern. Ältere verfallen.
    static func neue(_ alle: [PflegeEintrag], angewandt: Set<String>, jetzt: Date,
                     kalender: Calendar = .current) -> [PflegeEintrag] {
        let heute = Haustier.pflegeTag(jetzt, kalender: kalender)
        let gestern = kalender.date(byAdding: .day, value: -1, to: jetzt)
            .map { Haustier.pflegeTag($0, kalender: kalender) } ?? heute
        return alle.filter { !angewandt.contains($0.name) && ($0.tag == heute || $0.tag == gestern) }
    }

    /// Wendet die Einträge auf das Tier an, ohne Münzen. Gibt zurück, wie viele gewirkt haben.
    @discardableResult
    static func anwenden(_ eintraege: [PflegeEintrag], auf h: inout Haustier,
                         jetzt: Date = Date.now) -> Int {
        h.aktualisiere(jetzt: jetzt)
        var gewirkt = 0
        for e in eintraege {
            let ok: Bool
            switch e.art {
            case leckerli: ok = h.leckerli(bezahlen: { _ in true })
            case spielen: ok = h.spielen(bezahlen: { _ in true })
            default: ok = false
            }
            if ok { gewirkt += 1 }
        }
        return gewirkt
    }

    /// Das Tier als Text für die Cloud und zurück.
    static func text(_ h: Haustier) -> String {
        String(data: HaustierSpeicher.kodiere(h), encoding: .utf8) ?? ""
    }

    static func haustier(aus text: String) -> Haustier? {
        HaustierSpeicher.dekodiere(Data(text.utf8))
    }
}

// MARK: Cloud-Zugriff

extension CloudDienst {
    /// Legt den Stand des Tiers ab. Ohne Tier geht ein leerer Stand raus, denn Einträge lassen sich nicht löschen.
    static func sendeHaustier(_ h: Haustier?) async throws {
        let json = h.map { HaustierPflege.text($0) } ?? "{}"
        guard json.utf16.count <= 8000 else {
            throw PaketFehler(text: "Das Haustier ist zu groß zum Verschicken.")
        }
        try await sende(FamilienProtokoll.haustier(json: json))
    }

    static func ladeHaustier() async throws -> (haustier: Haustier, stand: Date)? {
        let liste = try await lies(FamilienProtokoll.typHaustier)
        guard let e = liste.first(where: { $0.id == "haustier" }) ?? liste.first,
              let h = HaustierPflege.haustier(aus: e.text("json")) else { return nil }
        return (h, e.erstelltDatum)
    }

    static func holePflege() async throws -> [PflegeEintrag] {
        try await lies(FamilienProtokoll.typPflege).compactMap { e in
            let art = e.text("art"), tag = e.text("tag")
            guard !art.isEmpty, !tag.isEmpty else { return nil }
            return PflegeEintrag(name: e.id, art: art, tag: tag)
        }
    }

    /// false, wenn es für heute schon einen Eintrag dieser Art gibt (der Dienst zählt nur den ersten).
    static func sendePflege(art: String, jetzt: Date = Date.now) async throws -> Bool {
        let a = try await sende(FamilienProtokoll.pflege(art: art, tag: Haustier.pflegeTag(jetzt)))
        return (a.json?["neu"] as? Bool) ?? true
    }
}

// MARK: Abgleich auf dem Kind-Gerät

enum HaustierSync {
    nonisolated(unsafe) private static var wartend: Task<Void, Never>?
    nonisolated(unsafe) private static var laeuft = false
    nonisolated(unsafe) private static var nochmal = false

    private static var modus: String { UserDefaults.standard.string(forKey: "modus") ?? "" }

    private static var erlaubt: Bool {
        modus == "kind" && FamilienModell.shared.aktiv
            && !Einwilligung.erforderlich(
                gespeicherteVersion: UserDefaults.standard.integer(forKey: Einwilligung.versionKey))
    }

    /// Kurz warten, damit viele Änderungen hintereinander nur einen Abgleich auslösen.
    static func anstossen() {
        guard erlaubt else { return }
        wartend?.cancel()
        wartend = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            // Ein eigener Vorgang, damit ein späteres Abbrechen nicht die Cloud-Anfrage trifft.
            await Task { await lauf() }.value
        }
    }

    /// Nie zwei Abgleiche gleichzeitig. Kommt währenddessen eine Änderung, läuft er danach noch einmal.
    private static func lauf() async {
        if laeuft { nochmal = true; return }
        laeuft = true
        repeat {
            nochmal = false
            await abgleich()
        } while nochmal
        laeuft = false
    }

    /// Holt die Fürsorge der Eltern, wendet sie an und legt den Stand in die Cloud.
    static func abgleich(speicher: UserDefaults = .standard, jetzt: Date = Date.now) async {
        guard erlaubt else { return }
        if var h = HaustierSpeicher.laden(speicher: speicher),
           let alle = try? await CloudDienst.holePflege() {
            var angewandt = Set(speicher.stringArray(forKey: HaustierPflege.angewandtKey) ?? [])
            let neue = HaustierPflege.neue(alle, angewandt: angewandt, jetzt: jetzt)
            if !neue.isEmpty {
                HaustierPflege.anwenden(neue, auf: &h, jetzt: jetzt)
                HaustierSpeicher.sichern(h, speicher: speicher)
                WidgetBruecke.aktualisieren(cloud: false)
            }
            // Alles Gelesene merken, auch Verfallenes, damit es nie später wirkt.
            for e in alle { angewandt.insert(e.name) }
            speicher.set(Array(angewandt), forKey: HaustierPflege.angewandtKey)
        }
        await hochladen(speicher: speicher)
    }

    /// Lädt nur hoch, wenn sich seit dem letzten Mal etwas geändert hat.
    static func hochladen(speicher: UserDefaults = .standard) async {
        guard erlaubt else { return }
        let lokal = HaustierSpeicher.laden(speicher: speicher)
        let text = lokal.map { HaustierPflege.text($0) } ?? ""
        if speicher.string(forKey: HaustierPflege.hochgeladenKey) == text { return }
        do {
            try await CloudDienst.sendeHaustier(lokal)
            speicher.set(text, forKey: HaustierPflege.hochgeladenKey)
        } catch {
            CloudStatus.shared.meldung = "Haustier senden nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }
}

// MARK: Ansicht auf dem Eltern-Gerät

struct ElternHaustierView: View {
    private let familie = FamilienModell.shared
    @State private var tier: Haustier?
    @State private var stand: Date?
    @State private var heutigePflege: [PflegeEintrag] = []
    @State private var laedt = false
    @State private var meldung = ""
    /// Zählt hoch, damit das 3D-Tier nach Leckerli oder Spielen hüpft.
    @State private var stups = 0
    // Die Eule Olli erklärt den Eltern beim ersten Besuch, was sie beitragen können
    @AppStorage(Eule.elternEinfuehrungKey) private var einfuehrungGesehen = false
    @State private var einfuehrungSchritt = 0
    /// Was Olli gerade sagt. nil heißt: Das Tier hat das Wort.
    @State private var euleText: String?
    @State private var tippNummer = 0
    @State private var euleSpricht = 0
    @State private var tierSatz: String?
    @State private var antippNummer = 0
    @AppStorage(Eule.tonKey) private var laut = true

    private var heute: String { Haustier.pflegeTag(Date.now) }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(spacing: 18) {
                        if !familie.aktiv {
                            hinweis("Sobald dieses Gerät in den Einstellungen bei Familie mit deinem Kind verbunden ist, siehst du hier sein Haustier.")
                        } else if let h = tier {
                            // Die Zeit läuft weiter, auch wenn der Stand schon etwas älter ist.
                            TimelineView(.periodic(from: .now, by: 60)) { zeit in
                                karte(aktuell(h, zeit.date))
                            }
                            knoepfe(h)
                            fuss
                        } else if laedt {
                            ProgressView().tint(Theme.gelb).padding(.top, 60)
                        } else {
                            hinweis("Dein Kind hat noch kein Haustier ausgesucht. Es sucht eins im Tab Haustier auf seinem Gerät aus.")
                        }
                        if !meldung.isEmpty {
                            Text(meldung)
                                .font(.footnote)
                                .foregroundStyle(Theme.koralle)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
                .refreshable { await starteLaden() }
            }
            .navigationTitle("Haustier")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await starteLaden()
                await zeigeWichtigenTipp()
            }
        }
    }

    private func aktuell(_ h: Haustier, _ jetzt: Date) -> Haustier {
        var kopie = h
        kopie.aktualisiere(jetzt: jetzt)
        return kopie
    }

    private func hinweis(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .rounded))
            .foregroundStyle(Theme.textSanft)
            .multilineTextAlignment(.center)
            .padding(20)
            .frame(maxWidth: .infinity)
            .glasKarte(radius: 22)
    }

    private func karte(_ h: Haustier) -> some View {
        let schlaeft = h.stufe != .ei && HaustierZeit.schlaeft(Date.now)
        return VStack(spacing: 10) {
            Text(h.name)
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("\(h.stufe.name) · \(h.stimmung.emoji)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSanft)
            Haustier3DView(art: h.art, stufe: h.stufe, stimmung: h.stimmung,
                           hut: h.stufe == .ei ? "" : h.hut, stups: stups,
                           schlaeft: schlaeft,
                           eule: h.stufe == .ei ? .kreisen : .schweben,
                           euleSpricht: euleSpricht,
                           beiEule: { euleAntippen() },
                           beiTipp: { tierAntippen(h, schlaeft: schlaeft) })
                .frame(height: 250)
                .accessibilityLabel("\(h.name), \(h.stufe.name)")
            blase(h, schlaeft: schlaeft)
                .padding(.top, 4)
            if einfuehrungGesehen && euleText == nil {
                FragOlliKnopf { euleAntippen() }
            }
            balken("Satt", wert: h.satt / 100, farbe: Theme.mint)
            balken("Laune", wert: h.laune / 100, farbe: Theme.gelb)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background { HeroFlaeche(radius: 30) }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: euleText)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: einfuehrungGesehen)
    }

    // MARK: Olli und das Tier

    @ViewBuilder
    private func blase(_ h: Haustier, schlaeft: Bool) -> some View {
        if !einfuehrungGesehen {
            let schritte = Eule.elternEinfuehrung
            let i = min(einfuehrungSchritt, schritte.count - 1)
            SprechBlase(bild: Eule.bild, wer: Eule.name, text: schritte[i], spitzeLinks: true,
                        schritt: i, schritte: schritte.count,
                        weiter: { einfuehrungWeiter() },
                        ueberspringen: { einfuehrungEnde() })
        } else if let euleText {
            SprechBlase(bild: Eule.bild, wer: Eule.name, text: euleText, spitzeLinks: true,
                        schliessen: { self.euleText = nil })
        } else {
            SprechBlase(bild: h.emoji, wer: h.name,
                        text: tierSatz ?? TierStimme.vonSelbst(h, schlaeft: schlaeft),
                        tonhoehe: TierStimme.tonhoehe, vorlesen: !schlaeft)
        }
    }

    private var leckerliFrei: Bool {
        !HaustierPflege.gegeben(HaustierPflege.leckerli, heute: heute, vorhandene: heutigePflege)
    }

    private var spielFrei: Bool {
        !HaustierPflege.gegeben(HaustierPflege.spielen, heute: heute, vorhandene: heutigePflege)
    }

    private func euleAntippen() {
        Haptik.leicht()
        if !einfuehrungGesehen {
            let schritte = Eule.elternEinfuehrung
            sprichEule(schritte[min(einfuehrungSchritt, schritte.count - 1)])
            return
        }
        let liste = Eule.elternTipps(fuer: tier.map { aktuell($0, Date.now) },
                                     leckerliFrei: leckerliFrei, spielFrei: spielFrei)
        guard !liste.isEmpty else { return }
        let satz = liste[tippNummer % liste.count]
        tippNummer += 1
        tierSatz = nil
        euleText = satz
        sprichEule(satz)
    }

    private func sprichEule(_ text: String) {
        euleSpricht += 1
        if laut { Sprecher.shared.sprich(Eule.sprechbar(text), code: "de-DE") }
    }

    private func einfuehrungWeiter() {
        Haptik.leicht()
        if einfuehrungSchritt >= Eule.elternEinfuehrung.count - 1 {
            einfuehrungEnde()
        } else {
            einfuehrungSchritt += 1
            euleSpricht += 1
        }
    }

    private func einfuehrungEnde() {
        Sprecher.shared.still()
        einfuehrungGesehen = true
        einfuehrungSchritt = 0
        tippNummer = 0
        stups += 1
    }

    private func tierAntippen(_ h: Haustier, schlaeft: Bool) {
        Haptik.leicht()
        guard einfuehrungGesehen else { return }
        let satz = TierStimme.antippen(h, schlaeft: schlaeft, nummer: antippNummer)
        antippNummer += 1
        tierSagt(satz, hoerbar: !schlaeft)
    }

    private func tierSagt(_ satz: String, hoerbar: Bool = true) {
        euleText = nil
        tierSatz = satz
        if hoerbar && laut {
            Sprecher.shared.sprich(Eule.sprechbar(satz), code: "de-DE", tonhoehe: TierStimme.tonhoehe)
        }
    }

    /// Nach dem Laden meldet sich Olli, wenn gerade etwas passt, zum Beispiel ein freies Leckerli.
    private func zeigeWichtigenTipp() async {
        guard einfuehrungGesehen, euleText == nil, let h = tier,
              let satz = Eule.elternLageTipps(fuer: aktuell(h, Date.now), leckerliFrei: leckerliFrei,
                                              spielFrei: spielFrei).first else { return }
        do { try await Task.sleep(for: .milliseconds(600)) } catch { return }
        tierSatz = nil
        euleText = satz
        // Der erste Tipp in der Liste ist genau dieser, beim Antippen kommt der nächste
        tippNummer = 1
        euleSpricht += 1
    }

    private func balken(_ titel: String, wert: Double, farbe: Color) -> some View {
        HStack(spacing: 10) {
            Text(titel)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
                .frame(width: 52, alignment: .leading)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.14))
                GeometryReader { g in
                    Capsule().fill(farbe).frame(width: g.size.width * min(max(wert, 0), 1))
                }
            }
            .frame(height: 10)
        }
    }

    private func knoepfe(_ h: Haustier) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                knopf("🍎 Leckerli", art: HaustierPflege.leckerli, ei: h.stufe == .ei)
                knopf("🎾 Spielen", art: HaustierPflege.spielen, ei: h.stufe == .ei)
            }
            Text(h.stufe == .ei
                 ? "Das Tier ist noch ein Ei. Es schlüpft mit der ersten Runde deines Kindes."
                 : "Ein Leckerli und ein Spiel pro Tag sind gratis. Sie kommen an, sobald dein Kind die App öffnet.")
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)
        }
    }

    private func knopf(_ titel: String, art: String, ei: Bool) -> some View {
        let schon = HaustierPflege.gegeben(art, heute: heute, vorhandene: heutigePflege)
        return Button { Task { await geben(art) } } label: {
            Text(schon ? "Heute gegeben ✓" : titel)
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.navy)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(schon || ei ? Color.white.opacity(0.4) : Theme.gelb, in: Capsule())
        }
        .buttonStyle(TastenStil())
        .disabled(schon || ei)
    }

    private var fuss: some View {
        VStack(spacing: 12) {
            Toggle("Olli und das Tier sprechen laut", isOn: $laut)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
                .tint(Theme.gelb)
                .padding(.horizontal, 4)
            if let stand {
                Text("Stand vom \(stand.formatted(date: .abbreviated, time: .shortened)). Zum Aktualisieren nach unten ziehen.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// Das Laden läuft als eigener Vorgang. iOS bricht Aufgaben von Bildschirmen ab,
    /// zum Beispiel beim Wischen nach unten oder beim Wechsel des Tabs. Das würde die Anfrage treffen.
    private func starteLaden() async {
        await Task { await laden() }.value
    }

    private func istAbbruch(_ fehler: Error) -> Bool {
        if fehler is CancellationError { return true }
        return Task.isCancelled
    }

    private func laden() async {
        guard familie.aktiv else { return }
        laedt = true
        defer { laedt = false }
        do {
            if let gefunden = try await CloudDienst.ladeHaustier() {
                tier = gefunden.haustier
                stand = gefunden.stand
            } else {
                tier = nil
                stand = nil
            }
            heutigePflege = try await CloudDienst.holePflege()
                .filter { $0.tag == heute }
            meldung = ""
            WidgetBruecke.zeige(haustier: tier)
        } catch {
            if istAbbruch(error) { return }
            meldung = "Laden nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }

    private func geben(_ art: String) async {
        do {
            _ = try await Task { try await CloudDienst.sendePflege(art: art) }.value
            heutigePflege = try await CloudDienst.holePflege()
                .filter { $0.tag == heute }
            meldung = ""
            stups += 1
            Haptik.erfolg()
            tierSagt(art == HaustierPflege.leckerli ? "Mmh, lecker! Danke!" : "Juhu, spielen macht Spaß!")
        } catch {
            if istAbbruch(error) { return }
            meldung = "Senden nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }
}
