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

// MARK: - Datenmodell
// Hierarchie: Klassenarbeit (Klasse, Fach, Titel) > Uebung > Aufgabe

@Model
final class Klassenarbeit {
    var klasse: String = ""
    var fach: String = ""
    var titel: String = ""
    var erstellt: Date = Date.now
    var spezial: String = ""          // "", "fehlerheft", "training" oder "probe"
    @Relationship(deleteRule: .cascade, inverse: \Uebung.arbeit)
    var uebungen: [Uebung] = []

    init(klasse: String, fach: String, titel: String) {
        self.klasse = klasse
        self.fach = fach
        self.titel = titel
    }

    var sortierteUebungen: [Uebung] { uebungen.sorted { $0.reihenfolge < $1.reihenfolge } }
    var fertigeUebungen: Int { uebungen.filter { $0.istFertig }.count }
    var sterne: Int { uebungen.reduce(0) { $0 + $1.sterne } }
    var maxSterne: Int { uebungen.count * 3 }
}

@Model
final class Uebung {
    var titel: String = ""
    var gruppe: String = ""
    var symbol: String = ""
    var tipp: String = ""
    var reihenfolge: Int = 0
    var beste: Int = 0
    var sterne: Int = 0
    var arbeit: Klassenarbeit?
    @Relationship(deleteRule: .cascade, inverse: \Aufgabe.uebung)
    var aufgaben: [Aufgabe] = []

    init(titel: String, gruppe: String, symbol: String, tipp: String, reihenfolge: Int) {
        self.titel = titel
        self.gruppe = gruppe
        self.symbol = symbol
        self.tipp = tipp
        self.reihenfolge = reihenfolge
    }

    var sortierteAufgaben: [Aufgabe] { aufgaben.sorted { $0.reihenfolge < $1.reihenfolge } }
    var beantwortet: Int { aufgaben.filter { $0.erledigt }.count }
    var angesehenAnzahl: Int { aufgaben.filter { $0.angesehen }.count }
    var richtigAnzahl: Int { aufgaben.filter { $0.richtig == true }.count }
    var istFertig: Bool { !aufgaben.isEmpty && beantwortet == aufgaben.count }
    var laufend: Bool { beantwortet > 0 && !istFertig }

    func sternAnzahl(fuer gut: Int) -> Int {
        sterneFuer(gut: gut, gesamt: aufgaben.count)
    }
}

@Model
final class Aufgabe {
    var art: String = "zahl"          // zahl, rest, vergleich, mauer, text
    var frage: String = ""
    var rechnung: String = ""
    var hinweis: String = ""
    var erklaerung: String = ""
    var antwort: String = ""
    var antwort2: String = ""
    var reihenJSON: String = ""
    var reihenfolge: Int = 0
    var richtig: Bool?
    var angesehen: Bool = false       // Lösung wurde angezeigt (zählt weder richtig noch falsch)
    var quellKey: String = ""         // bei Kopien im Fehlerheft: Verweis auf die Originalaufgabe
    var gemeistert: Bool = false      // Fehler wurde im Fehlerheft richtig wiederholt
    var uebung: Uebung?

    var erledigt: Bool { richtig != nil || angesehen }

    init(art: String, frage: String, rechnung: String, hinweis: String,
         erklaerung: String, antwort: String, antwort2: String,
         reihenJSON: String, reihenfolge: Int) {
        self.art = art
        self.frage = frage
        self.rechnung = rechnung
        self.hinweis = hinweis
        self.erklaerung = erklaerung
        self.antwort = antwort
        self.antwort2 = antwort2
        self.reihenJSON = reihenJSON
        self.reihenfolge = reihenfolge
    }

    var reihen: [[Int]] {
        guard let d = reihenJSON.data(using: .utf8),
              let r = try? JSONDecoder().decode([[Int]].self, from: d) else { return [] }
        return r
    }

    // Faktoren aus "3 · 5 =" lesen (für das Punktefeld)
    var faktoren: (Int, Int)? {
        guard art == "zahl", !rechnung.contains("\n") else { return nil }
        let t = rechnung.replacingOccurrences(of: " =", with: "")
        let teile = t.components(separatedBy: " · ")
        guard teile.count == 2,
              let a = Int(teile[0]), let b = Int(teile[1]),
              (1...10).contains(a), (1...10).contains(b) else { return nil }
        return (a, b)
    }
}

// MARK: - Ergebnisse einer Runde
// Kind-Gerät: Warteschlange (quelle "lokal", gesendet false)
// Eltern-Gerät: Anzeige im Dashboard (quelle "cloud" oder "demo")

@Model
final class RundenErgebnis {
    var eintragID: String = UUID().uuidString
    var klasse: String = ""
    var fach: String = ""
    var arbeit: String = ""
    var uebung: String = ""
    var richtig: Int = 0
    var gesamt: Int = 0
    var angesehen: Int = 0
    var sterne: Int = 0
    var zeitpunkt: Date = Date.now
    var quelle: String = "lokal"
    var gesendet: Bool = false
    var kind: String = ""

    init(klasse: String, fach: String, arbeit: String, uebung: String,
         richtig: Int, gesamt: Int, angesehen: Int,
         zeitpunkt: Date = Date.now, quelle: String) {
        self.klasse = klasse
        self.fach = fach
        self.arbeit = arbeit
        self.uebung = uebung
        self.richtig = richtig
        self.gesamt = gesamt
        self.angesehen = angesehen
        self.sterne = sterneFuer(gut: richtig, gesamt: gesamt)
        self.zeitpunkt = zeitpunkt
        self.quelle = quelle
        self.kind = (UserDefaults.standard.string(forKey: "kindName") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var anteil: Double { gesamt > 0 ? Double(richtig) / Double(gesamt) : 0 }
}

func sterneFuer(gut: Int, gesamt: Int) -> Int {
    guard gesamt > 0 else { return 0 }
    let anteil = Double(gut) / Double(gesamt)
    if anteil >= 0.9 { return 3 }
    if anteil >= 0.7 { return 2 }
    if anteil >= 0.5 { return 1 }
    return 0
}

// MARK: - Import-Format (von Claude geliefert)

struct ArbeitPaket: Decodable {
    let klasse: String
    let fach: String
    let arbeit: String
    let uebungen: [UebungPaket]
}

struct UebungPaket: Decodable {
    let titel: String
    let gruppe: String?
    let symbol: String?
    let tipp: String?
    let aufgaben: [AufgabePaket]
}

struct AufgabePaket: Decodable {
    let art: String?
    let frage: String?
    let rechnung: String?
    let hinweis: String?
    let erklaerung: String?
    let antwort: String?
    let antwort2: String?
    let reihen: [[Int]]?
    // Nur für art "wahl" (Vorschule): Bild, türkische Frage, große Zahl/Buchstabe, Folge, Antwortknöpfe
    let bild: String?
    let tr: String?
    let gross: String?
    let folge: [String]?
    let optionen: [String]?

    enum CodingKeys: String, CodingKey {
        case art, frage, rechnung, hinweis, erklaerung, antwort, antwort2, reihen
        case bild, tr, gross, folge, optionen
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        art = try c.decodeIfPresent(String.self, forKey: .art)
        frage = try c.decodeIfPresent(String.self, forKey: .frage)
        rechnung = try c.decodeIfPresent(String.self, forKey: .rechnung)
        hinweis = try c.decodeIfPresent(String.self, forKey: .hinweis)
        erklaerung = try c.decodeIfPresent(String.self, forKey: .erklaerung)
        antwort = AufgabePaket.text(c, .antwort)
        antwort2 = AufgabePaket.text(c, .antwort2)
        reihen = try c.decodeIfPresent([[Int]].self, forKey: .reihen)
        bild = try c.decodeIfPresent(String.self, forKey: .bild)
        tr = try c.decodeIfPresent(String.self, forKey: .tr)
        gross = AufgabePaket.text(c, .gross)
        folge = try? c.decodeIfPresent([String].self, forKey: .folge)
        optionen = try? c.decodeIfPresent([String].self, forKey: .optionen)
    }

    // Antworten dürfen als Text oder als Zahl im JSON stehen
    private static func text(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
        if let s = try? c.decode(String.self, forKey: key) { return s }
        if let i = try? c.decode(Int.self, forKey: key) { return String(i) }
        return nil
    }
}

// MARK: - Haptik

enum Haptik {
    static func erfolg() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func fehler() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func leicht() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

// MARK: - CloudKit (Stufe 1: nur Verbindungstest)

enum CloudKitDienst {
    // Schreibt einen Test-Datensatz in die öffentliche CloudKit-Datenbank.
    // Im Development-Umfeld legt CloudKit den Datensatztyp dabei automatisch an.
    static func verbindungTesten() async -> String {
        let container = CKContainer.default()
        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                return "iCloud ist auf diesem Gerät nicht verfügbar (Status \(status.rawValue)). Bitte in den Einstellungen bei iCloud anmelden."
            }
            let datensatz = CKRecord(recordType: "RundenErgebnis")
            datensatz["familienCode"] = "TEST" as CKRecordValue
            datensatz["uebung"] = "Verbindungstest" as CKRecordValue
            datensatz["richtig"] = 9 as CKRecordValue
            datensatz["gesamt"] = 10 as CKRecordValue
            datensatz["angesehen"] = 0 as CKRecordValue
            datensatz["zeitpunkt"] = Date() as CKRecordValue
            let gespeichert = try await container.publicCloudDatabase.save(datensatz)
            return "Verbindung steht. Test-Datensatz gespeichert:\n\(gespeichert.recordID.recordName)"
        } catch {
            return "Fehler: \(error.localizedDescription)"
        }
    }
}
