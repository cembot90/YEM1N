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
// MARK: - Anleitung und Info
// ============================================================

enum Lernzeit {
    static let kennung = "yem1n.lernzeit"

    static func planen(an: Bool, minuten: Int) {
        let zentrum = UNUserNotificationCenter.current()
        zentrum.removePendingNotificationRequests(withIdentifiers: [kennung])
        guard an else { return }
        zentrum.requestAuthorization(options: [.alert, .sound]) { erlaubt, _ in
            guard erlaubt else { return }
            let inhalt = UNMutableNotificationContent()
            inhalt.title = "YEM1N"
            inhalt.body = "Zeit zum Üben. Ein paar Aufgaben, dann hast du es geschafft."
            inhalt.sound = .default
            var zeit = DateComponents()
            zeit.hour = minuten / 60
            zeit.minute = minuten % 60
            let ausloeser = UNCalendarNotificationTrigger(dateMatching: zeit, repeats: true)
            zentrum.add(UNNotificationRequest(identifier: kennung, content: inhalt, trigger: ausloeser))
        }
    }
}

enum AppInfo {
    static let anleitungURL = "https://cembot90.github.io/YEM1N/anleitung.html"

    /// Anleitung in der gewählten Farbwelt: Die Seite liest "farbwelt" aus der Adresse.
    static var anleitungAdresse: URL? {
        let rosa = UserDefaults.standard.string(forKey: "farbwelt") == "rosa"
        return URL(string: anleitungURL + (rosa ? "?farbwelt=rosa" : ""))
    }
    static let feedbackAdresse = "cembot@icloud.com"

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }
    static var geraet: String {
        UIDevice.current.model + ", iOS " + UIDevice.current.systemVersion
    }
    static func feedbackURL(modus: String) -> URL? {
        let rolle = modus == "eltern" ? "Eltern-Gerät" : (modus == "kind" ? "Kind-Gerät" : "ohne Rolle")
        let text = "\n\n\nBitte oben schreiben, hier nicht löschen:\nYEM1N \(version) (\(build))\n\(geraet)\n\(rolle)"
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = feedbackAdresse
        c.queryItems = [
            URLQueryItem(name: "subject", value: "YEM1N Feedback"),
            URLQueryItem(name: "body", value: text)
        ]
        return c.url
    }
}

struct WebAnsicht: UIViewRepresentable {
    let url: URL
    @Binding var laedt: Bool
    @Binding var fehler: Bool

    func makeCoordinator() -> Koordinator { Koordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.navigationDelegate = context.coordinator
        web.load(URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 20))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Koordinator: NSObject, WKNavigationDelegate {
        let eltern: WebAnsicht
        init(_ eltern: WebAnsicht) { self.eltern = eltern }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            eltern.laedt = false
            eltern.fehler = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            eltern.laedt = false
            eltern.fehler = true
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            eltern.laedt = false
            eltern.fehler = true
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let ziel = navigationAction.request.url,
               ziel.host != "cembot90.github.io" {
                UIApplication.shared.open(ziel)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

struct AnleitungView: View {
    @State private var laedt = true
    @State private var fehler = false

    var body: some View {
        ZStack {
            (Theme.rosa ? Color(red: 1.0, green: 0.96, blue: 0.98) : Color(red: 0.97, green: 0.98, blue: 1.0)).ignoresSafeArea()
            if let url = AppInfo.anleitungAdresse {
                WebAnsicht(url: url, laedt: $laedt, fehler: $fehler)
                    .opacity(fehler ? 0 : 1)
            }
            if laedt && !fehler {
                ProgressView("Anleitung wird geladen")
                    .tint(Theme.navy)
                    .foregroundStyle(Theme.navy)
            }
            if fehler {
                kurzAnleitung
            }
        }
        .navigationTitle("Anleitung")
        .navigationBarTitleDisplayMode(.inline)
    }

    private let kurz: [(String, String)] = [
        ("Reiter", "Unten gibt es höchstens fünf Reiter. Kind: Schule, Sprachen, Vorschule, Haustier und Ich. Sprachen und Vorschule lassen sich unter Einstellungen > Bereiche ausblenden. Unter Ich stehen Joker-Tipps, Erfolge, Spiele, Duell und Einstellungen. Eltern: Übersicht, Joker, Lernen, Haustier und Einstellungen. Unter Lernen liegen Schule, Sprachen, Vorschule, Duell, der Aufgaben-Editor und das Verteilen von Aufgaben."),
        ("Einrichten", "Beim ersten Start Kind oder Eltern wählen. Die Eltern erzeugen den Familiencode und tragen ihn auf dem Kind-Gerät ein. Ein Klassencode ist zusätzlich möglich."),
        ("QR-Code", "Statt abzutippen: Das Eltern-Gerät zeigt den Code unter Einstellungen > Familiencode als QR-Code, das Kind-Gerät scannt ihn. Den Familiencode nur dem Kind oder dem anderen Elternteil zeigen."),
        ("Üben", "Im Tab Schule eine Arbeit wählen, dann eine Übung. Antwort eintippen und bestätigen. Mit In Schritten rechnet das Kind die Aufgabe in kleinen Schritten wie im Heft, am Ende kommt das Ergebnis in die Aufgabe. Nach jeder Übung gibt es bis zu drei Sterne."),
        ("Vorschule", "Im Tab Vorschule gibt es große Bilder zum Antippen mit Vorlesen auf Deutsch: Zahlen und Rechnen, Sprache und Laute (Buchstaben, Reime, Silben) und Spielen und Entdecken (links und rechts, Gefühle, Tiere, Verkehr, Muster, Memory). Für jedes geschaffte Spiel gibt es einen Stempel im Schulstart-Pass. Unter Einstellungen > Bereiche gibt es Englisch für Kleine (Wörter hören und Bilder antippen) und die übrigen Spiele auf Englisch oder Türkisch (Versuch)."),
        ("Lernwelt", "Ganz oben im Tab Schule: 130 Themen mit fertigen Aufgaben für Klasse 1 bis 4 in Mathe, Deutsch, Englisch, Musik und Kunst, nach dem Lehrplan von Hessen, Bayern oder NRW. Jedes Mal neue Aufgaben, dazu Lesetexte mit Fragen, Zahlenmauern, eine Uhr zum Ablesen und Töne zum Anhören. Die eigene Klasse steht oben, andere Klassen lassen sich aufklappen. Mathe und Deutsch stehen in der Reihenfolge des Schuljahres, was gerade dran ist, ist markiert. Bundesland und Klasse stehen unter Einstellungen, Profil."),
        ("Weiter", "Am Ende einer Übung führt der Knopf Nächste Übung direkt zur nächsten."),
        ("Hilfen", "Der Lautsprecher liest die Aufgabe vor. Hinweis, Lösung zeigen, Notizblock und Joker helfen bei schweren Aufgaben."),
        ("Stimmen", "Unter Einstellungen, Vorlese-Stimmen lädst du einmal die Gerätestimme Thorsten (Deutsch), Fahrettin (Türkisch) oder Cori (Englisch). Sie liest dann natürlich vor, auch ohne Internet."),
        ("Mit dem Stift", "Über der Eingabe auf Mit dem Stift schreiben tippen. Dann die Zahl mit dem Apple Pencil oder dem Finger aufs Karoblatt schreiben. Das Gerät liest sie, die Zahl steht im Antwortfeld, dann auf den Haken tippen. Lieber Tasten schaltet zurück. Auf dem iPad ist der Stift von Anfang an an."),
        ("Zeig es mir als Bild", "Nach einem Fehler oder bei Lösung zeigen malt Olli die Rechnung: Punktefeld beim Mal, eine Reihe mehr oder weniger bei Nachbaraufgaben, Kekse auf Tellern beim Teilen, Sprünge auf dem Zahlenstrahl bei Plus und Minus, den Rechenweg bei Punkt vor Strich."),
        ("Erklär-Freund", "Nach einer falschen Antwort erklärt die Eule mit Warum war das falsch?, wo der Denkfehler lag. Den Fehler erkennt YEM1N selbst. Auf iPhones mit Apple Intelligence formuliert die KI auf dem Gerät die Erklärung kindgerecht, ohne Internet."),
        ("Joker", "Der Joker schickt eine Aufgabe an die Eltern. Ein Tipp auf die Mitteilung öffnet bei den Eltern direkt den Reiter Joker. Die Antworten sieht das Kind unter Ich."),
        ("Einwilligung", "Beim ersten Start bestätigt ein Elternteil die Datenschutzerklärung. Unter Einstellungen > Datenschutz lässt sich die Einwilligung widerrufen und die Cloud-Daten löschen. Cloud-Einträge löscht die App nach 12 Monaten selbst. Impressum und Beta und Haftung stehen unter Info."),
        ("Fehlerheft", "Falsche Aufgaben kommen ins Fehlerheft. Ein Fehler ist erst gemeistert, wenn er zweimal richtig war: Nach der ersten richtigen Antwort kommt er nach 3 Tagen noch einmal, bei einer falschen schon morgen. Auf dem Knopf steht, wie viele Fehler fällig sind."),
        ("Haustier", "Im Tab Haustier sucht sich das Kind ein Tier aus. Es steht in 3D auf der Bühne: Antippen lässt es hüpfen und dorthin schauen, waagrecht ziehen dreht es. Nach einer geschafften Runde tanzt es, von 20 bis 7 Uhr schläft es. Beim Antippen sagt es etwas zu seiner Laune. Die Eule Olli kreist über dem Ei, erklärt beim ersten Besuch alles Schritt für Schritt und gibt danach Tipps: auf Olli oder Frag Olli tippen. Ob beide laut sprechen, stellt ein Schalter unten im Tab ein. Es schlüpft mit der ersten Runde und wird satt und größer, wenn das Kind übt. Mit Münzen gibt es Leckerlis, Spielzeug und Hüte, einmal am Tag ein Geschenk. Das Tier läuft nie weg. Mit Familiencode sehen die Eltern das Tier in ihrem Tab Haustier und können es täglich gratis füttern und mit ihm spielen. Eine Mitteilung um 17 Uhr erinnert, wenn es bald Hunger hat, und lässt sich im Tab ausschalten. Als Widget zeigt das Tier mit der Serie auch den Sperrbildschirm: lange antippen, Anpassen, YEM1N wählen."),
        ("Probearbeit", "Zwanzig gemischte Aufgaben mit Uhr, am Ende gibt es eine Note. Jede Probearbeit sieht anders aus. Eine angefangene Probearbeit geht am selben Tag weiter, danach gibt es neue Aufgaben."),
        ("Sprachen", "Im Tab Sprachen lernt das Kind Englisch, Türkisch und Italienisch. Der Bereich ist noch ein Versuch und zuerst aus. Einschalten und Sprachen wählen geht unter Einstellungen > Bereiche."),
        ("Abzeichen", "Für Serien, Sterne und fehlerfreie Runden gibt es Abzeichen. Das Pokal-Symbol im Tab Schule zeigt alle. Ein neues Abzeichen erscheint gleich nach der Übung."),
        ("Serie und Wochenziel", "Ein freier Tag pro Woche ist erlaubt, ohne dass die Serie endet. Das Wochenziel sind fünf Tage mal Tagesziel an Runden. Wer es schafft, holt sich im Pokal-Bereich 10 Münzen ab."),
        ("Münzen und Spiele", "Für jede gleich richtig gelöste Aufgabe gibt es eine Münze, für drei Sterne fünf extra. Angeschaute Lösungen bringen nichts. Mit den Münzen schaltet das Kind ein Spiel frei, das Symbol steht oben im Tab Schule und unter Ich. Es gibt fünf Spiele: Elfmeterschießen, Einhorn-Flug, Zahlenlauf, Münzjagd und Münz-Hockey. Gespielt wird erst nach einer geschafften Übung."),
        ("Elfmeterschießen", "Vom Ball nach oben zum Tor wischen. Die gestrichelte Linie zeigt, wohin der Ball fliegt. Ein Tor bringt einen Punkt, in den Winkel drei. Der Torwart wird mit jedem Level schneller. Nach drei Fehlschüssen ist Schluss."),
        ("Einhorn-Flug", "Tippen lässt das Einhorn steigen. Sterne bringen einen Punkt, Regenbögen drei, Herzen geben ein Leben zurück. Gewitterwolken kosten ein Herz. Das Einhorn kann nicht abstürzen, es prallt oben und unten weich ab."),
        ("Zahlenlauf", "Antippen springt, ein zweites Antippen in der Luft ist der Doppelsprung. Gedrückt halten springt höher. Drei Leben, danach ist die Runde vorbei. Flieger unterläuft man am besten, Trampoline schleudern hoch, Flügel geben kurz einen dritten Sprung."),
        ("Münzjagd", "Auf den Plattformen alle Münzen einsammeln. Daumen links auflegen, dann erscheint der Analogstick: zur Seite ziehen läuft, nach oben springt. Rechts geht Springen auch mit dem großen Pfeil. Beim Fallen gedrückt halten lässt dich schweben. Die leuchtende Münze bringt drei Punkte. Gegner kosten ein Leben."),
        ("Münz-Hockey", "Mit dem Finger den Schläger in der linken Hälfte bewegen. Wer zuerst fünf Tore hat, gewinnt. Danach wird der Computer besser."),
        ("Duell", "Kind: Reiter Ich, Duell. Eltern: Reiter Lernen, Duell. Zwei rechnen je zehn Aufgaben auf ihrer eigenen Stufe, von Klasse 1 bis Profi. Mehr richtig gewinnt, bei Gleichstand die schnellere Zeit, falsch kostet 3 Sekunden. Zu zweit an einem Gerät oder mit Familiencode als Herausforderung an die Familie. Kostet keine Münzen."),
        ("Einstellungen", "Die Einstellungen sind nach Themen sortiert: Ich, Familie und Klasse, Lernen und Spielen, Aussehen, Hilfe und Rechtliches. Technik wie Cloud-Diagnose, Einrichtung und Gerätemodus steht unter Für Fortgeschrittene."),
        ("Lernzeit", "In den Einstellungen unter Spiele und Lernzeit lässt sich eine tägliche Erinnerung ans Üben einschalten, mit fester Uhrzeit."),
        ("Wochenbericht", "Sonntags um 18 Uhr gibt es einen Bericht in Worten: was gut lief, wo es hakt, welcher Denkfehler öfter vorkam und ein Tipp für zu Hause. Ein Tipp auf die Mitteilung oder auf den gelben Hinweis in der Übersicht öffnet ihn. Teilen geht als Text oder PDF."),
        ("Für Eltern", "Die Übersicht zeigt den Wochenbericht, die Abzeichen und den Schwächen-Radar mit den Übungen, die am schwersten fallen. Darunter stehen die Aufgaben, die haken, mit dem, was dein Kind geschrieben hat. Tippe auf eine Übung oder eine Runde, um jede einzelne Antwort zu sehen. Unter Kinder in der Familie steht, wann jedes Kind zuletzt geübt hat. Alte Konten lassen sich mit dem Papierkorb entfernen."),
        ("Eigene Aufgaben", "Fotos von Buchseiten kannst du selbst in Aufgaben verwandeln: Die Vorlage in der ausführlichen Anleitung (Abschnitt 11.4, Eigene Aufgaben aus Fotos) als erste Nachricht an eine KI wie Claude oder ChatGPT schicken, dann Fotos und einen Namen. Das JSON, das zurückkommt, fügst du im Tab Schule über Plus und Text einfügen ein (Eltern: Reiter Lernen, Schule). Prüfe ein paar Antworten, bevor dein Kind übt."),
        ("Neue Aufgaben", "Im Tab Schule nach unten ziehen oder Neue Aufgaben holen wählen. Dafür braucht das Gerät Internet."),
        ("Sparmodus", "Ruckelt die App auf einem älteren Gerät, unter Einstellungen, Farben und Darstellung den Sparmodus einschalten. Er lässt Bewegungen, Konfetti und Glas-Effekte weg, Üben und Spiele bleiben gleich. Im Stromsparmodus von iOS ist er von selbst an."),
        ("Hilfe", "Die ausführliche Anleitung öffnet sich, sobald das Gerät online ist. Unter Info kannst du Feedback an den Admin schicken.")
    ]

    private var kurzAnleitung: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Kein Internet. Das ist die Kurzfassung.", systemImage: "wifi.slash")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.navy)
                ForEach(kurz, id: \.0) { eintrag in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(eintrag.0)
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.navy)
                        Text(eintrag.1)
                            .font(.subheadline)
                            .foregroundStyle(Theme.navy.opacity(0.85))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(20)
        }
    }
}

struct InfoView: View {
    @AppStorage("modus") private var modus = ""
    @State private var kopiert = false

    private var infoText: String {
        "YEM1N \(AppInfo.version) (\(AppInfo.build)), \(AppInfo.geraet)"
    }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text("YEM1N")
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.gelb)
                        Text("Version \(AppInfo.version), Build \(AppInfo.build)")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textSanft)
                        Text(AppInfo.geraet)
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 10) {
                        NavigationLink { AnleitungView() } label: {
                            zeile("Anleitung", "book.fill")
                        }
                        NavigationLink { DatenschutzView() } label: {
                            zeile("Datenschutzhinweise", "hand.raised.fill")
                        }
                        NavigationLink { ImpressumView() } label: {
                            zeile("Impressum", "person.text.rectangle")
                        }
                        NavigationLink { BetaHinweisView() } label: {
                            zeile("Beta und Haftung", "exclamationmark.shield")
                        }
                        if let url = AppInfo.feedbackURL(modus: modus) {
                            Link(destination: url) {
                                zeile("Feedback an den Admin", "envelope.fill")
                            }
                        }
                        Button {
                            UIPasteboard.general.string = infoText
                            kopiert = true
                        } label: {
                            zeile(kopiert ? "Kopiert" : "Versionsinfo kopieren", kopiert ? "checkmark" : "doc.on.doc")
                        }
                    }

                    Text("Fehler gefunden oder eine Idee? Schreibe kurz, was passiert ist. Version und Gerät hängen automatisch an der Nachricht.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSanft)
                        .padding(.horizontal, 10)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func zeile(_ titel: String, _ symbol: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.navy)
                .frame(width: 40, height: 40)
                .background(Theme.gelb, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(titel)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Theme.gelb)
        }
        .padding(14)
        .glasKarte(radius: 20)
    }
}
