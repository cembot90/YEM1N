import SwiftUI
import SwiftData

// ============================================================
// MARK: - Reiter "Ich" (Kind) und "Lernen" (Eltern)
// iOS zeigt unten höchstens fünf Reiter, alles danach verschwindet im Menü "Mehr".
// Darum sammeln diese beiden Seiten, was vorher eigene Reiter waren.
// ============================================================

/// Kind-Gerät: alles über mich. Joker-Tipps der Familie, Erfolge, Spiele und Einstellungen.
struct KindIchView: View {
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("muenzen") private var muenzen = 0
    @AppStorage("spieleErlaubt") private var spieleErlaubt = true
    @AppStorage(HaustierSpeicher.key) private var haustierDaten = Data()
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle == "lokal" })
    private var lokale: [RundenErgebnis]
    @State private var zeigeErfolge = false
    @State private var zeigeSpiele = false
    @State private var zeigeDuell = false
    private let joker = JokerStand.shared

    private var tier: Haustier? { HaustierSpeicher.dekodiere(haustierDaten) }

    private var chips: [HeroChip] {
        var c: [HeroChip] = []
        let serie = Erfolge.geschuetzteSerie(lokale).laenge
        if serie > 0 { c.append(HeroChip(text: "🔥 \(serie) \(serie == 1 ? "Tag" : "Tage")", hervorgehoben: true)) }
        c.append(HeroChip(text: "🪙 \(muenzen)"))
        c.append(HeroChip(text: "🃏 \(joker.uebrigHeute) übrig"))
        return c
    }

    var body: some View {
        NavigationStack {
            HeroSeite {
                HeroKopf(kicker: "Ich",
                         titel: kindName.isEmpty ? "Hallo!" : "Hallo \(kindName)!",
                         untertitel: "Deine Joker-Tipps, Erfolge und Einstellungen",
                         bild: tier?.emoji ?? "🌟",
                         chips: chips)

                AbschnittsTitel("Joker-Tipps", text: "Hilfe von deiner Familie")
                KindJokerView(eingebettet: true)

                AbschnittsTitel("Für mich")
                Button { zeigeErfolge = true } label: {
                    BereichsKarte(bild: "🏆", titel: "Meine Erfolge",
                                  text: "Abzeichen, Serie und Wochenziel")
                }
                .buttonStyle(TastenStil())
                .einblenden(1)
                if spieleErlaubt {
                    Button { zeigeSpiele = true } label: {
                        BereichsKarte(bild: "🎮", titel: "Spiele",
                                      text: "Mit deinen Münzen spielen")
                    }
                    .buttonStyle(TastenStil())
                    .einblenden(2)
                }
                // Das Duell ist Üben und kostet keine Münzen, darum steht es auch ohne Spiele da
                Button { zeigeDuell = true } label: {
                    BereichsKarte(bild: "⚔️", titel: "Duell",
                                  text: "Kopfrechnen gegen deine Familie")
                }
                .buttonStyle(TastenStil())
                .einblenden(3)

                AbschnittsTitel("Einstellungen und Hilfe")
                ZeilenGruppe {
                    NavigationLink { EinstellungenInhalt() } label: {
                        EinstellungsZeile(symbol: "gearshape.fill", titel: "Einstellungen",
                                          text: "Profil, Familie, Farben und mehr")
                    }
                    .buttonStyle(.plain)
                    ZeilenTrenner()
                    NavigationLink { InfoView() } label: {
                        EinstellungsZeile(symbol: "book.fill", titel: "Anleitung",
                                          text: "So funktioniert YEM1N", farbe: Theme.himmel)
                    }
                    .buttonStyle(.plain)
                }
            }
            .refreshable { await JokerCloud.shared.aktualisieren() }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $zeigeErfolge) {
                ErfolgeView()
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
            .sheet(isPresented: $zeigeSpiele) {
                SpieleView()
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
            .sheet(isPresented: $zeigeDuell) {
                DuellView(zeigeSchliessen: true)
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
        }
    }
}

/// Eltern-Gerät: Schule, Sprachen und Vorschule ausprobieren und Aufgaben verwalten.
struct ElternLernenView: View {
    @Query private var alleArbeiten: [Klassenarbeit]
    @AppStorage("vorschulTab") private var vorschulAn = true
    @AppStorage(SprachAuswahl.anSchluessel) private var sprachenAn = false
    @State private var offen: LernBereich?

    enum LernBereich: String, Identifiable {
        case schule, sprachen, vorschule, duell
        var id: String { rawValue }
    }

    private var schulAnzahl: Int {
        alleArbeiten.filter { $0.spezial.isEmpty && $0.fach != "Vorschule" }.count
    }

    var body: some View {
        NavigationStack {
            HeroSeite {
                HeroKopf(kicker: "Lernen", titel: "Aufgaben und Übungen",
                         untertitel: "So sieht dein Kind die Aufgaben. Hier kannst du alles ausprobieren und neue Aufgaben verteilen.",
                         bild: "📚",
                         chips: [HeroChip(text: "\(schulAnzahl) \(schulAnzahl == 1 ? "Klassenarbeit" : "Klassenarbeiten")",
                                          hervorgehoben: schulAnzahl > 0)])

                AbschnittsTitel("Bereiche")
                Button { offen = .schule } label: {
                    BereichsKarte(bild: "✏️", titel: "Schule",
                                  text: "Klassenarbeiten, Fehlerheft und Training", betont: true)
                }
                .buttonStyle(TastenStil())
                .einblenden(3)
                if sprachenAn {
                    Button { offen = .sprachen } label: {
                        BereichsKarte(bild: "🌍", titel: "Sprachen",
                                      text: "Wörter lernen mit Bildern und Vorlesen")
                    }
                    .buttonStyle(TastenStil())
                    .einblenden(4)
                }
                if vorschulAn {
                    Button { offen = .vorschule } label: {
                        BereichsKarte(bild: "🧸", titel: "Vorschule",
                                      text: "Zählen, Formen, Buchstaben und mehr")
                    }
                    .buttonStyle(TastenStil())
                    .einblenden(5)
                }
                Button { offen = .duell } label: {
                    BereichsKarte(bild: "⚔️", titel: "Duell",
                                  text: "Kopfrechnen gegen dein Kind, jeder auf seiner Stufe")
                }
                .buttonStyle(TastenStil())
                .einblenden(6)

                AbschnittsTitel("Aufgaben verwalten")
                ZeilenGruppe {
                    NavigationLink { MatheEditorView() } label: {
                        EinstellungsZeile(symbol: "square.and.pencil", titel: "Aufgaben-Editor",
                                          text: "Eigene Klassenarbeiten bauen")
                    }
                    .buttonStyle(.plain)
                    ZeilenTrenner()
                    NavigationLink { PaketeView() } label: {
                        EinstellungsZeile(symbol: "icloud.and.arrow.up.fill", titel: "Aufgaben verteilen",
                                          text: "An die Kind-Geräte oder die Klasse schicken",
                                          farbe: Theme.mint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $offen) { bereich in
                switch bereich {
                case .schule:
                    VollbildRahmen(titel: "Schule") { StartView() }
                case .sprachen:
                    VollbildRahmen(titel: "Sprachen") { SprachStartView() }
                case .vorschule:
                    VollbildRahmen(titel: "Vorschule") { VorschuleView() }
                case .duell:
                    VollbildRahmen(titel: "Duell") { DuellView() }
                }
            }
        }
    }
}
