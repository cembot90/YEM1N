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

// MARK: - App-Einstieg

@main
struct MatheApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let container: ModelContainer

    init() {
        // Geräte, die schon einen Namen eingetragen haben, brauchen den Einrichtungsassistenten nicht
        let vorgaben = UserDefaults.standard
        if vorgaben.object(forKey: "profilFertig") == nil {
            let hatName = !(vorgaben.string(forKey: "kindName") ?? "").isEmpty
            let hatIch = !(vorgaben.string(forKey: "jokerIch") ?? "").isEmpty
            if hatName || hatIch { vorgaben.set(true, forKey: "profilFertig") }
        }
        let schema = Schema([Klassenarbeit.self, Uebung.self, Aufgabe.self, RundenErgebnis.self])
        // SwiftData bleibt lokal auf dem Gerät. Ohne diese Zeile würde SwiftData
        // nach dem Aktivieren von iCloud die Daten automatisch in die private
        // iCloud-Datenbank spiegeln.
        // Ausdrücklich im normalen App-Ordner. Seit es die App Group fürs Widget gibt, würde SwiftData
        // sonst von selbst in den Gruppen-Ordner wechseln und die vorhandenen Daten wären weg.
        let konfiguration = ModelConfiguration(schema: schema, groupContainer: .none, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: konfiguration)
        } catch {
            fatalError("Datenbank konnte nicht geöffnet werden: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WurzelView()
                .tint(Theme.gelb)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}

// MARK: - Familiencode

enum Familiencode {
    private static let zeichen = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    // Zehn Zeichen ohne verwechselbare Buchstaben, angezeigt als XXXXX-XXXXX
    static func neu() -> String {
        let roh = (0..<10).map { _ in zeichen.randomElement() ?? "A" }
        return String(roh[0..<5]) + "-" + String(roh[5..<10])
    }

    static func bereinigt(_ text: String) -> String {
        let erlaubt = Set(zeichen)
        let roh = text.uppercased().filter { erlaubt.contains($0) }
        let kurz = String(roh.prefix(10))
        guard kurz.count > 5 else { return kurz }
        return String(kurz.prefix(5)) + "-" + String(kurz.dropFirst(5))
    }

    static func istGueltig(_ text: String) -> Bool {
        bereinigt(text).count == 11
    }
}

// MARK: - Beispieldaten für das Eltern-Dashboard

enum Beispieldaten {
    static func laden(in context: ModelContext) {
        let plan: [(String, Int)] = [
            ("Teilen mit Rest", 10), ("Einmaleins", 12), ("Kernaufgaben", 10),
            ("Zahlenmauern", 4), ("Sachaufgaben", 8), ("Punkt vor Strich", 10),
            ("Geteilt", 10), ("Alles gemischt", 12)
        ]
        for _ in 0..<16 {
            let (titel, gesamt) = plan.randomElement() ?? ("Einmaleins", 12)
            let schwach = titel == "Teilen mit Rest" || titel == "Sachaufgaben"
            let untergrenze = schwach ? gesamt * 3 / 10 : gesamt * 7 / 10
            let obergrenze = schwach ? gesamt * 6 / 10 : gesamt
            let richtig = Int.random(in: untergrenze...max(untergrenze, obergrenze))
            let wunsch = Int.random(in: 0...2) == 0 ? Int.random(in: 1...2) : 0
            let angesehen = min(wunsch, gesamt - richtig)
            let stunden = Int.random(in: 0...6) * 24 + Int.random(in: 0...8)
            let zeit = Calendar.current.date(byAdding: .hour, value: -stunden, to: Date.now) ?? Date.now
            context.insert(RundenErgebnis(klasse: "Klasse 3", fach: "Mathe",
                                          arbeit: "Klassenarbeit Nr. 1", uebung: titel,
                                          richtig: richtig, gesamt: gesamt,
                                          angesehen: angesehen, zeitpunkt: zeit,
                                          quelle: "demo"))
        }
    }

    static func loeschen(in context: ModelContext) {
        try? context.delete(model: RundenErgebnis.self,
                            where: #Predicate<RundenErgebnis> { $0.quelle == "demo" })
    }
}
