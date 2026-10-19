import Foundation

// ============================================================
// MARK: - Lob und Mutmacher
// ============================================================
//
// Viele verschiedene Rückmeldungen, damit es nicht langweilig wird:
// allgemeines Lob, Lob mit Namen, Lob nach einem Fehler, Serien und
// ein Satz zum Schluss, der zur Runde passt. Derselbe Satz kommt nie
// zweimal kurz hintereinander.
// Diese Datei braucht nur Foundation, damit pruefen/linux-tests.sh sie prüfen kann.

/// Ein Satz auf Deutsch, Türkisch und Englisch. {name} wird durch den Namen ersetzt.
/// Türkisch und Englisch gibt es nur für die Vorschule, wenn die Eltern das einschalten.
struct LobText: Equatable, Sendable {
    let de: String
    let tr: String
    let en: String

    /// Der Satz in der Sprache "de", "tr" oder "en", sonst Deutsch
    func text(_ sprache: String) -> String {
        switch sprache {
        case "tr": return tr
        case "en": return en
        default: return de
        }
    }
}

enum Lob {

    // MARK: Satzlisten

    static let richtig: [LobText] = [
        LobText(de: "Super!", tr: "Süper!", en: "Super!"),
        LobText(de: "Toll gemacht!", tr: "Aferin!", en: "Well done!"),
        LobText(de: "Richtig!", tr: "Doğru!", en: "Right!"),
        LobText(de: "Prima!", tr: "Harika!", en: "Great!"),
        LobText(de: "Klasse!", tr: "Bravo!", en: "Brilliant!"),
        LobText(de: "Spitze!", tr: "Çok iyi!", en: "Excellent!"),
        LobText(de: "Genau!", tr: "Tam olarak!", en: "Exactly!"),
        LobText(de: "Stark!", tr: "Süpersin!", en: "Awesome!"),
        LobText(de: "Wunderbar!", tr: "Muhteşem!", en: "Wonderful!"),
        LobText(de: "Sehr gut!", tr: "Çok güzel!", en: "Very good!"),
        LobText(de: "Bravo!", tr: "Tebrikler!", en: "Bravo!"),
        LobText(de: "Das stimmt!", tr: "Evet, doğru!", en: "That's right!"),
        LobText(de: "Perfekt!", tr: "Mükemmel!", en: "Perfect!"),
        LobText(de: "Ganz genau!", tr: "Kesinlikle doğru!", en: "Spot on!"),
        LobText(de: "Volltreffer!", tr: "Tam isabet!", en: "Bullseye!"),
        LobText(de: "Du bist ein Profi!", tr: "Sen bir ustasın!", en: "You're a pro!"),
        LobText(de: "Wow, richtig!", tr: "Vay, doğru!", en: "Wow, correct!"),
        LobText(de: "Das hast du super gemacht!", tr: "Çok güzel yaptın!", en: "You did that really well!"),
        LobText(de: "Treffer!", tr: "İşte bu!", en: "Got it!"),
        LobText(de: "Du hast es!", tr: "Bildin!", en: "You've got it!"),
        LobText(de: "Klasse gemacht!", tr: "Harikasın!", en: "Nicely done!"),
        LobText(de: "Richtig gut!", tr: "Çok başarılı!", en: "Really good!"),
        LobText(de: "Juhu, richtig!", tr: "Yaşasın, doğru!", en: "Hooray, correct!"),
        LobText(de: "Gut aufgepasst!", tr: "İyi dikkat ettin!", en: "Well spotted!")
    ]

    static let mitName: [LobText] = [
        LobText(de: "Super, {name}!", tr: "Süper, {name}!", en: "Super, {name}!"),
        LobText(de: "Toll, {name}!", tr: "Aferin {name}!", en: "Well done, {name}!"),
        LobText(de: "Genau so, {name}!", tr: "Tam böyle, {name}!", en: "That's it, {name}!"),
        LobText(de: "{name}, du bist spitze!", tr: "{name}, harikasın!", en: "{name}, you're a star!"),
        LobText(de: "Richtig, {name}!", tr: "Doğru, {name}!", en: "Correct, {name}!"),
        LobText(de: "Klasse gemacht, {name}!", tr: "Bravo {name}!", en: "Nicely done, {name}!"),
        LobText(de: "Das kannst du, {name}!", tr: "Bunu biliyorsun, {name}!", en: "You know this, {name}!"),
        LobText(de: "Wow, {name}!", tr: "Vay be, {name}!", en: "Wow, {name}!")
    ]

    static let nachFehler: [LobText] = [
        LobText(de: "Jetzt hat es geklappt!", tr: "İşte şimdi oldu!", en: "Now you've got it!"),
        LobText(de: "Siehst du, du schaffst das!", tr: "Gördün mü, yapabiliyorsun!", en: "See, you can do it!"),
        LobText(de: "Nicht aufgegeben. Stark!", tr: "Pes etmedin. Aferin!", en: "You didn't give up. Great!"),
        LobText(de: "Genau, jetzt stimmt es!", tr: "Evet, şimdi doğru!", en: "Yes, now it's right!"),
        LobText(de: "Gut nachgedacht!", tr: "İyi düşündün!", en: "Good thinking!"),
        LobText(de: "Dranbleiben lohnt sich!", tr: "Devam etmek işe yarıyor!", en: "Keeping at it pays off!"),
        LobText(de: "Beim zweiten Mal richtig. Prima!", tr: "İkinci denemede doğru. Harika!", en: "Right on the second try. Great!")
    ]

    /// Wenn es in der Vorschule noch nicht stimmt. Danach darf das Kind nochmal tippen.
    static let nochmal: [LobText] = [
        LobText(de: "Fast! Probier es noch einmal.", tr: "Neredeyse! Bir daha dene.", en: "Almost! Try again."),
        LobText(de: "Knapp daneben. Du schaffst das!", tr: "Az kaldı. Yapabilirsin!", en: "So close. You can do it!"),
        LobText(de: "Hmm, schau noch mal genau hin.", tr: "Hmm, bir daha dikkatlice bak.", en: "Hmm, take another good look."),
        LobText(de: "Noch nicht ganz. Versuch es noch mal!", tr: "Tam değil. Tekrar dene!", en: "Not quite. Try again!"),
        LobText(de: "Oh, nicht ganz. Gleich hast du es!", tr: "Ah, tam değil. Neredeyse buldun!", en: "Oh, not quite. You will get it soon!"),
        LobText(de: "Kein Problem, noch ein Versuch!", tr: "Sorun değil, bir deneme daha!", en: "No problem, one more try!"),
        LobText(de: "Hoppla! Noch einmal?", tr: "Hoppala! Bir daha?", en: "Oops! Once more?"),
        LobText(de: "Das war es nicht. Probier ein anderes!", tr: "Bu değil. Başka birini dene!", en: "That's not it. Try a different one!"),
        LobText(de: "Fehler sind nicht schlimm. Noch mal!", tr: "Hata yapmak sorun değil. Bir daha!", en: "Mistakes are okay. Once more!"),
        LobText(de: "Überleg noch mal in Ruhe.", tr: "Bir daha sakince düşün.", en: "Take your time and think again.")
    ]

    /// Kurzer Titel, wenn in Mathe oder Deutsch eine Antwort falsch war
    static let daneben: [String] = [
        "Noch nicht richtig.", "Knapp daneben.", "Leider nicht.", "Fast.",
        "Das war es nicht.", "Hoppla, nicht ganz.", "Noch nicht ganz.", "Nicht schlimm, weiter geht es."
    ]

    static let endePerfekt: [LobText] = [
        LobText(de: "Alles richtig! Du bist ein Star!", tr: "Hepsi doğru! Sen bir yıldızsın!", en: "All correct! You're a star!"),
        LobText(de: "Keinen einzigen Fehler. Wahnsinn!", tr: "Hiç hata yok. İnanılmaz!", en: "Not a single mistake. Amazing!"),
        LobText(de: "Perfekte Runde, {name}!", tr: "Mükemmel bir tur, {name}!", en: "Perfect round, {name}!"),
        LobText(de: "Alles geschafft und alles richtig. Super!", tr: "Hepsini bitirdin, hepsi doğru. Süper!", en: "All done and all correct. Super!"),
        LobText(de: "Volle Punktzahl! Darauf kannst du stolz sein.", tr: "Tam puan! Kendinle gurur duyabilirsin.", en: "Full marks! You can be proud of yourself.")
    ]

    static let endeGut: [LobText] = [
        LobText(de: "Das hast du toll gemacht!", tr: "Çok güzel yaptın!", en: "You did that really well!"),
        LobText(de: "Starke Runde, {name}!", tr: "Harika bir tur, {name}!", en: "Great round, {name}!"),
        LobText(de: "Fast alles richtig. Klasse!", tr: "Neredeyse hepsi doğru. Bravo!", en: "Almost all correct. Brilliant!"),
        LobText(de: "Super geübt! Weiter so.", tr: "Çok iyi çalıştın! Böyle devam et.", en: "Great practice! Keep it up."),
        LobText(de: "Geschafft! Das war richtig gut.", tr: "Bitti! Çok iyiydi.", en: "Done! That was really good.")
    ]

    static let endeGeuebt: [LobText] = [
        LobText(de: "Geschafft! Jedes Mal üben macht dich besser.", tr: "Bitti! Her çalışma seni daha iyi yapıyor.", en: "Done! Every bit of practice makes you better."),
        LobText(de: "Gut, dass du drangeblieben bist, {name}!", tr: "Devam ettiğin için aferin, {name}!", en: "Well done for keeping at it, {name}!"),
        LobText(de: "Runde geschafft! Beim nächsten Mal klappt noch mehr.", tr: "Tur bitti! Bir dahaki sefere daha da iyi olacak.", en: "Round finished! Next time even more will work."),
        LobText(de: "Du hast durchgehalten. Toll!", tr: "Sonuna kadar dayandın. Harika!", en: "You kept going. Great!"),
        LobText(de: "Üben ist wie Sport. Du wirst immer stärker!", tr: "Çalışmak spor gibi. Gittikçe güçleniyorsun!", en: "Practising is like sport. You keep getting stronger!")
    ]

    // MARK: Auswahl

    /// Lob für eine richtige Antwort.
    /// `serie`: so viele richtig hintereinander, diese mitgezählt.
    /// `nachFehler`: vorher war bei dieser Aufgabe schon ein falscher Versuch.
    static func fuerRichtig(serie: Int, nachFehler: Bool, name: String,
                            zufall: Double = Double.random(in: 0..<1)) -> LobText {
        if let s = serienLob(serie) { return s }
        if nachFehler { return waehle(Self.nachFehler, "nachFehler", name: name) }
        let n = vorname(name)
        if !n.isEmpty && zufall < 0.25 { return waehle(mitName, "mitName", name: n) }
        return waehle(richtig, "richtig", name: n)
    }

    /// Ein besonderes Lob, wenn eine Serie eine schöne Zahl erreicht, sonst nil.
    static func serienLob(_ n: Int) -> LobText? {
        switch n {
        case 3: return LobText(de: "Drei richtig hintereinander!", tr: "Arka arkaya üç doğru!", en: "Three right in a row!")
        case 5: return LobText(de: "Fünf am Stück! Du bist in Fahrt!", tr: "Arka arkaya beş! Çok iyi gidiyorsun!", en: "Five in a row! You're on a roll!")
        case 8: return LobText(de: "Acht hintereinander! Unglaublich!", tr: "Arka arkaya sekiz! İnanılmaz!", en: "Eight in a row! Incredible!")
        case 10: return LobText(de: "Zehn richtig am Stück! Du bist ein Star!", tr: "Arka arkaya on doğru! Sen bir yıldızsın!", en: "Ten right in a row! You're a star!")
        case let x where x >= 15 && x % 5 == 0:
            return LobText(de: "Schon \(x) richtig hintereinander! Rekordverdächtig!",
                           tr: "Arka arkaya \(x) doğru! Rekor gibi!",
                           en: "Already \(x) right in a row! That could be a record!")
        default: return nil
        }
    }

    static func fuerNochmal() -> LobText {
        waehle(nochmal, "nochmal", name: "")
    }

    static func titelDaneben() -> String {
        daneben[Abwechslung.index("daneben", anzahl: daneben.count)]
    }

    /// Satz am Ende einer Runde, passend zum Ergebnis.
    static func fuerEnde(richtig: Int, gesamt: Int, name: String) -> LobText {
        let anteil = gesamt > 0 ? Double(richtig) / Double(gesamt) : 0
        let n = vorname(name)
        if gesamt > 0 && richtig >= gesamt { return waehle(endePerfekt, "endePerfekt", name: n) }
        if anteil >= 0.7 { return waehle(endeGut, "endeGut", name: n) }
        return waehle(endeGeuebt, "endeGeuebt", name: n)
    }

    // MARK: Helfer

    /// Nur der erste Vorname, ohne Leerzeichen am Rand
    /// "jonas" oder "JONAS" wird "Jonas", damit die Stimme den Namen nicht buchstabiert.
    /// Gemischte Schreibweisen wie "LeAnn" bleiben so, wie sie eingetragen sind.
    static func vorname(_ name: String) -> String {
        guard let erster = name.split(separator: " ").first.map(String.init) else { return "" }
        if erster == erster.lowercased() || (erster.count > 1 && erster == erster.uppercased()) {
            return erster.prefix(1).uppercased() + erster.dropFirst().lowercased()
        }
        return erster
    }

    /// Setzt den Namen ein. Ohne Namen fällt der Name samt Komma weg.
    static func mitNamen(_ t: LobText, _ name: String) -> LobText {
        LobText(de: einsetzen(t.de, name), tr: einsetzen(t.tr, name), en: einsetzen(t.en, name))
    }

    static func einsetzen(_ text: String, _ name: String) -> String {
        guard text.contains("{name}") else { return text }
        if !name.isEmpty { return text.replacingOccurrences(of: "{name}", with: name) }
        var t = text
        for muster in [", {name}", " {name}", "{name}, ", "{name} "] {
            t = t.replacingOccurrences(of: muster, with: "")
        }
        t = t.replacingOccurrences(of: "{name}", with: "")
        // Nach dem Weglassen am Anfang groß schreiben: "du bist spitze!" wird "Du bist spitze!"
        return t.prefix(1).uppercased() + t.dropFirst()
    }

    private static func waehle(_ liste: [LobText], _ schluessel: String, name: String) -> LobText {
        mitNamen(liste[Abwechslung.index(schluessel, anzahl: liste.count)], name)
    }
}

/// Zieht zufällig, aber nie einen der zuletzt gezogenen Einträge.
enum Abwechslung {
    private static var zuletzt: [String: [Int]] = [:]

    static func index(_ schluessel: String, anzahl: Int) -> Int {
        guard anzahl > 1 else { return 0 }
        let sperre = min(anzahl / 2, 6)
        let gesperrt = zuletzt[schluessel, default: []]
        let frei = (0..<anzahl).filter { !gesperrt.contains($0) }
        let i = frei.randomElement() ?? 0
        var neu = gesperrt + [i]
        if neu.count > sperre { neu.removeFirst(neu.count - sperre) }
        zuletzt[schluessel] = neu
        return i
    }

    static func vergessen() {
        zuletzt.removeAll()
    }
}
