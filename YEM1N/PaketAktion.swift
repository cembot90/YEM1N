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
// MARK: - Pakete aus Zwischenablage oder Datei, Wochenbericht, Notizblock
// ============================================================

@MainActor
enum PaketAktion {
    static func lese(_ roh: String) -> (paket: ArbeitPaket, text: String)? {
        let text = PaketJSON.bereinigt(roh)
        guard let daten = text.data(using: .utf8),
              let p = try? JSONDecoder().decode(ArbeitPaket.self, from: daten),
              !p.uebungen.isEmpty,
              p.uebungen.allSatisfy({ !$0.aufgaben.isEmpty }) else { return nil }
        // Vorschul-Aufgaben: 2 bis 4 Knöpfe, die Antwort muss einer davon sein
        for u in p.uebungen {
            for a in u.aufgaben where a.art == "wahl" {
                guard let o = a.optionen, (2...4).contains(o.count),
                      let r = a.antwort, o.contains(r),
                      !(a.frage ?? "").isEmpty else { return nil }
            }
        }
        return (p, text)
    }

    static func anzahl(_ p: ArbeitPaket) -> Int {
        p.uebungen.reduce(0) { $0 + $1.aufgaben.count }
    }

    // Nur auf diesem Gerät importieren
    static func lokal(_ p: ArbeitPaket, context: ModelContext) -> String {
        if PaketImport.vorhanden(klasse: p.klasse, fach: p.fach, titel: p.arbeit, in: context) {
            return "\(p.arbeit) ist auf diesem Gerät schon vorhanden."
        }
        PaketImport.einfuegen(p, in: context)
        try? context.save()
        return "\(p.arbeit) wurde importiert."
    }

    // Eltern: in die Cloud stellen und auch hier importieren
    static func veroeffentliche(_ p: ArbeitPaket, text: String, context: ModelContext, klasse: Bool = false) async -> String {
        let familie = UserDefaults.standard.string(forKey: "familienCode") ?? ""
        let ziel: String
        if klasse {
            guard let k = CloudDienst.klassenCloudCode else {
                return "Bitte zuerst im Tab Einstellungen einen Klassencode eintragen oder erzeugen."
            }
            ziel = k
        } else {
            guard Familiencode.istGueltig(familie) else {
                return "Bitte zuerst im Tab Einstellungen einen Familiencode eintragen."
            }
            ziel = familie
        }
        do {
            try await CloudDienst.hochladen(code: ziel, paket: p, json: text)
            if !PaketImport.vorhanden(klasse: p.klasse, fach: p.fach, titel: p.arbeit, in: context) {
                PaketImport.einfuegen(p, in: context)
                try? context.save()
            }
            return klasse ? "\(p.arbeit) ist beim Klassencode. Alle Geräte mit diesem Code laden es automatisch."
                          : "\(p.arbeit) ist in der Cloud. Die Kind-Geräte laden es automatisch."
        } catch {
            return "Hochladen nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }
}

enum Wochenbericht {
    // Erinnerung jeden Sonntag um 18 Uhr, der Bericht selbst steht im Eltern-Dashboard
    static func planen() async {
        let zentrale = UNUserNotificationCenter.current()
        let einstellungen = await zentrale.notificationSettings()
        guard einstellungen.authorizationStatus == .authorized else { return }
        let inhalt = UNMutableNotificationContent()
        inhalt.title = "📊 Euer YEM1N-Wochenbericht"
        inhalt.body = "Die Woche ist geschafft. Tippe, um zu sehen, wie sie gelaufen ist."
        inhalt.sound = .default
        var d = DateComponents()
        d.weekday = 1
        d.hour = 18
        d.minute = 0
        let ausloeser = UNCalendarNotificationTrigger(dateMatching: d, repeats: true)
        let anfrage = UNNotificationRequest(identifier: "wochenbericht", content: inhalt, trigger: ausloeser)
        try? await zentrale.add(anfrage)
    }
}

// Notizblock zum Rechnen mit Finger oder Apple Pencil
struct NotizblockView: UIViewRepresentable {
    @Binding var zeichnung: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let c = PKCanvasView()
        c.drawingPolicy = .anyInput
        c.backgroundColor = .clear
        c.isOpaque = false
        c.drawing = zeichnung
        c.tool = PKInkingTool(.pen, color: .white, width: 4)
        c.delegate = context.coordinator
        return c
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != zeichnung {
            uiView.drawing = zeichnung
        }
    }

    func makeCoordinator() -> Koordinator { Koordinator(self) }

    final class Koordinator: NSObject, PKCanvasViewDelegate {
        var eltern: NotizblockView
        init(_ eltern: NotizblockView) { self.eltern = eltern }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            eltern.zeichnung = canvasView.drawing
        }
    }
}
