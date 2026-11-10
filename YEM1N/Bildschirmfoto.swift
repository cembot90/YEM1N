import SwiftUI
import SwiftData

// Nur für Bildschirmfotos beim Prüfen auf GitHub. In der echten App (Release) gibt es das alles nicht.
// Aufruf im Simulator: xcrun simctl launch <gerät> de.cemaras.yem1n -bildschirmfoto ueben
// Die Daten liegen dabei nur im Arbeitsspeicher, auf dem Gerät wird nichts gespeichert oder verändert.
#if DEBUG
enum Bildschirmfoto {
    /// Der gewünschte Bildschirm, sonst nil (dann startet die App ganz normal)
    static var ziel: String? {
        let wert = UserDefaults.standard.string(forKey: "bildschirmfoto") ?? ""
        return wert.isEmpty ? nil : wert
    }
}

struct BildschirmfotoView: View {
    let ziel: String
    @Environment(\.modelContext) private var context
    @State private var uebung: Uebung?

    var body: some View {
        Group {
            switch ziel {
            case "start":
                WurzelView()
            case "vorschule":
                VorschuleView()
            case "vorschulrunde":
                NavigationStack { VorschulRunde(art: .zaehlen) }
            case "lernwelt":
                NavigationStack { LernweltView() }
            case "haustier":
                HaustierView()
            case "einstellungen":
                EinstellungenView(eingebettet: true)
            default:
                if let uebung {
                    NavigationStack { UebungView(uebung: uebung) }
                } else {
                    HintergrundView()
                }
            }
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .background(HintergrundView())
        .tint(Theme.gelb)
        .preferredColorScheme(.dark)
        .onAppear { if uebung == nil { uebung = beispiel() } }
    }

    /// Eine kleine Übung mit Beispielaufgaben, passend zum gewünschten Bildschirm
    private func beispiel() -> Uebung {
        let arbeit = Klassenarbeit(klasse: "3", fach: "Mathe", titel: "Beispiel")
        let u = Uebung(titel: "Halbieren und Zehner", gruppe: "", symbol: "divide", tipp: "Zerlege die Zahl in Zehner und Einer.", reihenfolge: 0)
        context.insert(arbeit)
        context.insert(u)
        u.arbeit = arbeit
        var liste: [Aufgabe] = []
        func neu(_ art: String, _ frage: String, _ rechnung: String, _ antwort: String,
                 hinweis: String = "", optionen: String = "") {
            let a = Aufgabe(art: art, frage: frage, rechnung: rechnung, hinweis: hinweis,
                            erklaerung: "", antwort: antwort, antwort2: "", reihenJSON: "", reihenfolge: liste.count)
            a.optionen = optionen
            context.insert(a)
            a.uebung = u
            liste.append(a)
        }
        switch ziel {
        case "ueben-lang":
            neu("wahl", "Lies genau: Tim hat 24 Murmeln und schenkt seiner Schwester die Hälfte. Wie viele Murmeln hat Tim danach noch?",
                "", "12", optionen: "12\n14\n48")
        case "ueben-text":
            neu("text", "Schreibe das Wort richtig.", "der hunt", "Hund")
        case "ueben-vergleich":
            neu("vergleich", "Welches Zeichen passt?", "48 ? 84", "<", hinweis: "Schau zuerst auf die Zehner.")
        default:
            neu("zahl", "Halbiere die Zahl.", "48", "24")
        }
        neu("zahl", "Welcher Zehner kommt davor?", "67", "60")
        neu("zahl", "Rechne aus.", "7 · 8", "56")
        if ziel == "ergebnis" {
            for a in liste { a.richtig = true }
        }
        return u
    }
}
#endif
