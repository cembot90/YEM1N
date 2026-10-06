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
         "Cem Aras, Schulweg 20, 65618 Selters (Taunus). Telefon: 0172-7579888, E-Mail: cembot@icloud.com."),
        ("Auf deinem Gerät",
         "YEM1N speichert Klassenarbeiten, Aufgaben, Ergebnisse und Einstellungen (zum Beispiel Name des Kindes, Klasse, Farbwelt, Tagesziel) auf diesem Gerät. Das bleibt dort, bis du die App löschst."),
        ("In der Cloud",
         "Nur wenn ein Familiencode eingetragen ist, nutzt die App die iCloud (CloudKit) von Apple. Dort liegen Rundenergebnisse (Fach, Übung, Anzahl richtig, Sterne, Zeitpunkt und der Name des Kindes, falls eingetragen), Joker-Nachrichten und Aufgabenpakete. Wer den Familiencode kennt, kann diese Einträge lesen. Gib ihn deshalb nur an Eltern weiter, denen du vertraust. Für den Namen des Kindes reicht ein Vorname oder Spitzname. Apple speichert technisch, welche pseudonyme iCloud-Kennung einen Eintrag angelegt hat, einen Klarnamen sehe ich dadurch nicht."),
        ("Klassencode",
         "Über den Klassencode kommen nur Aufgabenpakete an. Sie sind vom Admin digital unterschrieben, sonst nimmt die App sie nicht an. Ergebnisse und Joker laufen nie über den Klassencode."),
        ("Kein Tracking",
         "Die App enthält keine Werbung, keine Analysedienste und keine Software von Drittanbietern. Es gibt kein Benutzerkonto bei mir. Die Sprachausgabe läuft auf dem Gerät. Es werden keine Fotos, Kontakte, Standortdaten oder Mikrofonaufnahmen erhoben."),
        ("Mitteilungen",
         "Die App sendet Mitteilungen zwischen Eltern- und Kindgeräten über Apple. Dafür gibt Apple ein technisches Gerätekennzeichen aus. Die Erlaubnis kannst du jederzeit in den iOS-Einstellungen widerrufen."),
        ("Zwecke und Rechtsgrundlagen",
         "Die Daten werden nur verarbeitet, damit die App funktioniert: Üben, Ergebnisübersicht für Eltern, Joker und Aufgabenverteilung. Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO und, soweit Eltern die App für ihr Kind einrichten, deren Einwilligung nach Art. 6 Abs. 1 lit. a in Verbindung mit Art. 8 DSGVO. Für Mitteilungen gilt deine Einwilligung. Die digitale Unterschrift der Klassenpakete dient der Sicherheit (Art. 6 Abs. 1 lit. f DSGVO)."),
        ("Empfänger",
         "Die Cloud-Daten und Mitteilungen laufen über Apple (iCloud/CloudKit und Apple Push Notification Service). Eine Übermittlung in Drittländer, insbesondere die USA, kann dabei nicht ausgeschlossen werden. Apple stützt sich dafür auf Standardvertragsklauseln und das EU-US Data Privacy Framework. Weitere Empfänger gibt es nicht."),
        ("Speicherdauer und Löschen",
         "Daten auf dem Gerät bleiben, bis du die App löschst. Cloud-Einträge bleiben, bis sie gelöscht werden. Mit dem Knopf unten löschst du die Cloud-Einträge dieses Familiencodes, die dieses Gerät angelegt hat. Nutze ihn auf jedem Gerät der Familie. Du kannst mich auch per E-Mail um Löschung bitten."),
        ("Deine Rechte",
         "Du hast das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung der Verarbeitung, Datenübertragbarkeit und Widerspruch sowie das Recht, eine Einwilligung jederzeit zu widerrufen. Schreibe dazu an die oben genannte E-Mail-Adresse. Du kannst dich außerdem bei einer Datenschutzaufsichtsbehörde beschweren, zum Beispiel beim Hessischen Beauftragten für Datenschutz und Informationsfreiheit in Wiesbaden."),
        ("Kinder",
         "Die App richtet sich an Eltern, die sie gemeinsam mit ihren Kindern nutzen. Familiencode, Klassencode und Name sollten Eltern einrichten.")
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
