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

// ============================================================
// MARK: - Cloud-Pakete: Klassenarbeiten und Übungssets verteilen
// ============================================================

struct CloudPaket: Identifiable {
    let id: String
    let klasse: String
    let fach: String
    let titel: String
    let erstellt: Date
}

enum PaketJSON {
    // Eine Klassenarbeit als JSON-Text im Importformat
    static func text(von a: Klassenarbeit) -> String? {
        var uebungen: [[String: Any]] = []
        for u in a.sortierteUebungen {
            var aufgaben: [[String: Any]] = []
            for x in u.sortierteAufgaben {
                var d: [String: Any] = ["art": x.art, "frage": x.frage,
                                        "rechnung": x.rechnung, "antwort": x.antwort]
                if !x.hinweis.isEmpty { d["hinweis"] = x.hinweis }
                if !x.erklaerung.isEmpty { d["erklaerung"] = x.erklaerung }
                if !x.antwort2.isEmpty { d["antwort2"] = x.antwort2 }
                if x.art == "mauer" { d["reihen"] = x.reihen }
                aufgaben.append(d)
            }
            var ud: [String: Any] = ["titel": u.titel, "gruppe": u.gruppe,
                                     "symbol": u.symbol, "aufgaben": aufgaben]
            if !u.tipp.isEmpty { ud["tipp"] = u.tipp }
            uebungen.append(ud)
        }
        let wurzel: [String: Any] = ["klasse": a.klasse, "fach": a.fach,
                                     "arbeit": a.titel, "uebungen": uebungen]
        guard let daten = try? JSONSerialization.data(withJSONObject: wurzel) else { return nil }
        return String(data: daten, encoding: .utf8)
    }

    // Stabiler Name des Cloud-Datensatzes, damit erneutes Hochladen ersetzt statt verdoppelt
    static func schluessel(klasse: String, fach: String, titel: String) -> String {
        let erlaubt = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        var aus = ""
        var letzterStrich = false
        for z in (klasse + "-" + fach + "-" + titel).lowercased() {
            if erlaubt.contains(z) {
                aus.append(z)
                letzterStrich = false
            } else if !letzterStrich {
                aus.append("-")
                letzterStrich = true
            }
        }
        return aus
    }

    // Aus eingefügtem Text das JSON-Objekt herauslösen (falls Code-Zaun oder Begleittext dabei ist)
    static func bereinigt(_ text: String) -> String {
        if let s = text.firstIndex(of: "{"), let e = text.lastIndex(of: "}"), s < e {
            return String(text[s...e])
        }
        return text
    }
}

enum PaketImport {
    static func vorhanden(klasse: String, fach: String, titel: String, in context: ModelContext) -> Bool {
        let alle = (try? context.fetch(FetchDescriptor<Klassenarbeit>())) ?? []
        return alle.contains { $0.klasse == klasse && $0.fach == fach && $0.titel == titel }
    }

    static func einfuegen(_ paket: ArbeitPaket, in context: ModelContext) {
        let arbeit = Klassenarbeit(klasse: paket.klasse, fach: paket.fach, titel: paket.arbeit)
        context.insert(arbeit)
        for (i, up) in paket.uebungen.enumerated() {
            let uebung = Uebung(titel: up.titel,
                                gruppe: up.gruppe ?? "Aufgaben",
                                symbol: up.symbol ?? "✎",
                                tipp: up.tipp ?? "",
                                reihenfolge: i)
            context.insert(uebung)
            uebung.arbeit = arbeit
            for (j, ap) in up.aufgaben.enumerated() {
                var reihenJSON = ap.reihen
                    .flatMap { try? JSONEncoder().encode($0) }
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""
                let aufgabe: Aufgabe
                if ap.art == "wahl" {
                    // Vorschule: rechnung = Bild, hinweis = türkische Frage, erklaerung = große Zahl,
                    // antwort2 = Folge, reihenJSON = Antwortknöpfe
                    reihenJSON = (try? JSONEncoder().encode(ap.optionen ?? []))
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
                    aufgabe = Aufgabe(art: "wahl",
                                      frage: ap.frage ?? "",
                                      rechnung: ap.bild ?? "",
                                      hinweis: ap.tr ?? "",
                                      erklaerung: ap.gross ?? "",
                                      antwort: ap.antwort ?? "",
                                      antwort2: (ap.folge ?? []).joined(separator: " "),
                                      reihenJSON: reihenJSON,
                                      reihenfolge: j)
                } else {
                    aufgabe = Aufgabe(art: ap.art ?? "zahl",
                                      frage: ap.frage ?? "",
                                      rechnung: ap.rechnung ?? "",
                                      hinweis: ap.hinweis ?? "",
                                      erklaerung: ap.erklaerung ?? "",
                                      antwort: ap.antwort ?? "",
                                      antwort2: ap.antwort2 ?? "",
                                      reihenJSON: reihenJSON,
                                      reihenfolge: j)
                }
                context.insert(aufgabe)
                aufgabe.uebung = uebung
            }
        }
    }
}

extension CloudDienst {
    // Der Klassencode wird in der Cloud mit "K-" markiert, damit er nie mit einem Familiencode verwechselt wird
    static var klassenCloudCode: String? {
        let c = UserDefaults.standard.string(forKey: "klassenCode") ?? ""
        return Familiencode.istGueltig(c) ? "K-" + Familiencode.bereinigt(c) : nil
    }

    // Nur die Kopfdaten laden, der große JSON-Text kommt erst bei Bedarf
    static func ladePakete(code: String) async throws -> [CloudPaket] {
        let q = CKQuery(recordType: "Lernpaket",
                        predicate: NSPredicate(format: "familienCode == %@", code))
        let keys: [CKRecord.FieldKey] = ["klasse", "fach", "titel"]
        let antwort = try await db.records(matching: q, desiredKeys: keys, resultsLimit: 100)
        var liste: [CloudPaket] = []
        for (_, ergebnis) in antwort.matchResults {
            guard let r = try? ergebnis.get() else { continue }
            liste.append(CloudPaket(id: r.recordID.recordName,
                                    klasse: (r["klasse"] as? String) ?? "",
                                    fach: (r["fach"] as? String) ?? "",
                                    titel: (r["titel"] as? String) ?? "",
                                    erstellt: r.creationDate ?? Date.distantPast))
        }
        return liste.sorted { $0.erstellt < $1.erstellt }
    }

    static func ladePaketSigniert(id: String) async throws -> (json: String, sig: String)? {
        let r = try await db.record(for: CKRecord.ID(recordName: id))
        guard let j = r["json"] as? String, let sg = r["sig"] as? String else { return nil }
        return (j, sg)
    }

    // Admin-Schlüssel anlegen: der öffentliche Teil kommt in die Cloud, der private bleibt im Schlüsselbund
    static func erzeugeKlassenSchluessel(_ code: String) async throws {
        let k = Curve25519.Signing.PrivateKey()
        let r = CKRecord(recordType: "KlassenSchluessel",
                         recordID: CKRecord.ID(recordName: "klassenkey-" + code))
        r["klassenCode"] = code as CKRecordValue
        r["publicKey"] = k.publicKey.rawRepresentation.base64EncodedString() as CKRecordValue
        let erg = try await db.modifyRecords(saving: [r], deleting: [], savePolicy: .allKeys)
        for (_, e) in erg.saveResults { _ = try e.get() }
        Schluesselbund.speichere(k.rawRepresentation, konto: Klassensiegel.konto(code))
        UserDefaults.standard.removeObject(forKey: "klassenPin-" + code)
    }

    static func stelleOeffentlichenSchluesselSicher(_ code: String) async throws {
        guard let k = Klassensiegel.privaterSchluessel(code) else { return }
        if await ladeKlassenSchluessel(code) != nil { return }
        let r = CKRecord(recordType: "KlassenSchluessel",
                         recordID: CKRecord.ID(recordName: "klassenkey-" + code))
        r["klassenCode"] = code as CKRecordValue
        r["publicKey"] = k.publicKey.rawRepresentation.base64EncodedString() as CKRecordValue
        let erg = try await db.modifyRecords(saving: [r], deleting: [], savePolicy: .allKeys)
        for (_, e) in erg.saveResults { _ = try e.get() }
    }

    static func ladeKlassenSchluessel(_ code: String) async -> Data? {
        guard let r = try? await db.record(for: CKRecord.ID(recordName: "klassenkey-" + code)),
              let b64 = r["publicKey"] as? String else { return nil }
        return Data(base64Encoded: b64)
    }

    // Datenschutz: löscht alle Einträge dieses Familiencodes, die dieses Gerät angelegt hat
    static func loescheEigeneDaten(code: String) async -> Int {
        let typen = ["RundenErgebnis", "JokerAnfrage", "JokerAntwort", "JokerDaumen",
                     "JokerNachschub", "JokerFreigabe", "Lernpaket", "Haustier", "HaustierPflege"]
        var geloescht = 0
        for typ in typen {
            let q = CKQuery(recordType: typ, predicate: NSPredicate(format: "familienCode == %@", code))
            guard let antwort = try? await db.records(matching: q, desiredKeys: [], resultsLimit: 400) else { continue }
            var ids: [CKRecord.ID] = []
            for (id, ergebnis) in antwort.matchResults {
                if (try? ergebnis.get()) != nil { ids.append(id) }
            }
            if ids.isEmpty { continue }
            guard let erg = try? await db.modifyRecords(saving: [], deleting: ids) else { continue }
            for (_, e) in erg.deleteResults {
                if (try? e.get()) != nil { geloescht += 1 }
            }
        }
        return geloescht
    }

    static func ladePaketText(id: String) async throws -> String? {
        let r = try await db.record(for: CKRecord.ID(recordName: id))
        return r["json"] as? String
    }

    static func hochladen(code: String, paket: ArbeitPaket, json: String) async throws {
        let name = "paket-" + code + "-" + PaketJSON.schluessel(klasse: paket.klasse,
                                                              fach: paket.fach, titel: paket.arbeit)
        let r = CKRecord(recordType: "Lernpaket", recordID: CKRecord.ID(recordName: name))
        r["familienCode"] = code as CKRecordValue
        r["klasse"] = paket.klasse as CKRecordValue
        r["fach"] = paket.fach as CKRecordValue
        r["titel"] = paket.arbeit as CKRecordValue
        r["json"] = json as CKRecordValue
        r["aufgaben"] = paket.uebungen.reduce(0) { $0 + $1.aufgaben.count } as CKRecordValue
        if code.hasPrefix("K-") {
            // Falls der öffentliche Schlüssel in dieser Cloud fehlt (zum Beispiel nach dem Wechsel auf Production),
            // wird er mit dem vorhandenen privaten Schlüssel neu hinterlegt. So bleibt der Schlüssel gleich.
            try await stelleOeffentlichenSchluesselSicher(code)
            guard let sig = Klassensiegel.signiere(code: code, json: json) else { throw KlassenFehler.keinSchluessel }
            r["sig"] = sig as CKRecordValue
        }
        let ergebnis = try await db.modifyRecords(saving: [r], deleting: [], savePolicy: .allKeys)
        for (_, e) in ergebnis.saveResults { _ = try e.get() }
    }

    static func loeschePaket(id: String) async throws {
        _ = try await db.deleteRecord(withID: CKRecord.ID(recordName: id))
    }
}

// Eltern: Aufgaben in die Cloud stellen, Kind-Geräte laden sie von selbst
struct PaketeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Klassenarbeit.klasse), SortDescriptor(\Klassenarbeit.fach),
                  SortDescriptor(\Klassenarbeit.erstellt)])
    private var arbeiten: [Klassenarbeit]
    @AppStorage("familienCode") private var familienCode = ""
    @State private var cloud: [CloudPaket] = []
    @State private var klassenCloud: [CloudPaket] = []
    @State private var cloudZuLoeschen: [CloudPaket] = []
    @State private var fuerKlasse = false
    @State private var meldung = ""
    @State private var zeigeEinfuegen = false
    @State private var eingabe = ""
    @State private var fehlerText = ""
    @State private var arbeitet = false

    private let zeile = Color.white.opacity(0.08)

    private func inCloud(_ a: Klassenarbeit) -> Bool {
        cloud.contains { $0.klasse == a.klasse && $0.fach == a.fach && $0.titel == a.titel }
    }

    private var eigene: [Klassenarbeit] { arbeiten.filter { $0.spezial.isEmpty } }

    var body: some View {
        ZStack {
            HintergrundView()
            List {
                if !Familiencode.istGueltig(familienCode) && CloudDienst.klassenCloudCode == nil {
                    Section {
                        Text("Zuerst im Tab Einstellungen einen Familiencode eintragen.")
                            .foregroundStyle(Theme.koralle)
                    }
                    .listRowBackground(zeile)
                }

                Section {
                    Button {
                        fehlerText = ""
                        zeigeEinfuegen = true
                    } label: {
                        Label("JSON einfügen und veröffentlichen", systemImage: "doc.on.clipboard")
                    }
                } footer: {
                    Text("Das JSON von Claude einfügen. Es landet direkt in der Cloud und auch hier auf dem Gerät.")
                }
                .listRowBackground(zeile)

                Section {
                    if eigene.isEmpty {
                        Text("Keine Klassenarbeit auf diesem Gerät.")
                            .foregroundStyle(Theme.textSanft)
                    }
                    ForEach(eigene) { a in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(a.titel).font(.headline)
                                Text("\(a.klasse), \(a.fach)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSanft)
                            }
                            Spacer()
                            if inCloud(a) {
                                Image(systemName: "checkmark.icloud.fill").foregroundStyle(Theme.mint)
                            }
                            Menu(inCloud(a) ? "Erneut senden" : "Senden") {
                                Button("An meine Familie") { Task { await hochladen(a, klasse: false) } }
                                if CloudDienst.klassenCloudCode != nil {
                                    Button("An die Klasse") { Task { await hochladen(a, klasse: true) } }
                                }
                            }
                            .disabled(arbeitet)
                        }
                    }
                } header: {
                    Text("Auf diesem Gerät")
                } footer: {
                    Text("Kind-Geräte laden nur Pakete, die sie noch nicht haben. Vorhandene bleiben mit Fortschritt unverändert.")
                }
                .listRowBackground(zeile)

                Section {
                    if cloud.isEmpty {
                        Text("Noch nichts in der Cloud.").foregroundStyle(Theme.textSanft)
                    }
                    ForEach(cloud) { p in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.titel).font(.headline)
                            Text("\(p.klasse), \(p.fach)")
                                .font(.caption)
                                .foregroundStyle(Theme.textSanft)
                        }
                    }
                    .onDelete { offsets in
                        cloudZuLoeschen = offsets.map { cloud[$0] }
                    }
                } header: {
                    Text("In der Cloud")
                } footer: {
                    Text("Nach links wischen entfernt ein Paket aus der Cloud. Auf den Kind-Geräten bleibt es erhalten.")
                }
                .listRowBackground(zeile)

                if CloudDienst.klassenCloudCode != nil {
                    Section {
                        if klassenCloud.isEmpty {
                            Text("Noch nichts beim Klassencode.").foregroundStyle(Theme.textSanft)
                        }
                        ForEach(klassenCloud) { p in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.titel).font(.headline)
                                Text("\(p.klasse), \(p.fach)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSanft)
                            }
                        }
                        .onDelete { offsets in
                            cloudZuLoeschen = offsets.map { klassenCloud[$0] }
                        }
                    } header: {
                        Text("Bei der Klasse")
                    } footer: {
                        Text("Diese Pakete laden alle Geräte mit deinem Klassencode. Nur du kannst deine Pakete ändern oder löschen.")
                    }
                    .listRowBackground(zeile)
                }

                if !meldung.isEmpty {
                    Section { Text(meldung).font(.footnote) }
                        .listRowBackground(zeile)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Cloud-Pakete")
        .navigationBarTitleDisplayMode(.inline)
        .task { await laden() }
        .confirmationDialog("Aus der Cloud wirklich löschen?",
                            isPresented: Binding(get: { !cloudZuLoeschen.isEmpty },
                                                 set: { if !$0 { cloudZuLoeschen = [] } }),
                            titleVisibility: .visible) {
            Button("Ja, löschen", role: .destructive) {
                let ziele = cloudZuLoeschen
                cloudZuLoeschen = []
                Task {
                    for p in ziele { try? await CloudDienst.loeschePaket(id: p.id) }
                    await laden()
                }
            }
            Button("Nein, behalten", role: .cancel) { cloudZuLoeschen = [] }
        } message: {
            Text(cloudZuLoeschen.map(\.titel).joined(separator: ", "))
        }
        .refreshable { await laden() }
        .sheet(isPresented: $zeigeEinfuegen) { einfuegenSheet }
    }

    private var einfuegenSheet: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                VStack(alignment: .leading, spacing: 10) {
                    Button("Aus Zwischenablage einfügen") {
                        eingabe = UIPasteboard.general.string ?? ""
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    if CloudDienst.klassenCloudCode != nil {
                        Toggle("An die Klasse statt an meine Familie", isOn: $fuerKlasse)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                    }
                    TextEditor(text: $eingabe)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(Color.white.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    if !fehlerText.isEmpty {
                        Text(fehlerText)
                            .font(.footnote)
                            .foregroundStyle(Theme.koralle)
                    }
                }
                .padding()
            }
            .navigationTitle("JSON veröffentlichen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { zeigeEinfuegen = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(arbeitet ? "Bitte warten ..." : "Veröffentlichen") {
                        Task { await veroeffentlichen() }
                    }
                    .disabled(arbeitet || eingabe.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }

    private func laden() async {
        do {
            if Familiencode.istGueltig(familienCode) {
                cloud = try await CloudDienst.ladePakete(code: familienCode)
            }
            if let k = CloudDienst.klassenCloudCode {
                klassenCloud = try await CloudDienst.ladePakete(code: k)
            }
        } catch {
            meldung = CloudDienst.fehlertext(error)
        }
    }

    // Zielcode: Klassencode oder Familiencode
    private func zielCode(klasse: Bool) -> String? {
        if klasse { return CloudDienst.klassenCloudCode }
        return Familiencode.istGueltig(familienCode) ? familienCode : nil
    }

    private func hochladen(_ a: Klassenarbeit, klasse: Bool) async {
        guard let ziel = zielCode(klasse: klasse) else {
            meldung = klasse ? "Bitte zuerst einen Klassencode eintragen." : "Bitte zuerst einen Familiencode eintragen."
            return
        }
        guard let json = PaketJSON.text(von: a),
              let daten = json.data(using: .utf8),
              let paket = try? JSONDecoder().decode(ArbeitPaket.self, from: daten) else {
            meldung = "Das Paket konnte nicht erstellt werden."
            return
        }
        arbeitet = true
        meldung = "Wird hochgeladen ..."
        do {
            try await CloudDienst.hochladen(code: ziel, paket: paket, json: json)
            meldung = klasse ? "\(a.titel) ist beim Klassencode. Alle Geräte mit diesem Code laden es automatisch."
                             : "\(a.titel) ist in der Cloud. Die Kind-Geräte laden es automatisch."
            await laden()
        } catch {
            meldung = "Hochladen nicht möglich: \(CloudDienst.fehlertext(error))"
        }
        arbeitet = false
    }

    private func veroeffentlichen() async {
        guard let ziel = zielCode(klasse: fuerKlasse) else {
            fehlerText = fuerKlasse ? "Bitte zuerst einen Klassencode eintragen." : "Bitte zuerst einen Familiencode eintragen."
            return
        }
        let text = PaketJSON.bereinigt(eingabe)
        guard let daten = text.data(using: .utf8),
              let paket = try? JSONDecoder().decode(ArbeitPaket.self, from: daten),
              !paket.uebungen.isEmpty,
              paket.uebungen.allSatisfy({ !$0.aufgaben.isEmpty }) else {
            fehlerText = "Das Format passt nicht. Es geht um Klassenarbeiten und Übungssets, bitte das JSON von Claude komplett kopieren."
            return
        }
        fehlerText = ""
        arbeitet = true
        do {
            try await CloudDienst.hochladen(code: ziel, paket: paket, json: text)
            if !PaketImport.vorhanden(klasse: paket.klasse, fach: paket.fach, titel: paket.arbeit, in: context) {
                PaketImport.einfuegen(paket, in: context)
                try? context.save()
            }
            meldung = fuerKlasse ? "\(paket.arbeit) ist beim Klassencode. Alle Geräte mit diesem Code laden es automatisch."
                                 : "\(paket.arbeit) ist in der Cloud. Die Kind-Geräte laden es automatisch."
            eingabe = ""
            zeigeEinfuegen = false
            await laden()
        } catch {
            fehlerText = "Hochladen nicht möglich: \(CloudDienst.fehlertext(error))"
        }
        arbeitet = false
    }
}

// ============================================================
// MARK: - Joker-Nachschub und Cloud-Diagnose
// ============================================================

struct CloudNachschub: Identifiable {
    let id: String
    let kind: String
    let erstellt: Date
}

extension CloudDienst {
    static func sendeNachschub(code: String, kind: String) async throws {
        let r = CKRecord(recordType: "JokerNachschub")
        r["familienCode"] = code as CKRecordValue
        r["kind"] = kind as CKRecordValue
        _ = try await db.save(r)
    }

    static func sendeFreigabe(code: String) async throws {
        let r = CKRecord(recordType: "JokerFreigabe")
        r["familienCode"] = code as CKRecordValue
        r["anzahl"] = 3 as CKRecordValue
        _ = try await db.save(r)
    }

    static func ladeNachschub(code: String) async throws -> [CloudNachschub] {
        let records = try await holeRecords("JokerNachschub", code: code, limit: 100)
        var liste: [CloudNachschub] = []
        for r in records {
            liste.append(CloudNachschub(id: r.recordID.recordName,
                                        kind: (r["kind"] as? String) ?? "Kind",
                                        erstellt: r.creationDate ?? Date.distantPast))
        }
        return liste
    }

    static func ladeFreigaben(code: String) async throws -> [Date] {
        let records = try await holeRecords("JokerFreigabe", code: code, limit: 100)
        var liste: [Date] = []
        for r in records {
            liste.append(r.creationDate ?? Date.distantPast)
        }
        return liste
    }
}

// Eltern: Joker des Kindes wieder auffüllen, auf Anfrage oder jederzeit
struct JokerNachschubView: View {
    private let cloud = JokerCloud.shared
    @AppStorage("familienCode") private var familienCode = ""
    @State private var info = ""
    @State private var laeuft = false

    private var offene: [CloudNachschub] {
        let letzte = cloud.freigaben.max() ?? Date.distantPast
        return cloud.nachschub.filter { $0.erstellt > letzte }.sorted { $0.erstellt > $1.erstellt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Joker-Nachschub")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            if let a = offene.first {
                Text("\(a.kind) hat keine Joker mehr und fragt nach neuen (\(a.erstellt.formatted(.relative(presentation: .named)))).")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
            } else {
                Text("Keine offene Anfrage. Du kannst die Joker trotzdem jederzeit auffüllen.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Button {
                Task { await freigeben() }
            } label: {
                Text(laeuft ? "Bitte warten ..." : "Joker wieder auf 3 auffüllen")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            .disabled(laeuft || !Familiencode.istGueltig(familienCode))
            if !info.isEmpty {
                Text(info)
                    .font(.footnote)
                    .foregroundStyle(Theme.himmel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func freigeben() async {
        laeuft = true
        do {
            try await CloudDienst.sendeFreigabe(code: familienCode)
            Haptik.erfolg()
            info = "Freigegeben. Das Kind-Gerät füllt die Joker auf, sobald es online ist."
            await cloud.aktualisieren()
        } catch {
            info = "Freigabe nicht möglich: \(CloudDienst.fehlertext(error))"
        }
        laeuft = false
    }
}

// In den Einstellungen: Cloud prüfen und neu einrichten, damit das Kind nicht versehentlich darauf tippt
struct CloudDiagnoseView: View {
    @State private var testMeldung = ""
    @State private var testet = false

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CloudStatusKarte()
                    PushDiagnoseKarte()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Verbindungstest")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        Text("Schreibt einen Test-Datensatz in die Cloud und zeigt, ob die Verbindung steht.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                        Button {
                            Task {
                                testet = true
                                testMeldung = await CloudKitDienst.verbindungTesten()
                                testet = false
                            }
                        } label: {
                            Text(testet ? "Bitte warten ..." : "CloudKit testen")
                                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.navy)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Theme.gelb, in: Capsule())
                        }
                        .buttonStyle(TastenStil())
                        .disabled(testet)
                        if !testMeldung.isEmpty {
                            Text(testMeldung)
                                .font(.footnote)
                                .foregroundStyle(Theme.himmel)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glasKarte(radius: 26)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Cloud-Diagnose")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Zeigt, warum Mitteilungen ankommen oder nicht
struct PushDiagnoseKarte: View {
    @State private var erlaubnis = "wird geprüft ..."
    @State private var registrierung = "wird geprüft ..."
    @State private var abos = "wird geprüft ..."
    @State private var testInfo = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mitteilungen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            zeile("Erlaubnis", erlaubnis)
            zeile("Anmeldung bei Apple", registrierung)
            zeile("Abos in der Cloud", abos)
            HStack(spacing: 10) {
                Button { Task { await pruefen() } } label: { knopf("Prüfen") }
                    .buttonStyle(TastenStil())
                Button { Task { await testSenden() } } label: { knopf("Test in 5 Sekunden") }
                    .buttonStyle(TastenStil())
            }
            if !testInfo.isEmpty {
                Text(testInfo)
                    .font(.footnote)
                    .foregroundStyle(Theme.himmel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
        .task { await pruefen() }
    }

    private func zeile(_ titel: String, _ wert: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titel)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Theme.textSanft)
            Text(wert)
                .font(.footnote)
                .foregroundStyle(Color.white)
        }
    }

    private func knopf(_ titel: String) -> some View {
        Text(titel)
            .font(.system(.footnote, design: .rounded).weight(.heavy))
            .foregroundStyle(Theme.navy)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Theme.gelb, in: Capsule())
    }

    private func pruefen() async {
        let einstellungen = await UNUserNotificationCenter.current().notificationSettings()
        switch einstellungen.authorizationStatus {
        case .authorized: erlaubnis = "erlaubt"
        case .denied: erlaubnis = "ABGELEHNT. Bitte in den iPhone-Einstellungen unter Mitteilungen bei YEM1N erlauben."
        case .notDetermined: erlaubnis = "noch nicht gefragt. Bitte Cloud neu einrichten."
        case .provisional: erlaubnis = "vorläufig erlaubt"
        case .ephemeral: erlaubnis = "vorübergehend erlaubt"
        @unknown default: erlaubnis = "unbekannt"
        }
        registrierung = UserDefaults.standard.string(forKey: "pushStatus") ?? "noch keine Rückmeldung von Apple"
        do {
            let alle = try await CloudDienst.db.allSubscriptions()
            abos = alle.isEmpty ? "keine" : alle.map { $0.subscriptionID }.sorted().joined(separator: "\n")
        } catch {
            abos = "Fehler: \(error.localizedDescription)"
        }
    }

    private func testSenden() async {
        let inhalt = UNMutableNotificationContent()
        inhalt.title = "YEM1N"
        inhalt.body = "Test: So sieht eine Mitteilung aus."
        inhalt.sound = .default
        let anfrage = UNNotificationRequest(identifier: UUID().uuidString, content: inhalt,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
        do {
            try await UNUserNotificationCenter.current().add(anfrage)
            testInfo = "Kommt in 5 Sekunden. Sperre das iPhone oder bleib in der App, beides sollte ein Banner zeigen."
        } catch {
            testInfo = "Test nicht möglich: \(error.localizedDescription)"
        }
    }
}

// Wischen zum Erledigen: Karte nach links oder rechts ziehen
struct WischErledigt: ViewModifier {
    let aktion: () -> Void
    @State private var versatz: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: versatz)
            .opacity(1 - min(abs(versatz) / 300, 0.6))
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onChanged { wert in
                        if abs(wert.translation.width) > abs(wert.translation.height) {
                            versatz = wert.translation.width
                        }
                    }
                    .onEnded { wert in
                        let waagrecht = abs(wert.translation.width) > abs(wert.translation.height)
                        if waagrecht && abs(wert.translation.width) > 110 {
                            withAnimation(.easeOut(duration: 0.2)) {
                                versatz = wert.translation.width > 0 ? 500 : -500
                            }
                            Task {
                                try? await Task.sleep(for: .milliseconds(220))
                                aktion()
                                versatz = 0
                            }
                        } else {
                            withAnimation(.snappy) { versatz = 0 }
                        }
                    }
            )
    }
}

extension View {
    func wischErledigt(_ aktion: @escaping () -> Void) -> some View {
        modifier(WischErledigt(aktion: aktion))
    }
}

extension CloudDienst {
    // Name des Elternteils auf diesem Gerät, so wie er bei Joker-Antworten verwendet wird
    static func ichName() -> String {
        let id = UserDefaults.standard.string(forKey: "jokerIch") ?? ""
        let liste = JokerStand.shared.mitglieder
        return liste.first(where: { $0.id.uuidString == id })?.name ?? liste.first?.name ?? "Papa"
    }

    // Merker, damit die Cloud neu eingerichtet wird, wenn sich Modus, Familiencode oder Elternteil ändern
    static func marke(modus: String, code: String) -> String {
        modus + "|" + code + "|v5|" + (modus == "eltern" ? ichName() : "")
    }

    // Mitteilung nur an den Elternteil, dessen Tipp mit 👍 bewertet wurde
    static func aboDaumen(code: String, name: String) async throws {
        let predicate = NSPredicate(format: "familienCode == %@ AND absender == %@", code, name)
        let abo = CKQuerySubscription(recordType: "JokerDaumen", predicate: predicate,
                                      subscriptionID: "JokerDaumen-\(code)-\(name)",
                                      options: [.firesOnRecordCreation])
        let info = CKSubscription.NotificationInfo()
        info.alertBody = "👍 Dein Tipp hat geholfen! Das gibt Extra-Punkte in der Joker-Liga."
        info.soundName = "default"
        info.shouldBadge = true
        info.shouldSendContentAvailable = true
        abo.notificationInfo = info
        _ = try await db.save(abo)
    }
}
