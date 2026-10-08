import SwiftUI
import CloudKit

// ============================================================
// MARK: - Das Haustier der Familie
// Das Kind-Gerät besitzt das Tier und legt seinen Stand in die Cloud.
// Das Eltern-Gerät zeigt dieses Tier an und kann es füttern oder mit ihm
// spielen, gratis, je einmal am Tag. Weil in der Cloud nur das Gerät
// schreiben darf, das einen Eintrag angelegt hat, schickt das Eltern-Gerät
// seine Fürsorge als kleinen eigenen Eintrag. Das Kind-Gerät wendet ihn an.
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
    static func eintragName(code: String, art: String, tag: String) -> String {
        "pflege-\(code)-\(tag)-\(art)"
    }

    static func gegeben(_ art: String, heute: String, vorhandene: [PflegeEintrag]) -> Bool {
        vorhandene.contains { $0.art == art && $0.tag == heute }
    }

    /// Noch nicht angewendete Einträge von heute und gestern. Ältere verfallen.
    static func neue(_ alle: [PflegeEintrag], angewandt: Set<String>, jetzt: Date,
                     kalender: Calendar = .current) -> [PflegeEintrag] {
        let heute = Haustier.tagKennung(jetzt, kalender: kalender)
        let gestern = kalender.date(byAdding: .day, value: -1, to: jetzt)
            .map { Haustier.tagKennung($0, kalender: kalender) } ?? heute
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
    static func sendeHaustier(code: String, _ h: Haustier?) async throws {
        let id = CKRecord.ID(recordName: "haustier-" + code)
        guard let h else {
            _ = try? await db.modifyRecords(saving: [], deleting: [id])
            return
        }
        let r: CKRecord
        if let alt = try? await db.record(for: id) {
            r = alt
        } else {
            r = CKRecord(recordType: "Haustier", recordID: id)
            r["familienCode"] = code as CKRecordValue
        }
        r["json"] = HaustierPflege.text(h) as CKRecordValue
        let erg = try await db.modifyRecords(saving: [r], deleting: [], savePolicy: .changedKeys)
        for (_, e) in erg.saveResults { _ = try e.get() }
    }

    static func ladeHaustier(code: String) async throws -> (haustier: Haustier, stand: Date)? {
        let records = try await holeRecords("Haustier", code: code, limit: 5)
        guard let r = records.first(where: { $0.recordID.recordName == "haustier-" + code }) ?? records.first,
              let text = r["json"] as? String,
              let h = HaustierPflege.haustier(aus: text) else { return nil }
        return (h, r.modificationDate ?? r.creationDate ?? Date.now)
    }

    static func holePflege(code: String) async throws -> [PflegeEintrag] {
        let records = try await holeRecords("HaustierPflege", code: code, limit: 200)
        return records.compactMap { r in
            guard let art = r["art"] as? String, let tag = r["tag"] as? String else { return nil }
            return PflegeEintrag(name: r.recordID.recordName, art: art, tag: tag)
        }
    }

    /// false, wenn es für heute schon einen Eintrag dieser Art gibt.
    static func sendePflege(code: String, art: String, jetzt: Date = Date.now) async throws -> Bool {
        let tag = Haustier.tagKennung(jetzt)
        let id = CKRecord.ID(recordName: HaustierPflege.eintragName(code: code, art: art, tag: tag))
        let r = CKRecord(recordType: "HaustierPflege", recordID: id)
        r["familienCode"] = code as CKRecordValue
        r["art"] = art as CKRecordValue
        r["tag"] = tag as CKRecordValue
        r["absender"] = ichName() as CKRecordValue
        do {
            _ = try await db.save(r)
            return true
        } catch let fehler as CKError where fehler.code == .serverRecordChanged {
            return false
        }
    }
}

// MARK: Abgleich auf dem Kind-Gerät

enum HaustierSync {
    nonisolated(unsafe) private static var wartend: Task<Void, Never>?

    private static var code: String { UserDefaults.standard.string(forKey: "familienCode") ?? "" }
    private static var modus: String { UserDefaults.standard.string(forKey: "modus") ?? "" }

    private static var erlaubt: Bool {
        modus == "kind" && Familiencode.istGueltig(code)
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
            await abgleich()
        }
    }

    /// Holt die Fürsorge der Eltern, wendet sie an und legt den Stand in die Cloud.
    static func abgleich(speicher: UserDefaults = .standard, jetzt: Date = Date.now) async {
        guard erlaubt else { return }
        if var h = HaustierSpeicher.laden(speicher: speicher),
           let alle = try? await CloudDienst.holePflege(code: code) {
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
            try await CloudDienst.sendeHaustier(code: code, lokal)
            speicher.set(text, forKey: HaustierPflege.hochgeladenKey)
        } catch {
            CloudStatus.shared.meldung = "Haustier senden nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }
}

// MARK: Ansicht auf dem Eltern-Gerät

struct ElternHaustierView: View {
    @AppStorage("familienCode") private var familienCode = ""
    @State private var tier: Haustier?
    @State private var stand: Date?
    @State private var heutigePflege: [PflegeEintrag] = []
    @State private var laedt = false
    @State private var meldung = ""

    private var heute: String { Haustier.tagKennung(Date.now) }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(spacing: 18) {
                        if !Familiencode.istGueltig(familienCode) {
                            hinweis("Trag in den Einstellungen den Familiencode ein, dann siehst du hier das Haustier deines Kindes.")
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
                .refreshable { await laden() }
            }
            .navigationTitle("Haustier")
            .navigationBarTitleDisplayMode(.inline)
            .task { await laden() }
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
        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                Text(h.emoji).font(.system(size: h.stufe.groesse))
                if let hut = HaustierHut.finde(h.hut)?.emoji, h.stufe != .ei {
                    Text(hut).font(.system(size: h.stufe.groesse * 0.4)).offset(y: -h.stufe.groesse * 0.2)
                }
            }
            .padding(.top, 14)
            Text(h.name)
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("\(h.stufe.name) · \(h.stimmung.emoji)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSanft)
            Text(h.spruch)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            balken("Satt", wert: h.satt / 100, farbe: Theme.mint)
            balken("Laune", wert: h.laune / 100, farbe: Theme.gelb)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 26)
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
        Group {
            if let stand {
                Text("Stand vom \(stand.formatted(date: .abbreviated, time: .shortened)). Zum Aktualisieren nach unten ziehen.")
            }
        }
        .font(.caption)
        .foregroundStyle(Theme.textSanft)
        .multilineTextAlignment(.center)
    }

    private func laden() async {
        guard Familiencode.istGueltig(familienCode) else { return }
        laedt = true
        defer { laedt = false }
        do {
            if let gefunden = try await CloudDienst.ladeHaustier(code: familienCode) {
                tier = gefunden.haustier
                stand = gefunden.stand
            } else {
                tier = nil
                stand = nil
            }
            heutigePflege = try await CloudDienst.holePflege(code: familienCode)
                .filter { $0.tag == heute }
            meldung = ""
            WidgetBruecke.zeige(haustier: tier)
        } catch {
            meldung = "Laden nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }

    private func geben(_ art: String) async {
        do {
            _ = try await CloudDienst.sendePflege(code: familienCode, art: art)
            heutigePflege = try await CloudDienst.holePflege(code: familienCode)
                .filter { $0.tag == heute }
            meldung = ""
        } catch {
            meldung = "Senden nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }
}
