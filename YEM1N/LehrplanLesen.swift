import Foundation

// ============================================================
// MARK: - Lernwelt Deutsch: Lesen und verstehen
// ============================================================
//
// Kurze, selbst geschriebene Texte mit Fragen dazu. Klasse 1 liest zwei Sätze,
// Klasse 4 längere Sachtexte, bei denen man auch zwischen den Zeilen lesen muss.
// Jede Antwort steht im Text oder folgt eindeutig daraus.

struct LeseText {
    let titel: String
    let text: String
    /// Frage, richtige Antwort, falsche Antworten
    let fragen: [(String, String, [String])]
}

enum LehrplanLesen {
    static var themen: [LernThema] {
        [
            LernThema(id: "l1-lesen", fach: .deutsch, titel: "Lesen und verstehen", emoji: "📗",
                      beschreibung: "Zwei Sätze lesen und eine Frage beantworten", klasse: 1,
                      tipp: "Lies den Text zweimal. Die Antwort steht im Text.", erzeuge: { LehrplanLesen.aufgabe(LehrplanLesen.klasse1) }),
            LernThema(id: "l2-lesen", fach: .deutsch, titel: "Lesen und verstehen", emoji: "📘",
                      beschreibung: "Kleine Geschichten", klasse: 2,
                      tipp: "Lies erst die Frage, dann suche die Stelle im Text.", erzeuge: { LehrplanLesen.aufgabe(LehrplanLesen.klasse2) }),
            LernThema(id: "l3-lesen", fach: .deutsch, titel: "Lesen und verstehen", emoji: "📙",
                      beschreibung: "Geschichten und Sachtexte", klasse: 3,
                      tipp: "Lies erst die Frage, dann suche die Stelle im Text.", erzeuge: { LehrplanLesen.aufgabe(LehrplanLesen.klasse3) }),
            LernThema(id: "l4-lesen", fach: .deutsch, titel: "Lesen und verstehen", emoji: "📕",
                      beschreibung: "Sachtexte und zwischen den Zeilen lesen", klasse: 4,
                      tipp: "Manche Antwort steht nicht wörtlich da. Überlege, was der Text bedeutet.",
                      erzeuge: { LehrplanLesen.aufgabe(LehrplanLesen.klasse4) })
        ]
    }

    static func aufgabe(_ texte: [LeseText]) -> LernAufgabe {
        let t = Lern.eins(texte)
        let (frage, richtig, falsch) = Lern.eins(t.fragen)
        return Lern.wahl(frage: frage, rechnung: t.titel + "\n\n" + t.text, richtig: richtig, falsch: falsch,
                         erklaerung: "Richtig ist: \(richtig).")
    }

    static let klasse1: [LeseText] = [
        LeseText(titel: "Der Ball", text: "Tim hat einen roten Ball. Er spielt im Garten.",
                 fragen: [("Welche Farbe hat der Ball?", "rot", ["blau", "gelb"]),
                          ("Wo spielt Tim?", "im Garten", ["in der Schule", "im Bad"])]),
        LeseText(titel: "Mimi", text: "Die Katze heißt Mimi. Sie trinkt Milch.",
                 fragen: [("Wie heißt die Katze?", "Mimi", ["Lilo", "Bello"]),
                          ("Was trinkt Mimi?", "Milch", ["Saft", "Tee"])]),
        LeseText(titel: "Der Kuchen", text: "Oma backt einen Kuchen. Der Kuchen ist süß.",
                 fragen: [("Wer backt?", "Oma", ["Opa", "Mama"]),
                          ("Wie ist der Kuchen?", "süß", ["sauer", "salzig"])]),
        LeseText(titel: "Der Regenbogen", text: "Am Himmel ist ein Regenbogen. Er hat viele Farben.",
                 fragen: [("Was ist am Himmel?", "ein Regenbogen", ["ein Flugzeug", "ein Vogel"]),
                          ("Wie viele Farben hat der Regenbogen?", "viele", ["nur eine", "zwei"])]),
        LeseText(titel: "Die Hasen", text: "Ben hat zwei Hasen. Sie fressen Möhren.",
                 fragen: [("Wie viele Hasen hat Ben?", "zwei", ["drei", "einen"]),
                          ("Was fressen die Hasen?", "Möhren", ["Äpfel", "Nüsse"])]),
        LeseText(titel: "Der Apfel", text: "Ida isst einen Apfel. Der Apfel ist grün.",
                 fragen: [("Was isst Ida?", "einen Apfel", ["eine Birne", "eine Banane"]),
                          ("Welche Farbe hat der Apfel?", "grün", ["rot", "gelb"])])
    ]

    static let klasse2: [LeseText] = [
        LeseText(titel: "Bruno im Park",
                 text: "Lena geht mit ihrem Hund Bruno in den Park. Bruno holt gern Stöcke. Plötzlich sieht er ein Eichhörnchen und rennt los. Lena muss lachen.",
                 fragen: [("Wie heißt der Hund?", "Bruno", ["Max", "Rex"]),
                          ("Was holt Bruno gern?", "Stöcke", ["Bälle", "Knochen"]),
                          ("Was sieht Bruno plötzlich?", "ein Eichhörnchen", ["eine Katze", "einen Vogel"])]),
        LeseText(titel: "Ali ist krank",
                 text: "Heute ist Ali krank. Er hat Halsschmerzen und bleibt im Bett. Mama bringt ihm einen warmen Tee mit Honig. Am Nachmittag geht es ihm schon besser.",
                 fragen: [("Warum bleibt Ali im Bett?", "Er ist krank.", ["Er ist müde.", "Es ist Sonntag."]),
                          ("Was bringt Mama?", "Tee mit Honig", ["Kakao", "Suppe"]),
                          ("Wann geht es Ali besser?", "am Nachmittag", ["am Morgen", "am nächsten Tag"])]),
        LeseText(titel: "Bunte Blätter",
                 text: "Im Herbst fallen die Blätter von den Bäumen. Sie werden gelb, rot und braun. Mia sammelt die schönsten Blätter. Daraus bastelt sie ein Bild.",
                 fragen: [("Wann fallen die Blätter?", "im Herbst", ["im Sommer", "im Frühling"]),
                          ("Was bastelt Mia aus den Blättern?", "ein Bild", ["eine Kette", "einen Hut"])]),
        LeseText(titel: "Die Sandburg",
                 text: "Tom und Sara bauen im Sand eine große Burg. Tom holt Wasser mit dem Eimer. Sara baut einen Turm. Am Ende stecken sie eine Muschel auf die Spitze.",
                 fragen: [("Wer baut den Turm?", "Sara", ["Tom", "Mama"]),
                          ("Womit holt Tom Wasser?", "mit dem Eimer", ["mit der Schaufel", "mit den Händen"]),
                          ("Was stecken sie auf die Spitze?", "eine Muschel", ["eine Fahne", "einen Stein"])])
    ]

    static let klasse3: [LeseText] = [
        LeseText(titel: "Der Igel",
                 text: "Igel sind kleine Tiere mit vielen Stacheln. Ein Igel hat etwa 7000 Stacheln. Wenn er Angst hat, rollt er sich zu einer Kugel zusammen. Igel fressen am liebsten Käfer, Würmer und Schnecken. Im Winter halten sie Winterschlaf.",
                 fragen: [("Wie viele Stacheln hat ein Igel etwa?", "etwa 7000", ["etwa 700", "etwa 70"]),
                          ("Was macht ein Igel, wenn er Angst hat?", "Er rollt sich zusammen.", ["Er rennt weg.", "Er bellt laut."]),
                          ("Was macht der Igel im Winter?", "Er hält Winterschlaf.", ["Er fliegt in den Süden.", "Er sammelt Äpfel."]),
                          ("Was frisst der Igel am liebsten?", "Käfer, Würmer und Schnecken", ["Äpfel und Birnen", "Gras und Blätter"])]),
        LeseText(titel: "Allein zum Bäcker",
                 text: "Jonas geht zum ersten Mal allein zum Bäcker. Mama gibt ihm fünf Euro. Er kauft vier Brötchen und eine Brezel. An der Kasse bekommt er Geld zurück. Stolz läuft er nach Hause.",
                 fragen: [("Was kauft Jonas?", "vier Brötchen und eine Brezel", ["ein Brot", "einen Kuchen"]),
                          ("Wie viel Geld gibt Mama ihm?", "fünf Euro", ["zehn Euro", "zwei Euro"]),
                          ("Wie fühlt sich Jonas am Ende?", "stolz", ["traurig", "wütend"])]),
        LeseText(titel: "Bienen",
                 text: "Bienen leben in einem Bienenstock. Dort wohnen viele tausend Bienen und eine Königin. Die Arbeiterinnen fliegen von Blüte zu Blüte und sammeln Nektar. Daraus machen sie Honig. Dabei bestäuben sie die Blüten, damit Früchte wachsen können.",
                 fragen: [("Wer lebt mit den Bienen im Stock?", "eine Königin", ["ein König", "ein Bär"]),
                          ("Was sammeln die Arbeiterinnen?", "Nektar", ["Wasser", "Sand"]),
                          ("Was machen die Bienen aus dem Nektar?", "Honig", ["Zucker", "Milch"])]),
        LeseText(titel: "Das letzte Tor",
                 text: "Beim Fußballspiel steht es 2 zu 2. Noch eine Minute ist zu spielen. Ida bekommt den Ball und läuft auf das Tor zu. Sie schießt, und der Ball landet im Netz. Ihre Mannschaft gewinnt 3 zu 2.",
                 fragen: [("Wie steht es kurz vor Schluss?", "2 zu 2", ["1 zu 0", "3 zu 1"]),
                          ("Wer schießt das letzte Tor?", "Ida", ["der Torwart", "der Trainer"]),
                          ("Wie endet das Spiel?", "3 zu 2", ["2 zu 2", "2 zu 3"])])
    ]

    static let klasse4: [LeseText] = [
        LeseText(titel: "Der Mond",
                 text: "Der Mond ist der Begleiter der Erde. Er leuchtet nicht selbst, sondern wird von der Sonne angestrahlt. Deshalb sehen wir ihn mal als schmale Sichel und mal als volle Scheibe. Für eine Runde um die Erde braucht er ungefähr einen Monat. Im Jahr 1969 betraten zum ersten Mal Menschen den Mond.",
                 fragen: [("Warum leuchtet der Mond?", "Die Sonne strahlt ihn an.", ["Er hat eigene Lampen.", "Er brennt wie ein Feuer."]),
                          ("Wie lange braucht der Mond für eine Runde um die Erde?", "ungefähr einen Monat", ["einen Tag", "ein Jahr"]),
                          ("Wann waren zum ersten Mal Menschen auf dem Mond?", "1969", ["1869", "2009"])]),
        LeseText(titel: "Alles weiß",
                 text: "Als Luis morgens aus dem Fenster schaut, ist alles weiß. Schnell zieht er seine dicke Jacke, Mütze und Handschuhe an. Draußen holt er seinen Schlitten aus dem Keller. Mit seiner Schwester fährt er den Hügel hinunter, bis es dunkel wird. Abends sind beide müde, aber glücklich.",
                 fragen: [("Warum ist draußen alles weiß?", "Es hat geschneit.", ["Es ist neblig.", "Jemand hat alles angemalt."]),
                          ("Was holt Luis aus dem Keller?", "seinen Schlitten", ["sein Fahrrad", "seinen Ball"]),
                          ("Wie fühlen sich die Kinder am Abend?", "müde und glücklich", ["traurig", "wütend und hungrig"])]),
        LeseText(titel: "Wasser",
                 text: "Wasser gibt es in drei Formen. Als Eis ist es fest, im Glas ist es flüssig und als Dampf ist es gasförmig. Wasser gefriert bei 0 Grad Celsius zu Eis. Bei 100 Grad kocht es und wird zu Dampf. Ohne Wasser könnten Menschen, Tiere und Pflanzen nicht leben.",
                 fragen: [("Bei wie viel Grad gefriert Wasser?", "bei 0 Grad", ["bei 10 Grad", "bei 100 Grad"]),
                          ("Wie nennt man Wasser, wenn es gasförmig ist?", "Dampf", ["Eis", "Regen"]),
                          ("In wie vielen Formen gibt es Wasser?", "in drei", ["in zwei", "in vier"])]),
        LeseText(titel: "Der Neue",
                 text: "In der Pause sieht Nele, dass Emil allein auf der Bank sitzt. Er ist neu in der Klasse und kennt noch niemanden. Nele setzt sich zu ihm und fragt, ob er mitspielen möchte. Emil lächelt und nickt. Ab diesem Tag spielen die beiden jede Pause zusammen.",
                 fragen: [("Warum sitzt Emil allein?", "Er ist neu und kennt noch niemanden.", ["Er hat sich verletzt.", "Er möchte lieber lesen."]),
                          ("Was macht Nele?", "Sie fragt ihn, ob er mitspielt.", ["Sie lacht ihn aus.", "Sie holt die Lehrerin."]),
                          ("Welches Wort passt zu Nele?", "freundlich", ["frech", "ängstlich"])])
    ]
}
