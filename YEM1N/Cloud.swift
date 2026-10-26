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
// MARK: - Cloud: Joker, Ergebnisse und Mitteilungen
// ============================================================
//
// Alles, was die Familie austauscht, geht über den Familien-Dienst (Protokoll 2, FamilienModell.swift).
// CloudKit wird nur noch zum Lesen öffentlicher, unterschriebener Klassenpakete benutzt (CloudPakete.swift).

extension Notification.Name {
    nonisolated static let cloudPush = Notification.Name("yem1nCloudPush")
    /// Die Mitteilung zum Wochenbericht wurde angetippt.
    nonisolated static let oeffneBericht = Notification.Name("yem1nOeffneBericht")
    /// Die Liste der Vorlese-Stimmen ist neu geladen.
    nonisolated static let stimmenGeladen = Notification.Name("yem1nStimmenGeladen")
    /// Eine Mitteilung wurde angetippt. Im Objekt steht der Bereich, zum Beispiel "joker".
    nonisolated static let oeffneBereich = Notification.Name("yem1nOeffneBereich")
}

// Registriert das Gerät für Mitteilungen und meldet eingehende Mitteilungen an die App.
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
        let kennung = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set("registriert", forKey: "pushStatus")
        Task { @MainActor in FamilienModell.shared.pushTokenMerken(kennung) }
    }

    nonisolated func application(_ application: UIApplication,
                                 didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UserDefaults.standard.set("Fehler: \(error.localizedDescription)", forKey: "pushStatus")
    }

    nonisolated func application(_ application: UIApplication,
                                 didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .cloudPush, object: nil)
        }
        return .newData
    }

    // Ohne diese Methode zeigt iOS bei geöffneter App kein Banner.
    // Wichtig: iOS erwartet die Antwort auf dem Haupt-Thread. Die async-Variante dieser
    // Methoden antwortet aus einem Hintergrund-Thread, und das brachte die App zum Absturz.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .cloudPush, object: nil)
            // Ohne .badge: Solange die App offen ist, soll kein roter Punkt entstehen
            completionHandler([.banner, .list, .sound])
        }
    }

    // Tipp auf eine Mitteilung. Die App springt in den passenden Bereich:
    // Wochenbericht zur Übersicht, Joker-Mitteilungen zum Joker, Haustier zum Haustier.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let inhalt = response.notification.request.content.userInfo
        let ziel = inhalt["ziel"] as? String
        let kennung = response.notification.request.identifier
        let bereich = MitteilungsZiel.bereich(ziel: ziel, kennung: kennung, typ: inhalt["typ"] as? String)
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if bereich == "bericht" {
                    UserDefaults.standard.set(true, forKey: Wochenbericht.oeffnenSchluessel)
                    NotificationCenter.default.post(name: .oeffneBericht, object: nil)
                } else if let bereich {
                    // Gemerkt für den Fall, dass die App gerade erst startet und noch niemand zuhört
                    UserDefaults.standard.set(bereich, forKey: MitteilungsZiel.merkSchluessel)
                    NotificationCenter.default.post(name: .oeffneBereich, object: bereich)
                }
            }
            completionHandler()
        }
    }
}

/// Entscheidet, wohin ein Tipp auf eine Mitteilung führt.
enum MitteilungsZiel {
    /// Hier merkt sich die App den Bereich, bis die Reiter ihn übernommen haben.
    nonisolated static let merkSchluessel = "oeffneBereichGemerkt"

    /// Liest den gemerkten Bereich einmal und löscht ihn dann.
    static func abholen() -> String? {
        let b = UserDefaults.standard.string(forKey: merkSchluessel)
        UserDefaults.standard.removeObject(forKey: merkSchluessel)
        return b
    }

    /// "bericht", "joker", "haustier", "schule", "duell", "familie" oder nil (dann bleibt die App, wo sie ist).
    /// [typ] ist die Art des Eintrags, wie der Familien-Dienst sie in der Mitteilung mitschickt.
    nonisolated static func bereich(ziel: String?, kennung: String, typ: String? = nil) -> String? {
        if ziel == "bericht" || kennung == "wochenbericht" { return "bericht" }
        switch typ {
        case "frage", "antwort", "daumen", "nachschub", "freigabe": return "joker"
        case "pflege": return "haustier"
        case "paket": return "schule"
        case "duell", "duellantwort": return "duell"
        case "geraet": return "familie"
        default: return nil
        }
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

    /// Fragt nach der Erlaubnis für Mitteilungen. Sie sind neutral, ohne Namen und ohne Inhalt.
    static func erlaubnisFragen() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
    }
}

// MARK: Datenmodelle aus der Cloud

struct CloudAntwort: Identifiable, Equatable {
    let id: String
    let anfrageID: String
    let absender: String
    let emoji: String
    let text: String
    let erstellt: Date
    var daumen: Bool
}

struct CloudAnfrage: Identifiable, Equatable {
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

// MARK: Zugriff auf den Familien-Dienst

enum CloudDienst {
    /// Die öffentliche CloudKit-Datenbank. Nur noch für Pakete der Klasse (lesen, unterschrieben).
    static var db: CKDatabase { CKContainer.default().publicCloudDatabase }

    static func fehlertext(_ error: Error) -> String {
        if let f = error as? FamilienFehler { return f.text }
        let t = error.localizedDescription
        if t.contains("queryable") || t.contains("not marked") {
            return "Im CloudKit Dashboard fehlt ein Index. \(t)"
        }
        if t.contains("record type") {
            return "Den Datensatztyp gibt es in CloudKit noch nicht. \(t)"
        }
        return t
    }

    static var familie: FamilienModell { FamilienModell.shared }

    /// Legt einen Eintrag beim Familien-Dienst ab. Wirft einen [FamilienFehler], wenn es nicht klappt.
    @discardableResult
    static func sende(_ body: [String: Any]) async throws -> FamilienAntwort {
        let a = await familie.senden(body)
        try a.pruefen()
        return a
    }

    /// Liest alle Einträge einer Art. Wirft einen [FamilienFehler], wenn schon die erste Seite fehlt.
    static func lies(_ typ: String) async throws -> [FamilienEintrag] {
        guard familie.aktiv else { throw FamilienFehler(status: -3) }
        guard let liste = await familie.lesen(typ) else { throw FamilienFehler(status: 0) }
        return liste
    }

    // MARK: Joker lesen

    static func ladeJoker() async throws -> [CloudAnfrage] {
        let fragen = try await lies(FamilienProtokoll.typFrage)
        let antworten = (try? await lies(FamilienProtokoll.typAntwort)) ?? []
        let daumen = (try? await lies(FamilienProtokoll.typDaumen)) ?? []

        let daumenIDs = Set(daumen.map { $0.text("antwortId") })
        let alle = antworten.map { e in
            CloudAntwort(id: e.id,
                         anfrageID: e.text("frageId"),
                         absender: e.absender.isEmpty ? "?" : e.absender,
                         emoji: e.text("emoji", ersatz: "🙂"),
                         text: e.text("text"),
                         erstellt: e.erstelltDatum,
                         daumen: daumenIDs.contains(e.id))
        }
        let liste = fragen.map { e in
            CloudAnfrage(id: e.id,
                         kind: e.text("kind", ersatz: "Kind"),
                         fach: e.text("fach"),
                         uebung: e.text("uebung"),
                         text: e.text("text"),
                         erstellt: e.erstelltDatum,
                         antworten: alle.filter { $0.anfrageID == e.id }.sorted { $0.erstellt < $1.erstellt })
        }
        return liste.sorted { $0.erstellt > $1.erstellt }
    }

    // MARK: Schreiben

    static func sendeJoker(kind: String, fach: String, uebung: String, text: String) async throws {
        try await sende(FamilienProtokoll.frage(id: FamilienProtokoll.neueKennung("frage"),
                                                kind: kind, fach: fach, uebung: uebung, text: text))
    }

    /// Den Namen des Absenders setzt der Dienst aus dem Namen des Geräts.
    static func sendeAntwort(anfrageID: String, emoji: String, text: String) async throws {
        try await sende(FamilienProtokoll.antwort(id: FamilienProtokoll.neueKennung("antwort"),
                                                  frageId: anfrageID, emoji: emoji, text: text))
    }

    static func sendeDaumen(anfrageID: String, antwortID: String) async throws {
        try await sende(FamilienProtokoll.daumen(frageId: anfrageID, antwortId: antwortID))
    }

    static func sendeErgebnis(_ e: RundenErgebnis) async throws {
        let d = ErgebnisDaten(id: "erg-" + e.eintragID, klasse: e.klasse, fach: e.fach, arbeit: e.arbeit,
                              uebung: e.uebung, richtig: e.richtig, gesamt: e.gesamt, angesehen: e.angesehen,
                              sterne: e.sterne, kind: e.kind,
                              zeitpunkt: Int64(e.zeitpunkt.timeIntervalSince1970 * 1000), details: e.details)
        try await sende(FamilienProtokoll.ergebnis(d))
    }

    static func sendeNachschub(kind: String) async throws {
        try await sende(FamilienProtokoll.nachschub(id: FamilienProtokoll.neueKennung("nachschub"), kind: kind))
    }

    static func sendeFreigabe() async throws {
        try await sende(FamilienProtokoll.freigabe(id: FamilienProtokoll.neueKennung("freigabe"), anzahl: 3))
    }
}

// MARK: Ergebnisse senden und holen

enum CloudSync {
    private static var modus: String { UserDefaults.standard.string(forKey: "modus") ?? "" }
    private static var verbunden: Bool { FamilienModell.shared.aktiv }

    static func anstossen(_ context: ModelContext) {
        Task { await sendeOffene(context) }
    }

    // Kind-Gerät: alle noch nicht gesendeten Ergebnisse hochladen
    static func sendeOffene(_ context: ModelContext) async {
        guard modus == "kind", verbunden else { return }
        let beschreibung = FetchDescriptor<RundenErgebnis>(
            predicate: #Predicate { $0.quelle == "lokal" && $0.gesendet == false })
        guard let offene = try? context.fetch(beschreibung), !offene.isEmpty else { return }
        for e in offene {
            do {
                try await CloudDienst.sendeErgebnis(e)
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
        guard modus == "eltern", verbunden else { return }
        do {
            let eintraege = try await CloudDienst.lies(FamilienProtokoll.typErgebnis)
            let vorhanden = (try? context.fetch(FetchDescriptor<RundenErgebnis>())) ?? []
            var ids = Set<String>()
            for v in vorhanden { ids.insert(v.eintragID) }
            for r in eintraege {
                let id = r.id.hasPrefix("erg-") ? String(r.id.dropFirst(4)) : r.id
                guard !ids.contains(id) else { continue }
                let kindName = r.text("kind").trimmingCharacters(in: .whitespacesAndNewlines)
                let zeit = r.zahl("zeitpunkt") > 0
                    ? Date(timeIntervalSince1970: Double(r.zahl("zeitpunkt")) / 1000)
                    : r.erstelltDatum
                if Kinder.istEntfernt(kindName, zeitpunkt: zeit) { continue }
                let e = RundenErgebnis(klasse: r.text("klasse"),
                                       fach: r.text("fach"),
                                       arbeit: r.text("arbeit"),
                                       uebung: r.text("uebung"),
                                       richtig: Int(r.zahl("richtig")),
                                       gesamt: Int(r.zahl("gesamt")),
                                       angesehen: Int(r.zahl("angesehen")),
                                       zeitpunkt: zeit,
                                       quelle: "cloud")
                e.eintragID = id
                e.kind = kindName
                e.details = r.text("details")
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
        guard modus == "kind", verbunden else { return }
        guard let liste = try? await CloudDienst.lies(FamilienProtokoll.typFreigabe) else { return }
        var benutzt = Set(UserDefaults.standard.stringArray(forKey: "jokerFreigaben") ?? [])
        var neu = false
        for e in liste where !benutzt.contains(e.id) {
            benutzt.insert(e.id)
            neu = true
        }
        if neu {
            JokerStand.shared.auffuellen()
            UserDefaults.standard.set(Array(benutzt), forKey: "jokerFreigaben")
        }
    }

    // Kind-Gerät: neue Klassenarbeiten und Übungssets laden. Vorhandene bleiben mit Fortschritt unberührt.
    // Pakete der Familie kommen vom Familien-Dienst, Pakete der Klasse aus CloudKit (nur mit gültiger Unterschrift).
    // Ergebnis: Anzahl neuer Pakete, bei einem Fehler -1
    @discardableResult
    static func holePakete(_ context: ModelContext) async -> Int {
        let klasse = CloudDienst.klassenCloudCode
        guard modus == "kind", verbunden || klasse != nil else { return 0 }
        let meineKlasse = (UserDefaults.standard.string(forKey: "kindKlasse") ?? "")
            .trimmingCharacters(in: .whitespaces).lowercased()
        var neu = 0
        var fehlerText: String?

        if verbunden {
            do {
                for kopf in try await CloudDienst.ladeFamilienPakete() {
                    if !meineKlasse.isEmpty && kopf.klasse.lowercased() != meineKlasse { continue }
                    if PaketImport.vorhanden(klasse: kopf.klasse, fach: kopf.fach, titel: kopf.titel, in: context) { continue }
                    guard let paket = kopf.paket, !paket.uebungen.isEmpty else { continue }
                    if PaketImport.vorhanden(klasse: paket.klasse, fach: paket.fach, titel: paket.arbeit, in: context) { continue }
                    PaketImport.einfuegen(paket, in: context)
                    neu += 1
                }
            } catch {
                fehlerText = "Neue Aufgaben holen nicht möglich: \(CloudDienst.fehlertext(error))"
            }
        }

        if let klasse {
            do {
                var ungueltig = 0
                var gruende = Set<Klassensiegel.Ablehnung>()
                for k in try await CloudDienst.ladePakete(code: klasse) {
                    if !meineKlasse.isEmpty && k.klasse.lowercased() != meineKlasse { continue }
                    if PaketImport.vorhanden(klasse: k.klasse, fach: k.fach, titel: k.titel, in: context) { continue }
                    // Pakete aus der Klasse müssen vom Admin unterschrieben sein
                    guard let signiert = try await CloudDienst.ladePaketSigniert(id: k.id) else {
                        ungueltig += 1
                        gruende.insert(.ohneUnterschrift)
                        continue
                    }
                    let stand = await Klassensiegel.schluesselStand(klasse)
                    guard let oeffentlich = stand.schluessel else {
                        ungueltig += 1
                        gruende.insert(stand == .gewechselt ? .schluesselGewechselt : .keinSchluessel)
                        continue
                    }
                    guard Klassensiegel.pruefe(code: klasse, json: signiert.json,
                                               sig: signiert.sig, oeffentlich: oeffentlich) else {
                        ungueltig += 1
                        gruende.insert(.unterschriftFalsch)
                        continue
                    }
                    guard let daten = signiert.json.data(using: .utf8),
                          let paket = try? JSONDecoder().decode(ArbeitPaket.self, from: daten),
                          !paket.uebungen.isEmpty else { continue }
                    if PaketImport.vorhanden(klasse: paket.klasse, fach: paket.fach, titel: paket.arbeit, in: context) { continue }
                    PaketImport.einfuegen(paket, in: context)
                    neu += 1
                }
                if ungueltig > 0 {
                    let warum = gruende.map { $0.text }.joined(separator: "\n")
                    CloudStatus.shared.meldung = "\(ungueltig) Paket(e) der Klasse ohne gültige Unterschrift wurden ignoriert.\n" + warum
                }
            } catch {
                fehlerText = "Neue Aufgaben der Klasse holen nicht möglich: \(CloudDienst.fehlertext(error))"
            }
        }

        if neu > 0 { try? context.save() }
        if let fehlerText {
            CloudStatus.shared.meldung = fehlerText
            return neu > 0 ? neu : -1
        }
        return neu
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
        let familie = FamilienModell.shared
        // Ein Gerät, das noch auf die Freigabe wartet, fragt nur nach seinem Stand.
        if familie.zugang != nil && !familie.aktiv {
            await familie.statusPruefen()
        }
        if familie.aktiv {
            await familie.pushAnmelden()
            if modus == "eltern" { await familie.geraeteLaden() }
        }
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
        guard FamilienModell.shared.aktiv else {
            let t = FamilienModell.shared.wartet
                ? "Dieses Gerät wartet noch auf die Freigabe der Eltern."
                : "Dieses Gerät gehört noch zu keiner Familie."
            if fehler != t { fehler = t }
            return
        }
        // Läuft schon ein Abruf, braucht es keinen zweiten gleichzeitig
        guard !laedt else { return }
        laedt = true
        defer { laedt = false }
        // Nur ändern, was sich wirklich geändert hat. Jede Änderung zeichnet die Seite neu,
        // und das ruckelt auf älteren iPhones, wenn es alle paar Sekunden passiert.
        do {
            let neu = try await CloudDienst.ladeJoker()
            if neu != anfragen { anfragen = neu }
            let n = (try? await CloudDienst.ladeNachschub()) ?? []
            if n != nachschub { nachschub = n }
            let f = (try? await CloudDienst.ladeFreigaben()) ?? []
            if f != freigaben { freigaben = f }
            if UserDefaults.standard.string(forKey: "modus") == "kind" {
                await CloudSync.holeFreigaben()
            }
            if !fehler.isEmpty { fehler = "" }
        } catch {
            let t = "Laden nicht möglich: \(CloudDienst.fehlertext(error))"
            if fehler != t { fehler = t }
        }
    }

    /// Wie oft offene Seiten nachsehen. Neue Joker kommen sonst sofort über die Mitteilung.
    static let nachsehenAlle: Duration = .seconds(30)

    /// Schaut regelmäßig nach, aber nur, solange die App im Vordergrund ist.
    func nachsehenSolangeOffen() async {
        while !Task.isCancelled {
            if UIApplication.shared.applicationState == .active {
                await aktualisieren()
            }
            try? await Task.sleep(for: Self.nachsehenAlle)
        }
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
        guard FamilienModell.shared.aktiv else { return false }
        let name = UserDefaults.standard.string(forKey: "kindName") ?? ""
        do {
            try await CloudDienst.sendeJoker(kind: name.isEmpty ? "Kind" : name,
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
        .task { await cloud.nachsehenSolangeOffen() }
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
                try await CloudDienst.sendeAntwort(anfrageID: anfrage.id, emoji: m.emoji, text: t)
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
    private let familie = FamilienModell.shared
    @AppStorage("kindName") private var kindName = ""
    @State private var nachschubLaeuft = false
    @State private var nachschubInfo = ""

    private var meinName: String { kindName.isEmpty ? "Kind" : kindName }

    private func nachschubAnfragen() async {
        guard familie.aktiv else {
            nachschubInfo = "Dein Gerät ist noch nicht mit deiner Familie verbunden. Frag deine Eltern."
            return
        }
        nachschubLaeuft = true
        do {
            try await CloudDienst.sendeNachschub(kind: meinName)
            Haptik.erfolg()
            nachschubInfo = "Anfrage ist raus. Deine Eltern bekommen eine Mitteilung."
        } catch {
            nachschubInfo = "Das hat nicht geklappt. Bist du online?"
        }
        nachschubLaeuft = false
    }
    private var meine: [CloudAnfrage] { cloud.anfragen.filter { $0.kind == meinName } }

    /// true: ohne eigenen Rahmen und ohne Kopf, zum Einbauen in den Reiter "Ich".
    var eingebettet = false

    var body: some View {
        if eingebettet {
            inhalt
        } else {
            NavigationStack {
                HeroSeite {
                    HeroKopf(kicker: "Joker", titel: "Hilfe von deiner Familie",
                             untertitel: "Tippe bei einer Aufgabe auf 🃏, dann schickt dir deine Familie Tipps.",
                             bild: "🃏",
                             chips: [HeroChip(text: "Heute übrig: \(joker.uebrigHeute) von \(joker.limitProTag)",
                                              hervorgehoben: joker.uebrigHeute > 0)])
                    inhalt
                }
                .refreshable { await cloud.aktualisieren() }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    private var inhalt: some View {
        VStack(alignment: .leading, spacing: 16) {
            if familie.aktiv {
                nachschubBereich
            } else {
                Text(familie.wartet
                     ? "Dein Gerät wartet noch auf das Okay deiner Eltern. Sobald sie es erlaubt haben, kommen hier die Tipps deiner Familie an."
                     : "Dein Gerät ist noch nicht mit deiner Familie verbunden. Darum gibt es hier keine Tipps von deinen Eltern. Wenn du bei einer Aufgabe auf 🃏 Joker tippst, kannst du die Frage stattdessen per Nachricht an jemanden schicken. Bitte deine Eltern, dich in den Einstellungen bei Familie zu verbinden.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSanft)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glasKarte(radius: 22)
            }
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
        .task { await cloud.nachsehenSolangeOffen() }
        .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
            Task { await cloud.aktualisieren() }
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
            try? await CloudDienst.sendeDaumen(anfrageID: a.id, antwortID: x.id)
            Haptik.erfolg()
            await cloud.aktualisieren()
        }
    }
}

// MARK: Status der Cloud

struct CloudStatusKarte: View {
    private let status = CloudStatus.shared
    private let familie = FamilienModell.shared
    @Environment(\.modelContext) private var context

    private var zustand: String {
        guard let z = familie.zugang else {
            return CloudDienst.klassenCloudCode != nil
                ? "Dieses Gerät gehört zu keiner Familie. Aufgaben der Klasse kommen trotzdem an."
                : "Dieses Gerät gehört zu keiner Familie."
        }
        if familie.abgelehnt { return "Die Eltern haben dieses Gerät nicht freigegeben." }
        if familie.wartet { return "Wartet auf die Freigabe der Eltern." }
        return "Verbunden als \(z.name) (\(z.istEltern ? "Eltern-Gerät" : "Kind-Gerät"))."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cloud-Status")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text(zustand)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(familie.aktiv ? Theme.mint : Theme.koralle)
            Text(status.meldung.isEmpty ? "Noch nicht geprüft." : status.meldung)
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
            Button {
                Task {
                    status.arbeitet = true
                    status.meldung = "Verbindung wird geprüft ..."
                    status.meldung = await familie.verbindungTesten()
                    await CloudSync.aktiv(context, erzwingen: true)
                    status.arbeitet = false
                }
            } label: {
                Text(status.arbeitet ? "Bitte warten ..." : "Verbindung prüfen und abgleichen")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            .disabled(status.arbeitet || familie.zugang == nil)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }
}
