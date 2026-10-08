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
// MARK: - Cloud: Joker, Ergebnisse und Mitteilungen (CloudKit)
// ============================================================

extension Notification.Name {
    nonisolated static let cloudPush = Notification.Name("yem1nCloudPush")
}

// Registriert das Gerät für Mitteilungen und meldet eingehende CloudKit-Pushes an die App.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        Mitteilungen.aufraeumen()
        return true
    }

    /// Wer die App öffnet, hat die Mitteilungen gesehen. Der rote Punkt am Symbol
    /// und die Einträge in der Mitteilungszentrale verschwinden dann.
    func applicationDidBecomeActive(_ application: UIApplication) {
        Mitteilungen.aufraeumen()
    }

    nonisolated func application(_ application: UIApplication,
                                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.set("registriert", forKey: "pushStatus")
    }

    nonisolated func application(_ application: UIApplication,
                                 didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UserDefaults.standard.set("Fehler: \(error.localizedDescription)", forKey: "pushStatus")
    }

    nonisolated func application(_ application: UIApplication,
                                 didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        NotificationCenter.default.post(name: .cloudPush, object: nil)
        return .newData
    }

    // Ohne diese Methode zeigt iOS bei geöffneter App kein Banner
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        NotificationCenter.default.post(name: .cloudPush, object: nil)
        // Ohne .badge: Solange die App offen ist, soll kein roter Punkt entstehen
        return [.banner, .list, .sound]
    }
}

enum Mitteilungen {
    /// Löscht den roten Punkt am App-Symbol und alle schon zugestellten Mitteilungen.
    /// Geplante Erinnerungen wie die Lernzeit bleiben erhalten.
    static func aufraeumen() {
        let zentrum = UNUserNotificationCenter.current()
        zentrum.removeAllDeliveredNotifications()
        zentrum.setBadgeCount(0) { _ in }
    }
}

// MARK: Datenmodelle aus der Cloud

struct CloudAntwort: Identifiable {
    let id: String
    let anfrageID: String
    let absender: String
    let emoji: String
    let text: String
    let erstellt: Date
    var daumen: Bool
}

struct CloudAnfrage: Identifiable {
    let id: String
    let kind: String
    let fach: String
    let uebung: String
    let text: String
    let erstellt: Date
    var antworten: [CloudAntwort]
}

@Observable
final class CloudStatus {
    static let shared = CloudStatus()
    var meldung = ""
    var arbeitet = false
}

// MARK: CloudKit-Zugriff

enum CloudDienst {
    static var db: CKDatabase { CKContainer.default().publicCloudDatabase }

    // nil bedeutet: iCloud ist bereit, sonst steht hier der Grund
    static func kontoProblem() async -> String? {
        do {
            let s = try await CKContainer.default().accountStatus()
            if s == .available { return nil }
            return "iCloud ist auf diesem Gerät nicht verfügbar. Bitte in den Einstellungen bei iCloud anmelden."
        } catch {
            return "iCloud-Fehler: \(error.localizedDescription)"
        }
    }

    static func fehlertext(_ error: Error) -> String {
        let t = error.localizedDescription
        if t.contains("queryable") || t.contains("not marked") {
            return "Im CloudKit Dashboard fehlt ein Index (Feld familienCode, Typ Queryable). \(t)"
        }
        if t.contains("record type") {
            return "Der Datensatztyp gibt es noch nicht. Bitte auf Cloud neu einrichten tippen. \(t)"
        }
        return t
    }

    // MARK: Lesen

    static func holeRecords(_ typ: String, code: String, limit: Int = 200) async throws -> [CKRecord] {
        let q = CKQuery(recordType: typ, predicate: NSPredicate(format: "familienCode == %@", code))
        let antwort = try await db.records(matching: q, resultsLimit: limit)
        var liste: [CKRecord] = []
        for (_, ergebnis) in antwort.matchResults {
            if let r = try? ergebnis.get() { liste.append(r) }
        }
        return liste
    }

    static func ladeJoker(code: String) async throws -> [CloudAnfrage] {
        let anfragen = try await holeRecords("JokerAnfrage", code: code)
        let antworten = (try? await holeRecords("JokerAntwort", code: code)) ?? []
        let daumen = (try? await holeRecords("JokerDaumen", code: code)) ?? []

        var daumenIDs = Set<String>()
        for d in daumen {
            if let id = d["antwortID"] as? String { daumenIDs.insert(id) }
        }
        var alle: [CloudAntwort] = []
        for r in antworten {
            alle.append(CloudAntwort(id: r.recordID.recordName,
                                     anfrageID: (r["anfrageID"] as? String) ?? "",
                                     absender: (r["absender"] as? String) ?? "?",
                                     emoji: (r["emoji"] as? String) ?? "🙂",
                                     text: (r["text"] as? String) ?? "",
                                     erstellt: r.creationDate ?? Date.distantPast,
                                     daumen: daumenIDs.contains(r.recordID.recordName)))
        }
        var liste: [CloudAnfrage] = []
        for r in anfragen {
            let id = r.recordID.recordName
            let meine = alle.filter { $0.anfrageID == id }.sorted { $0.erstellt < $1.erstellt }
            liste.append(CloudAnfrage(id: id,
                                      kind: (r["kind"] as? String) ?? "Kind",
                                      fach: (r["fach"] as? String) ?? "",
                                      uebung: (r["uebung"] as? String) ?? "",
                                      text: (r["text"] as? String) ?? "",
                                      erstellt: r.creationDate ?? Date.distantPast,
                                      antworten: meine))
        }
        return liste.sorted { $0.erstellt > $1.erstellt }
    }

    // MARK: Schreiben

    static func sendeJoker(code: String, kind: String, fach: String, uebung: String, text: String) async throws {
        let r = CKRecord(recordType: "JokerAnfrage")
        r["familienCode"] = code as CKRecordValue
        r["kind"] = kind as CKRecordValue
        r["fach"] = fach as CKRecordValue
        r["uebung"] = uebung as CKRecordValue
        r["text"] = text as CKRecordValue
        r["status"] = "offen" as CKRecordValue
        _ = try await db.save(r)
    }

    static func sendeAntwort(code: String, anfrageID: String, absender: String, emoji: String, text: String) async throws {
        let r = CKRecord(recordType: "JokerAntwort")
        r["familienCode"] = code as CKRecordValue
        r["anfrageID"] = anfrageID as CKRecordValue
        r["absender"] = absender as CKRecordValue
        r["emoji"] = emoji as CKRecordValue
        r["text"] = text as CKRecordValue
        _ = try await db.save(r)
    }

    static func sendeDaumen(code: String, anfrageID: String, antwortID: String, absender: String) async throws {
        let id = CKRecord.ID(recordName: "daumen-" + antwortID)
        let r = CKRecord(recordType: "JokerDaumen", recordID: id)
        r["familienCode"] = code as CKRecordValue
        r["anfrageID"] = anfrageID as CKRecordValue
        r["antwortID"] = antwortID as CKRecordValue
        r["absender"] = absender as CKRecordValue
        do {
            _ = try await db.save(r)
        } catch let fehler as CKError where fehler.code == .serverRecordChanged {
            // Daumen war schon vergeben
        }
    }

    static func sendeErgebnis(code: String, e: RundenErgebnis) async throws {
        let id = CKRecord.ID(recordName: "erg-" + e.eintragID)
        let r = CKRecord(recordType: "RundenErgebnis", recordID: id)
        r["familienCode"] = code as CKRecordValue
        r["eintragID"] = e.eintragID as CKRecordValue
        r["klasse"] = e.klasse as CKRecordValue
        r["fach"] = e.fach as CKRecordValue
        r["arbeit"] = e.arbeit as CKRecordValue
        r["uebung"] = e.uebung as CKRecordValue
        r["richtig"] = e.richtig as CKRecordValue
        r["gesamt"] = e.gesamt as CKRecordValue
        r["angesehen"] = e.angesehen as CKRecordValue
        r["sterne"] = e.sterne as CKRecordValue
        r["kind"] = e.kind as CKRecordValue
        r["zeitpunkt"] = e.zeitpunkt as CKRecordValue
        do {
            _ = try await db.save(r)
        } catch let fehler as CKError where fehler.code == .serverRecordChanged {
            // Ergebnis ist schon in der Cloud
        }
    }

    // MARK: Einrichtung (Datensatztypen anlegen und Mitteilungen abonnieren)

    private static func schemaBeispiel(_ typ: String, _ felder: [String: CKRecordValue]) async throws {
        let id = CKRecord.ID(recordName: "schema-" + typ)
        let r = CKRecord(recordType: typ, recordID: id)
        for (k, v) in felder { r[k] = v }
        do {
            _ = try await db.save(r)
        } catch let fehler as CKError where fehler.code == .serverRecordChanged {
            // gibt es schon
        }
    }

    static func schemaAnlegen() async throws {
        let code = "SCHEMA" as CKRecordValue
        try await schemaBeispiel("JokerAnfrage", ["familienCode": code, "kind": "Kind" as CKRecordValue,
                                                  "fach": "Mathe" as CKRecordValue, "uebung": "Test" as CKRecordValue,
                                                  "text": "Test" as CKRecordValue, "status": "offen" as CKRecordValue])
        try await schemaBeispiel("JokerAntwort", ["familienCode": code, "anfrageID": "x" as CKRecordValue,
                                                  "absender": "Test" as CKRecordValue, "emoji": "🙂" as CKRecordValue,
                                                  "text": "Test" as CKRecordValue])
        try await schemaBeispiel("JokerDaumen", ["familienCode": code, "anfrageID": "x" as CKRecordValue,
                                                 "antwortID": "x" as CKRecordValue, "absender": "Test" as CKRecordValue])
        try await schemaBeispiel("RundenErgebnis", ["familienCode": code, "eintragID": "schema" as CKRecordValue,
                                                   "klasse": "Test" as CKRecordValue, "fach": "Test" as CKRecordValue,
                                                   "arbeit": "Test" as CKRecordValue, "uebung": "Test" as CKRecordValue,
                                                   "richtig": 1 as CKRecordValue, "gesamt": 1 as CKRecordValue,
                                                   "angesehen": 0 as CKRecordValue, "sterne": 3 as CKRecordValue,
                                                   "zeitpunkt": Date() as CKRecordValue])
        try await schemaBeispiel("JokerNachschub", ["familienCode": code, "kind": "Test" as CKRecordValue])
        try await schemaBeispiel("JokerFreigabe", ["familienCode": code, "anzahl": 3 as CKRecordValue])
        try await schemaBeispiel("Haustier", ["familienCode": code, "json": "{}" as CKRecordValue])
        try await schemaBeispiel("HaustierPflege", ["familienCode": code, "art": "leckerli" as CKRecordValue,
                                                    "tag": "2026-1-1" as CKRecordValue, "absender": "Test" as CKRecordValue])
        try await schemaBeispiel("Lernpaket", ["familienCode": code, "klasse": "Test" as CKRecordValue,
                                               "fach": "Test" as CKRecordValue, "titel": "Test" as CKRecordValue,
                                               "json": "{}" as CKRecordValue, "aufgaben": 0 as CKRecordValue])
    }

    static func abo(typ: String, code: String, text: String) async throws {
        let predicate = NSPredicate(format: "familienCode == %@", code)
        let abo = CKQuerySubscription(recordType: typ, predicate: predicate,
                                      subscriptionID: "\(typ)-\(code)",
                                      options: [.firesOnRecordCreation])
        let info = CKSubscription.NotificationInfo()
        info.alertBody = text
        info.soundName = "default"
        info.shouldBadge = true
        info.shouldSendContentAvailable = true
        abo.notificationInfo = info
        _ = try await db.save(abo)
    }

    static func einrichten(code: String, rolle: String) async -> String {
        if let problem = await kontoProblem() { return problem }
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        do {
            try await schemaAnlegen()
        } catch {
            return "Datensatztypen anlegen nicht möglich: \(fehlertext(error))"
        }
        do {
            if rolle == "eltern" {
                try await abo(typ: "JokerAnfrage", code: code,
                              text: "🃏 Joker-Alarm! Dein Kind braucht Hilfe. Tippe und hilf als Erste:r!")
                try await abo(typ: "RundenErgebnis", code: code,
                              text: "🏆 Dein Kind hat eine Runde geschafft!")
                try await aboDaumen(code: code, name: ichName())
                try await abo(typ: "JokerNachschub", code: code,
                              text: "🃏 Dein Kind hat keine Joker mehr und fragt nach neuen. Tippe zum Freigeben!")
            } else {
                try await abo(typ: "JokerAntwort", code: code,
                              text: "💡 Du hast einen Tipp bekommen! Schau im Tab Joker nach.")
                try await abo(typ: "JokerFreigabe", code: code,
                              text: "🎉 Neue Joker! Du hast wieder alle Joker für heute.")
                try await abo(typ: "HaustierPflege", code: code,
                              text: "🐾 Dein Haustier hat von deiner Familie etwas bekommen!")
                try await abo(typ: "Lernpaket", code: code,
                              text: "📚 Neue Aufgaben für dich sind da! Öffne YEM1N und leg los. 💪")
            }
        } catch {
            return "Mitteilungen einrichten nicht möglich: \(fehlertext(error))"
        }
        return "Cloud ist bereit. Mitteilungen sind eingerichtet."
    }
}

// MARK: Ergebnisse senden und holen

enum CloudSync {
    private static var code: String { UserDefaults.standard.string(forKey: "familienCode") ?? "" }
    private static var modus: String { UserDefaults.standard.string(forKey: "modus") ?? "" }

    static func anstossen(_ context: ModelContext) {
        Task { await sendeOffene(context) }
    }

    // Kind-Gerät: alle noch nicht gesendeten Ergebnisse hochladen
    static func sendeOffene(_ context: ModelContext) async {
        guard modus == "kind", Familiencode.istGueltig(code) else { return }
        let beschreibung = FetchDescriptor<RundenErgebnis>(
            predicate: #Predicate { $0.quelle == "lokal" && $0.gesendet == false })
        guard let offene = try? context.fetch(beschreibung), !offene.isEmpty else { return }
        for e in offene {
            do {
                try await CloudDienst.sendeErgebnis(code: code, e: e)
                e.gesendet = true
            } catch {
                CloudStatus.shared.meldung = "Senden nicht möglich: \(CloudDienst.fehlertext(error))"
                break
            }
        }
        try? context.save()
    }

    // Eltern-Gerät: neue Ergebnisse der Kinder abholen
    static func holeErgebnisse(_ context: ModelContext) async {
        guard modus == "eltern", Familiencode.istGueltig(code) else { return }
        do {
            let records = try await CloudDienst.holeRecords("RundenErgebnis", code: code, limit: 300)
            let vorhanden = (try? context.fetch(FetchDescriptor<RundenErgebnis>())) ?? []
            var ids = Set<String>()
            for v in vorhanden { ids.insert(v.eintragID) }
            for r in records {
                guard let id = r["eintragID"] as? String, !ids.contains(id) else { continue }
                let kindName = ((r["kind"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let zeit = (r["zeitpunkt"] as? Date) ?? (r.creationDate ?? Date.now)
                if Kinder.istEntfernt(kindName, zeitpunkt: zeit) { continue }
                let e = RundenErgebnis(klasse: (r["klasse"] as? String) ?? "",
                                       fach: (r["fach"] as? String) ?? "",
                                       arbeit: (r["arbeit"] as? String) ?? "",
                                       uebung: (r["uebung"] as? String) ?? "",
                                       richtig: (r["richtig"] as? Int) ?? 0,
                                       gesamt: (r["gesamt"] as? Int) ?? 0,
                                       angesehen: (r["angesehen"] as? Int) ?? 0,
                                       zeitpunkt: zeit,
                                       quelle: "cloud")
                e.eintragID = id
                e.kind = kindName
                context.insert(e)
                ids.insert(id)
            }
            try? context.save()
        } catch {
            CloudStatus.shared.meldung = "Ergebnisse holen nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }

    // Kind-Gerät: Joker-Freigaben der Eltern anwenden (Joker wieder auf das Limit setzen)
    static func holeFreigaben() async {
        guard modus == "kind", Familiencode.istGueltig(code) else { return }
        guard let liste = try? await CloudDienst.holeRecords("JokerFreigabe", code: code, limit: 100) else { return }
        var benutzt = Set(UserDefaults.standard.stringArray(forKey: "jokerFreigaben") ?? [])
        var neu = false
        for r in liste where !benutzt.contains(r.recordID.recordName) {
            benutzt.insert(r.recordID.recordName)
            neu = true
        }
        if neu {
            JokerStand.shared.auffuellen()
            UserDefaults.standard.set(Array(benutzt), forKey: "jokerFreigaben")
        }
    }

    // Kind-Gerät: neue Klassenarbeiten und Übungssets laden. Vorhandene bleiben mit Fortschritt unberührt.
    // Ergebnis: Anzahl neuer Pakete, bei einem Fehler -1
    @discardableResult
    static func holePakete(_ context: ModelContext) async -> Int {
        var codes: [String] = []
        if Familiencode.istGueltig(code) { codes.append(code) }
        if let k = CloudDienst.klassenCloudCode { codes.append(k) }
        guard modus == "kind", !codes.isEmpty else { return 0 }
        do {
            var koepfe: [(paket: CloudPaket, herkunft: String)] = []
            for c in codes {
                for p in try await CloudDienst.ladePakete(code: c) { koepfe.append((p, c)) }
            }
            var neu = 0
            var ungueltig = 0
            let meineKlasse = (UserDefaults.standard.string(forKey: "kindKlasse") ?? "")
                .trimmingCharacters(in: .whitespaces).lowercased()
            for eintrag in koepfe {
                let k = eintrag.paket
                if !meineKlasse.isEmpty && k.klasse.lowercased() != meineKlasse { continue }
                if PaketImport.vorhanden(klasse: k.klasse, fach: k.fach, titel: k.titel, in: context) { continue }
                let text: String
                if eintrag.herkunft.hasPrefix("K-") {
                    // Pakete aus der Klasse müssen vom Admin unterschrieben sein
                    guard let signiert = try await CloudDienst.ladePaketSigniert(id: k.id),
                          let oeffentlich = await Klassensiegel.vertrauterSchluessel(eintrag.herkunft),
                          Klassensiegel.pruefe(code: eintrag.herkunft, json: signiert.json,
                                               sig: signiert.sig, oeffentlich: oeffentlich) else {
                        ungueltig += 1
                        continue
                    }
                    text = signiert.json
                } else {
                    guard let t = try await CloudDienst.ladePaketText(id: k.id) else { continue }
                    text = t
                }
                guard let daten = text.data(using: .utf8),
                      let paket = try? JSONDecoder().decode(ArbeitPaket.self, from: daten),
                      !paket.uebungen.isEmpty else { continue }
                if PaketImport.vorhanden(klasse: paket.klasse, fach: paket.fach, titel: paket.arbeit, in: context) { continue }
                PaketImport.einfuegen(paket, in: context)
                neu += 1
            }
            if neu > 0 { try? context.save() }
            if ungueltig > 0 {
                CloudStatus.shared.meldung = "\(ungueltig) Paket(e) der Klasse ohne gültige Unterschrift wurden ignoriert."
            }
            return neu
        } catch {
            CloudStatus.shared.meldung = "Neue Aufgaben holen nicht möglich: \(CloudDienst.fehlertext(error))"
            return -1
        }
    }

    private static let paketeSucheKey = "paketeLetzteSuche"
    private static let paketeSucheAbstand: TimeInterval = 600

    private static func paketeSucheFaellig(jetzt: Date = Date()) -> Bool {
        let t = UserDefaults.standard.double(forKey: paketeSucheKey)
        return t == 0 || jetzt.timeIntervalSince1970 - t >= paketeSucheAbstand
    }

    // Wird beim Öffnen der App, bei Mitteilungen und beim Aktualisieren aufgerufen
    nonisolated(unsafe) private static var letzterLauf = Date.distantPast

    static func aktiv(_ context: ModelContext, erzwingen: Bool = false) async {
        if !erzwingen && Date().timeIntervalSince(letzterLauf) < 20 { return }
        letzterLauf = Date()
        if modus == "kind" {
            await sendeOffene(context)
            await holeFreigaben()
            // Neue Pakete kommen per Mitteilung (erzwingen) oder über "Neue Aufgaben holen".
            // Beim bloßen Öffnen der App reicht es, wenn die Suche alle 10 Minuten läuft.
            if erzwingen || paketeSucheFaellig() {
                await holePakete(context)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: paketeSucheKey)
            }
        }
        if modus == "eltern" { await holeErgebnisse(context) }
        if !modus.isEmpty { await JokerCloud.shared.aktualisieren() }
    }
}

// MARK: Joker: Speicher der Cloud-Anfragen

@Observable
final class JokerCloud {
    static let shared = JokerCloud()
    var anfragen: [CloudAnfrage] = []
    var nachschub: [CloudNachschub] = []
    var freigaben: [Date] = []
    var erledigt: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "jokerErledigt") ?? [])
    var laedt = false
    var fehler = ""

    // Was im Postfach angezeigt wird (erledigte Anfragen sind nur ausgeblendet, die Punkte bleiben)
    var sichtbar: [CloudAnfrage] { anfragen.filter { !erledigt.contains($0.id) } }

    func erledige(_ id: String) {
        erledigt.insert(id)
        UserDefaults.standard.set(Array(erledigt), forKey: "jokerErledigt")
    }

    func alleErledigen() {
        for a in anfragen { erledigt.insert(a.id) }
        UserDefaults.standard.set(Array(erledigt), forKey: "jokerErledigt")
    }

    func aktualisieren() async {
        let code = UserDefaults.standard.string(forKey: "familienCode") ?? ""
        guard Familiencode.istGueltig(code) else {
            fehler = "Noch kein Familiencode."
            return
        }
        laedt = true
        do {
            anfragen = try await CloudDienst.ladeJoker(code: code)
            nachschub = (try? await CloudDienst.ladeNachschub(code: code)) ?? []
            freigaben = (try? await CloudDienst.ladeFreigaben(code: code)) ?? []
            if UserDefaults.standard.string(forKey: "modus") == "kind" {
                await CloudSync.holeFreigaben()
            }
            fehler = ""
        } catch {
            fehler = "Laden nicht möglich: \(CloudDienst.fehlertext(error))"
        }
        laedt = false
    }

    // Punkte aus der Cloud: erste Person +3, zweite +1, Daumen vom Kind +2
    func punkte(name: String, seit: Date?) -> Int {
        var summe = 0
        for a in anfragen {
            let sortiert = a.antworten.sorted { $0.erstellt < $1.erstellt }
            var reihenfolge: [String] = []
            for x in sortiert where !reihenfolge.contains(x.absender) {
                reihenfolge.append(x.absender)
            }
            for (platz, person) in reihenfolge.enumerated() where person == name {
                let zeit = sortiert.first(where: { $0.absender == person })?.erstellt ?? Date.distantPast
                let zaehlt = (seit == nil) || (zeit >= (seit ?? Date.distantPast))
                if zaehlt {
                    if platz == 0 { summe += 3 }
                    if platz == 1 { summe += 1 }
                }
            }
            for x in sortiert where x.absender == name && x.daumen {
                let zaehlt = (seit == nil) || (x.erstellt >= (seit ?? Date.distantPast))
                if zaehlt { summe += 2 }
            }
        }
        return summe
    }
}

// Kind-Gerät: Joker über die Cloud schicken. Gibt false zurück, wenn es nicht geklappt hat.
enum JokerSender {
    static func sende(text: String, fach: String, uebung: String) async -> Bool {
        let code = UserDefaults.standard.string(forKey: "familienCode") ?? ""
        guard Familiencode.istGueltig(code) else { return false }
        if await CloudDienst.kontoProblem() != nil { return false }
        let name = UserDefaults.standard.string(forKey: "kindName") ?? ""
        do {
            try await CloudDienst.sendeJoker(code: code, kind: name.isEmpty ? "Kind" : name,
                                             fach: fach, uebung: uebung, text: text)
            await JokerCloud.shared.aktualisieren()
            return true
        } catch {
            JokerCloud.shared.fehler = "Joker senden nicht möglich: \(CloudDienst.fehlertext(error))"
            return false
        }
    }
}

// MARK: Eltern: Joker-Postfach

struct JokerPostfachView: View {
    private let cloud = JokerCloud.shared
    @State private var antwortAuf: CloudAnfrage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Joker-Postfach")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                Spacer()
                if cloud.laedt { ProgressView().tint(Theme.gelb) }
                if !cloud.sichtbar.isEmpty {
                    Button {
                        withAnimation(.snappy) { cloud.alleErledigen() }
                    } label: {
                        Text("Alle erledigt")
                            .font(.system(.caption, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.navy)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.gelb, in: Capsule())
                    }
                    .buttonStyle(TastenStil())
                }
                Button { Task { await cloud.aktualisieren() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.gelb)
                }
            }
            if !cloud.fehler.isEmpty {
                Text(cloud.fehler)
                    .font(.footnote)
                    .foregroundStyle(Theme.koralle)
            }
            if cloud.sichtbar.isEmpty && cloud.fehler.isEmpty {
                Text(cloud.anfragen.isEmpty
                     ? "Noch keine Joker-Anfrage. Sobald dein Kind einen Joker nutzt, bekommst du eine Mitteilung und siehst sie hier."
                     : "Alles erledigt. 🎉 Neue Anfragen erscheinen hier von selbst.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            } else if !cloud.sichtbar.isEmpty {
                Text("Nach links oder rechts wischen blendet eine Anfrage als erledigt aus.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
            }
            ForEach(Array(cloud.sichtbar.prefix(8))) { a in
                karte(a)
                    .wischErledigt { cloud.erledige(a.id) }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
        .task {
            while !Task.isCancelled {
                await cloud.aktualisieren()
                try? await Task.sleep(for: .seconds(10))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
            Task { await cloud.aktualisieren() }
        }
        .sheet(item: $antwortAuf) { a in
            JokerAntwortSheet(anfrage: a)
                .preferredColorScheme(.dark)
                .tint(Theme.gelb)
        }
    }

    private func karte(_ a: CloudAnfrage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🃏 \(a.kind)")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                Spacer()
                Text(a.erstellt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
                Button {
                    withAnimation(.snappy) { cloud.erledige(a.id) }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.mint)
                }
                .buttonStyle(.plain)
            }
            Text(a.text)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
            ForEach(a.antworten) { x in
                HStack(alignment: .top, spacing: 6) {
                    Text(x.emoji)
                    Text("\(x.absender): \(x.text)")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                    if x.daumen { Text("👍") }
                }
            }
            Button { antwortAuf = a } label: {
                Text(a.antworten.isEmpty ? "Jetzt helfen" : "Auch antworten")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
        }
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct JokerAntwortSheet: View {
    let anfrage: CloudAnfrage
    @Environment(\.dismiss) private var dismiss
    @AppStorage("familienCode") private var familienCode = ""
    @AppStorage("jokerIch") private var jokerIch = ""
    @State private var text = ""
    @State private var sendet = false
    @State private var meldung = ""
    private let joker = JokerStand.shared

    private var tipps: [String] {
        if anfrage.fach == "Mathe" {
            return ["💡 Zerlege die Aufgabe in kleine Schritte.",
                    "🔁 Denk an die Umkehraufgabe.",
                    "✋ Zeichne es dir auf oder nimm die Finger zu Hilfe.",
                    "🧮 Fang mit einer Aufgabe an, die du schon kannst.",
                    "📖 Lies die Aufgabe noch einmal in Ruhe."]
        }
        return ["🔊 Sprich das Wort laut aus und höre genau hin.",
                "🖼️ Stell dir ein Bild dazu vor.",
                "📖 Schau in der Wortliste unter dem Thema nach.",
                "🔁 Erinnerst du dich an ein ähnliches Wort?",
                "🌟 Rate mutig, du schaffst das!"]
    }

    private var ich: JokerMitglied? {
        joker.mitglieder.first(where: { $0.id.uuidString == jokerIch }) ?? joker.mitglieder.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("🃏 \(anfrage.kind) braucht Hilfe")
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        Text(anfrage.text)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.white)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                        if !anfrage.antworten.isEmpty {
                            Text("Schon geantwortet")
                                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.textSanft)
                            ForEach(anfrage.antworten) { x in
                                Text("\(x.emoji) \(x.absender): \(x.text)")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textSanft)
                            }
                        }

                        Text("Tipp-Karten")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.textSanft)
                        ForEach(tipps, id: \.self) { t in
                            Button { text = t } label: {
                                Text(t)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Color.white)
                                    .multilineTextAlignment(.leading)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(TastenStil())
                        }

                        TextField("Oder schreibe deinen eigenen Tipp", text: $text, axis: .vertical)
                            .lineLimit(2...5)
                            .padding(14)
                            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Text("Bitte nicht die Lösung verraten. Dafür gibt es Punktabzug.")
                            .font(.footnote)
                            .foregroundStyle(Theme.himmel)
                        Text(RechtHinweise.freitext)
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)

                        if !meldung.isEmpty {
                            Text(meldung).font(.footnote).foregroundStyle(Theme.koralle)
                        }

                        GelberKnopf(titel: sendet ? "Sende ..." : "Tipp senden") { sende() }
                            .padding(.horizontal, -24)
                            .disabled(sendet || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Hilf mit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Schließen") { dismiss() } }
            }
        }
    }

    private func sende() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let m = ich else { return }
        sendet = true
        meldung = ""
        Task {
            do {
                try await CloudDienst.sendeAntwort(code: familienCode, anfrageID: anfrage.id,
                                                   absender: m.name, emoji: m.emoji, text: t)
                await JokerCloud.shared.aktualisieren()
                Haptik.erfolg()
                dismiss()
            } catch {
                meldung = "Senden nicht möglich: \(CloudDienst.fehlertext(error))"
            }
            sendet = false
        }
    }
}

// MARK: Kind: Joker-Tab mit den Tipps der Familie

struct KindJokerView: View {
    private let cloud = JokerCloud.shared
    private let joker = JokerStand.shared
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("familienCode") private var familienCode = ""
    @State private var nachschubLaeuft = false
    @State private var nachschubInfo = ""

    private var meinName: String { kindName.isEmpty ? "Kind" : kindName }

    private func nachschubAnfragen() async {
        guard Familiencode.istGueltig(familienCode) else {
            nachschubInfo = "Es fehlt noch ein Familiencode. Frag deine Eltern."
            return
        }
        nachschubLaeuft = true
        do {
            try await CloudDienst.sendeNachschub(code: familienCode, kind: meinName)
            Haptik.erfolg()
            nachschubInfo = "Anfrage ist raus. Deine Eltern bekommen eine Mitteilung."
        } catch {
            nachschubInfo = "Das hat nicht geklappt. Bist du online?"
        }
        nachschubLaeuft = false
    }
    private var meine: [CloudAnfrage] { cloud.anfragen.filter { $0.kind == meinName } }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kopf
                        if Familiencode.istGueltig(familienCode) {
                            nachschubBereich
                        } else {
                            Text("Dieses Gerät gehört zu keiner Familie, nur zu einer Klasse. Darum gibt es hier keine Joker-Antworten von Eltern. Wenn du bei einer Aufgabe auf 🃏 Joker tippst, kannst du die Frage stattdessen per Nachricht an jemanden schicken. Einen Familiencode trägst du in den Einstellungen ein.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSanft)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glasKarte(radius: 22)
                        }
                        namenFeld
                        if !cloud.fehler.isEmpty {
                            Text(cloud.fehler).font(.footnote).foregroundStyle(Theme.koralle)
                        }
                        if meine.isEmpty {
                            Text("Noch kein Joker benutzt. Wenn du bei einer Aufgabe nicht weiter kannst, tippe auf 🃏 Joker. Deine Familie bekommt sofort eine Mitteilung und schickt dir Tipps.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSanft)
                        }
                        ForEach(Array(meine.prefix(10))) { a in
                            karte(a)
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
                .refreshable { await cloud.aktualisieren() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                while !Task.isCancelled {
                    await cloud.aktualisieren()
                    try? await Task.sleep(for: .seconds(8))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
                Task { await cloud.aktualisieren() }
            }
        }
    }

    private var kopf: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Joker")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gelb)
            Text("Heute übrig: \(joker.uebrigHeute) von \(joker.limitProTag)")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSanft)
        }
    }

    private var nachschubBereich: some View {
        VStack(alignment: .leading, spacing: 6) {
            if joker.uebrigHeute < joker.limitProTag {
                Button {
                    Task { await nachschubAnfragen() }
                } label: {
                    Text(nachschubLaeuft ? "Wird gesendet ..." : "🃏 Neue Joker anfragen")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.navy)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Theme.gelb, in: Capsule())
                }
                .buttonStyle(TastenStil())
                .disabled(nachschubLaeuft)
            }
            if !nachschubInfo.isEmpty {
                Text(nachschubInfo)
                    .font(.footnote)
                    .foregroundStyle(Theme.himmel)
            }
        }
    }

    private var namenFeld: some View {
        HStack(spacing: 10) {
            Text("Ich bin")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
            Text(kindName.isEmpty ? "Noch kein Name (Einstellungen > Profil)" : kindName)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(kindName.isEmpty ? Theme.textSanft : Color.white)
            Spacer()
        }
    }

    private func karte(_ a: CloudAnfrage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(a.fach.isEmpty ? "Joker" : a.fach)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                Spacer()
                Text(a.erstellt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
            }
            Text(a.text)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
            if a.antworten.isEmpty {
                Text("Noch kein Tipp. Gleich kommt Hilfe!")
                    .font(.footnote)
                    .foregroundStyle(Theme.himmel)
            }
            ForEach(a.antworten) { x in
                HStack(alignment: .top, spacing: 8) {
                    Text(x.emoji).font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(x.absender)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        Text(x.text)
                            .font(.subheadline)
                            .foregroundStyle(Color.white)
                    }
                    Spacer()
                    if x.daumen {
                        Text("👍")
                    } else {
                        Button { daumen(a, x) } label: {
                            Text("👍 Hat geholfen")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Theme.navy)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.gelb, in: Capsule())
                        }
                        .buttonStyle(TastenStil())
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 24)
    }

    private func daumen(_ a: CloudAnfrage, _ x: CloudAntwort) {
        Task {
            try? await CloudDienst.sendeDaumen(code: familienCode, anfrageID: a.id,
                                               antwortID: x.id, absender: x.absender)
            Haptik.erfolg()
            await cloud.aktualisieren()
        }
    }
}

// MARK: Status und Neu-Einrichtung der Cloud

struct CloudStatusKarte: View {
    private let status = CloudStatus.shared
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cloud-Status")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text(status.meldung.isEmpty ? "Noch nicht geprüft." : status.meldung)
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
            if !Familiencode.istGueltig(familienCode) {
                Text("Es fehlt noch ein Familiencode (Einstellungen).")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.koralle)
            }
            Button {
                Task {
                    status.arbeitet = true
                    status.meldung = "Cloud wird eingerichtet ..."
                    let ergebnis = await CloudDienst.einrichten(code: familienCode, rolle: modus)
                    status.meldung = ergebnis
                    if ergebnis.hasPrefix("Cloud ist bereit") {
                        UserDefaults.standard.set(CloudDienst.marke(modus: modus, code: familienCode), forKey: "cloudEingerichtet")
                    }
                    await CloudSync.aktiv(context, erzwingen: true)
                    status.arbeitet = false
                }
            } label: {
                Text(status.arbeitet ? "Bitte warten ..." : "Cloud neu einrichten und prüfen")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            .disabled(status.arbeitet || !Familiencode.istGueltig(familienCode))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }
}
