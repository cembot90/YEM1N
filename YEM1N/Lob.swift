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

/// Ein Satz auf Deutsch und Türkisch. {name} wird durch den Namen ersetzt.
struct LobText: Equatable, Sendable {
    let de: String
    let tr: String
}

enum Lob {

    // MARK: Satzlisten

    static let richtig: [LobText] = [
        LobText(de: "Super!", tr: "Süper!"),
        LobText(de: "Toll gemacht!", tr: "Aferin!"),
        LobText(de: "Richtig!", tr: "Doğru!"),
        LobText(de: "Prima!", tr: "Harika!"),
        LobText(de: "Klasse!", tr: "Bravo!"),
        LobText(de: "Spitze!", tr: "Çok iyi!"),
        LobText(de: "Genau!", tr: "Tam olarak!"),
        LobText(de: "Stark!", tr: "Süpersin!"),
        LobText(de: "Wunderbar!", tr: "Muhteşem!"),
        LobText(de: "Sehr gut!", tr: "Çok güzel!"),
        LobText(de: "Bravo!", tr: "Tebrikler!"),
        LobText(de: "Das stimmt!", tr: "Evet, doğru!"),
        LobText(de: "Perfekt!", tr: "Mükemmel!"),
        LobText(de: "Ganz genau!", tr: "Kesinlikle doğru!"),
        LobText(de: "Volltreffer!", tr: "Tam isabet!"),
        LobText(de: "Du bist ein Profi!", tr: "Sen bir ustasın!"),
        LobText(de: "Wow, richtig!", tr: "Vay, doğru!"),
        LobText(de: "Das hast du super gemacht!", tr: "Çok güzel yaptın!"),
        LobText(de: "Treffer!", tr: "İşte bu!"),
        LobText(de: "Du hast es!", tr: "Bildin!"),
        LobText(de: "Klasse gemacht!", tr: "Harikasın!"),
        LobText(de: "Richtig gut!", tr: "Çok başarılı!"),
        LobText(de: "Juhu, richtig!", tr: "Yaşasın, doğru!"),
        LobText(de: "Gut aufgepasst!", tr: "İyi dikkat ettin!")
    ]

    static let mitName: [LobText] = [
        LobText(de: "Super, {name}!", tr: "Süper, {name}!"),
        LobText(de: "Toll, {name}!", tr: "Aferin {name}!"),
        LobText(de: "Genau so, {name}!", tr: "Tam böyle, {name}!"),
        LobText(de: "{name}, du bist spitze!", tr: "{name}, harikasın!"),
        LobText(de: "Richtig, {name}!", tr: "Doğru, {name}!"),
        LobText(de: "Klasse gemacht, {name}!", tr: "Bravo {name}!"),
        LobText(de: "Das kannst du, {name}!", tr: "Bunu biliyorsun, {name}!"),
        LobText(de: "Wow, {name}!", tr: "Vay be, {name}!")
    ]

    static let nachFehler: [LobText] = [
        LobText(de: "Jetzt hat es geklappt!", tr: "İşte şimdi oldu!"),
        LobText(de: "Siehst du, du schaffst das!", tr: "Gördün mü, yapabiliyorsun!"),
        LobText(de: "Nicht aufgegeben. Stark!", tr: "Pes etmedin. Aferin!"),
        LobText(de: "Genau, jetzt stimmt es!", tr: "Evet, şimdi doğru!"),
        LobText(de: "Gut nachgedacht!", tr: "İyi düşündün!"),
        LobText(de: "Dranbleiben lohnt sich!", tr: "Devam etmek işe yarıyor!"),
        LobText(de: "Beim zweiten Mal richtig. Prima!", tr: "İkinci denemede doğru. Harika!")
    ]

    /// Wenn es in der Vorschule noch nicht stimmt. Danach darf das Kind nochmal tippen.
    static let nochmal: [LobText] = [
        LobText(de: "Fast! Probier es noch einmal.", tr: "Neredeyse! Bir daha dene."),
        LobText(de: "Knapp daneben. Du schaffst das!", tr: "Az kaldı. Yapabilirsin!"),
        LobText(de: "Hmm, schau noch mal genau hin.", tr: "Hmm, bir daha dikkatlice bak."),
        LobText(de: "Noch nicht ganz. Versuch es noch mal!", tr: "Tam değil. Tekrar dene!"),
        LobText(de: "Oh, nicht ganz. Gleich hast du es!", tr: "Ah, tam değil. Neredeyse buldun!"),
        LobText(de: "Kein Problem, noch ein Versuch!", tr: "Sorun değil, bir deneme daha!"),
        LobText(de: "Hoppla! Noch einmal?", tr: "Hoppala! Bir daha?"),
        LobText(de: "Das war es nicht. Probier ein anderes!", tr: "Bu değil. Başka birini dene!"),
        LobText(de: "Fehler sind nicht schlimm. Noch mal!", tr: "Hata yapmak sorun değil. Bir daha!"),
        LobText(de: "Überleg noch mal in Ruhe.", tr: "Bir daha sakince düşün.")
    ]

    /// Kurzer Titel, wenn in Mathe oder Deutsch eine Antwort falsch war
    static let daneben: [String] = [
        "Noch nicht richtig.", "Knapp daneben.", "Leider nicht.", "Fast.",
        "Das war es nicht.", "Hoppla, nicht ganz.", "Noch nicht ganz.", "Nicht schlimm, weiter geht es."
    ]

    static let endePerfekt: [LobText] = [
        LobText(de: "Alles richtig! Du bist ein Star!", tr: "Hepsi doğru! Sen bir yıldızsın!"),
        LobText(de: "Keinen einzigen Fehler. Wahnsinn!", tr: "Hiç hata yok. İnanılmaz!"),
        LobText(de: "Perfekte Runde, {name}!", tr: "Mükemmel bir tur, {name}!"),
        LobText(de: "Alles geschafft und alles richtig. Super!", tr: "Hepsini bitirdin, hepsi doğru. Süper!"),
        LobText(de: "Volle Punktzahl! Darauf kannst du stolz sein.", tr: "Tam puan! Kendinle gurur duyabilirsin.")
    ]

    static let endeGut: [LobText] = [
        LobText(de: "Das hast du toll gemacht!", tr: "Çok güzel yaptın!"),
        LobText(de: "Starke Runde, {name}!", tr: "Harika bir tur, {name}!"),
        LobText(de: "Fast alles richtig. Klasse!", tr: "Neredeyse hepsi doğru. Bravo!"),
        LobText(de: "Super geübt! Weiter so.", tr: "Çok iyi çalıştın! Böyle devam et."),
        LobText(de: "Geschafft! Das war richtig gut.", tr: "Bitti! Çok iyiydi.")
    ]

    static let endeGeuebt: [LobText] = [
        LobText(de: "Geschafft! Jedes Mal üben macht dich besser.", tr: "Bitti! Her çalışma seni daha iyi yapıyor."),
        LobText(de: "Gut, dass du drangeblieben bist, {name}!", tr: "Devam ettiğin için aferin, {name}!"),
        LobText(de: "Runde geschafft! Beim nächsten Mal klappt noch mehr.", tr: "Tur bitti! Bir dahaki sefere daha da iyi olacak."),
        LobText(de: "Du hast durchgehalten. Toll!", tr: "Sonuna kadar dayandın. Harika!"),
        LobText(de: "Üben ist wie Sport. Du wirst immer stärker!", tr: "Çalışmak spor gibi. Gittikçe güçleniyorsun!")
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
        case 3: return LobText(de: "Drei richtig hintereinander!", tr: "Arka arkaya üç doğru!")
        case 5: return LobText(de: "Fünf am Stück! Du bist in Fahrt!", tr: "Arka arkaya beş! Çok iyi gidiyorsun!")
        case 8: return LobText(de: "Acht hintereinander! Unglaublich!", tr: "Arka arkaya sekiz! İnanılmaz!")
        case 10: return LobText(de: "Zehn richtig am Stück! Du bist ein Star!", tr: "Arka arkaya on doğru! Sen bir yıldızsın!")
        case let x where x >= 15 && x % 5 == 0:
            return LobText(de: "Schon \(x) richtig hintereinander! Rekordverdächtig!",
                           tr: "Arka arkaya \(x) doğru! Rekor gibi!")
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
        LobText(de: einsetzen(t.de, name), tr: einsetzen(t.tr, name))
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
