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
// MARK: - Datenschutz
// ============================================================

struct DatenschutzView: View {
    private let abschnitte: [(String, String)] = [
        ("Verantwortlicher",
         "Cem Aras, Schulweg 20, 65618 Selters (Taunus). Telefon: +49 172 7579888, E-Mail: cembot@icloud.com."),
        ("Auf deinem Gerät",
         "YEM1N speichert Klassenarbeiten, Aufgaben, Ergebnisse und Einstellungen (zum Beispiel Name des Kindes, Klasse, Bundesland, Farbwelt, Tagesziel, gewählte Sprachen, Name und Zustand des Haustiers) sowie Datum und Fassung der Einwilligung auf diesem Gerät. Das bleibt dort, bis du die App löschst. Nur wenn dieses Gerät zu einer Familie gehört, geht der Stand des Haustiers zusätzlich an die Familie (siehe unten)."),
        ("Familie (freiwillig, mit Einwilligung)",
         "Solange dieses Gerät zu keiner Familie gehört, schickt die App keine Daten an mich oder andere. Gehört es mit Einwilligung der Eltern zu einer Familie, nutzt die App ein eigenes, abgetrenntes Fach für diese Familie. Dann werden gesendet: der Name und der öffentliche Schlüssel jedes Geräts, die Kennung für Mitteilungen, Fragen und Antworten der Joker (Freitext), Daumen, Rundenergebnisse (Fach, Übung, Anzahl richtig, Sterne, Zeitpunkt und der Name des Kindes, falls eingetragen, bei Mathe und Deutsch außerdem die einzelnen Aufgaben einer Runde mit der Eingabe des Kindes und der richtigen Lösung), Aufgabenpakete der Eltern, Duelle (Name, Stufe, Rechenaufgaben, Zahl der richtigen Antworten, Zeit und eine zufällige Gerätekennung) und das Haustier (Name, Art, Wachstum, Hunger, Laune und Hüte, dazu kleine Einträge der Eltern mit Tag und Leckerli oder Spielen). Zugriff haben nur Geräte der Familie. Jede Anfrage wird mit einem Schlüssel unterschrieben, der in der Secure Enclave dieses Geräts bleibt und nie verschickt wird. Ein neues Gerät kommt nur mit einem QR-Code dazu und muss von den Eltern erlaubt werden. Den Bereich für Eltern schützt eine PIN, die nur auf dem Gerät gespeichert wird. Für den Namen des Kindes reicht ein Vorname oder Spitzname. Tipps im Joker sind Freitext. Schreibe dort bitte keine Nachnamen, Adressen oder Telefonnummern."),
        ("Klassencode",
         "Über den Klassencode kommen nur Aufgabenpakete an. Sie sind vom Admin digital unterschrieben, sonst nimmt die App sie nicht an. Ergebnisse und Joker laufen nie über den Klassencode."),
        ("KI auf dem Gerät",
         "Der Erklär-Freund und der Wochenbericht in Worten werden auf iPhones mit Apple Intelligence von Apples Sprachmodell formuliert. Das läuft vollständig auf diesem Gerät. Aufgaben, Antworten und Ergebnisse werden dafür nicht ins Internet geschickt, weder an Apple noch an mich oder andere Anbieter."),
        ("Kein Tracking",
         "Die App enthält keine Werbung und keine Analysedienste. Es gibt kein Benutzerkonto bei mir. Die Sprachausgabe läuft auf dem Gerät, die Gerätestimmen rechnet die freie Software sherpa-onnx auf dem Gerät. Es werden keine Fotos, Kontakte, Standortdaten oder Mikrofonaufnahmen erhoben."),
        ("Mitteilungen",
         "Die App sendet Mitteilungen zwischen Eltern- und Kindgeräten. Sie laufen über den Familien-Dienst und Apple. Dafür gibt Apple ein technisches Gerätekennzeichen aus, das der Familien-Dienst speichert. Die Mitteilung selbst hat einen festen Text ohne Namen und ohne Inhalte. Die Erlaubnis kannst du jederzeit in den iOS-Einstellungen widerrufen."),
        ("Zwecke und Rechtsgrundlagen",
         "Die Daten werden nur verarbeitet, damit die App funktioniert: Üben, Ergebnisübersicht für Eltern, Joker, Aufgabenverteilung, Duelle in der Familie und das gemeinsame Haustier. Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO und, soweit Eltern die App für ihr Kind einrichten, deren Einwilligung nach Art. 6 Abs. 1 lit. a in Verbindung mit Art. 8 DSGVO. Für Mitteilungen gilt deine Einwilligung. Die digitale Unterschrift der Klassenpakete dient der Sicherheit (Art. 6 Abs. 1 lit. f DSGVO)."),
        ("Einwilligung und Widerruf",
         "Beim ersten Start und immer dann, wenn sich diese Erklärung inhaltlich ändert, bestätigt ein Elternteil oder eine erziehungsberechtigte Person die Einwilligung. Das Gerät speichert nur Datum und Fassung. Du kannst die Einwilligung jederzeit unter Einstellungen > Datenschutz > Einwilligung widerrufen. Dieses Gerät verlässt dann die Familie (seine Einträge werden gelöscht, wenn es ein Kinder-Gerät ist) und die App fragt neu. Ohne Einwilligung kann die App nicht genutzt werden. Der Widerruf berührt nicht die Rechtmäßigkeit der bisherigen Verarbeitung."),
        ("Empfänger",
         "Das Fach der Familie liegt bei Cloudflare (Cloudflare, Inc., USA) und wird in der EU gespeichert. Mitteilungen laufen über den Apple Push Notification Service (Apple, USA), bei Android-Geräten der Familie über Google Firebase Cloud Messaging (Google, USA). Pakete der Klasse lädt die App aus der öffentlichen CloudKit-Datenbank von Apple, nur mit Klassencode und ohne Daten des Kindes. Eine Übermittlung in Drittländer, insbesondere die USA, kann dabei nicht ausgeschlossen werden. Die Anbieter stützen sich dafür auf Standardvertragsklauseln und das EU-US Data Privacy Framework. Wenn du unter Vorlese-Stimmen eine Gerätestimme lädst, kommt die Datei von GitHub (GitHub, Inc., USA). GitHub sieht dabei wie bei jeder Webseite die IP-Adresse und technische Angaben zur Verbindung, aber keine Daten aus der App. Weitere Empfänger gibt es nicht."),
        ("Speicherdauer und Löschen",
         "Daten auf dem Gerät bleiben, bis du die App löschst. Die Eltern können die ganze Familie mit allen Einträgen jederzeit unter Einstellungen > Familie löschen. Ein Kinder-Gerät kann beim Verlassen der Familie seine Einträge mitnehmen (löschen lassen). Von selbst löscht der Familien-Dienst Einträge nach spätestens 12 Monaten (Duelle nach 14 Tagen) und eine unbenutzte Familie nach 12 Monaten ohne Nutzung. Eine Familie, die nie benutzt wurde, verschwindet nach 30 Tagen. Du kannst mich auch per E-Mail um Löschung bitten. Auf dem Eltern-Gerät blendet „Entfernen“ in der Kinderliste ein Kind nur auf diesem Gerät aus und löscht die dort gespeicherten Kopien seiner Ergebnisse."),
        ("Deine Rechte",
         "Du hast das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung der Verarbeitung, Datenübertragbarkeit und Widerspruch sowie das Recht, eine Einwilligung jederzeit zu widerrufen. Schreibe dazu an die oben genannte E-Mail-Adresse. Du kannst dich außerdem bei einer Datenschutzaufsichtsbehörde beschweren, zum Beispiel beim Hessischen Beauftragten für Datenschutz und Informationsfreiheit in Wiesbaden."),
        ("Kinder",
         "Die App richtet sich an Eltern, die sie gemeinsam mit ihren Kindern nutzen. Name, Familie und Klassencode richten Eltern ein und bestätigen dabei die Einwilligung. Ein Gerät sieht immer nur Einträge der eigenen Familie, nie die einer fremden. In Deutschland liegt die Altersgrenze für die eigene Einwilligung nach Art. 8 DSGVO bei 16 Jahren.")
    ]

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(abschnitte, id: \.0) { a in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(a.0)
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.gelb)
                            Text(a.1)
                                .font(.subheadline)
                                .foregroundStyle(Color.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glasKarte(radius: 22)
                    }
                    if let url = URL(string: "https://cembot90.github.io/YEM1N/") {
                        Link(destination: url) {
                            Label("Im Browser öffnen", systemImage: "safari")
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.navy)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Theme.gelb, in: Capsule())
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Datenschutz")
        .navigationBarTitleDisplayMode(.inline)
    }
}
