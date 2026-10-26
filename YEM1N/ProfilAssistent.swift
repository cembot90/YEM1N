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
// MARK: - Profil und Einrichtungsassistent
// ============================================================

enum ProfilDaten {
    static let klassen = ["Vorschule", "Klasse 1", "Klasse 2", "Klasse 3", "Klasse 4"]
}

struct ProfilAssistent: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @AppStorage("farbwelt") private var farbwelt = "blau"
    @AppStorage("tagesziel") private var tagesziel = 2
    @AppStorage("vorschulTab") private var vorschulTab = true
    @AppStorage(SprachAuswahl.anSchluessel) private var sprachenAn = false
    @AppStorage("jokerIch") private var jokerIch = ""
    @AppStorage(VorleseText.automatischSchluessel) private var automatischVorlesen = false
    @AppStorage("profilFertig") private var profilFertig = false
    @State private var schritt = 0
    @State private var name = ""
    @State private var klasse = ""
    @State private var geladen = false
    @State private var elternName = ""
    private let joker = JokerStand.shared
    private let familie = FamilienModell.shared

    private var istKind: Bool { modus == "kind" }
    /// Kind: Name, Klasse, Sprachen, Farben, Familie. Eltern: Wer bist du, Familie.
    private var letzterSchritt: Int { istKind ? 4 : 1 }
    private var familienSchrittNr: Int { letzterSchritt }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 22) {
                    Text("Willkommen bei YEM1N")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                    Text("Schritt \(schritt + 1) von \(letzterSchritt + 1)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textSanft)
                    inhalt
                    knoepfe
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            guard !geladen else { return }
            geladen = true
            name = kindName
            klasse = kindKlasse
        }
        .onChange(of: schritt) {
            if !istKind && schritt == familienSchrittNr && elternName.isEmpty {
                elternName = CloudDienst.ichName()
            }
        }
        // Wartet dieses Gerät auf die Freigabe der Eltern, fragt der Assistent von selbst nach.
        .task(id: familie.zugang?.status ?? "keine") {
            while !Task.isCancelled && familie.wartet {
                await familie.statusPruefen()
                try? await Task.sleep(for: .seconds(4))
            }
        }
    }

    @ViewBuilder
    private var inhalt: some View {
        if schritt == familienSchrittNr {
            familienSchritt
        } else if !istKind {
            frageKarte("Wer bist du?", "Unter diesem Namen erscheinen deine Antworten auf Joker-Fragen.") {
                let aktuell = jokerIch.isEmpty ? (joker.mitglieder.first?.id.uuidString ?? "") : jokerIch
                VStack(spacing: 10) {
                    ForEach(joker.mitglieder) { m in
                        chip("\(m.emoji) \(m.name)", aktiv: aktuell == m.id.uuidString) {
                            jokerIch = m.id.uuidString
                        }
                    }
                }
            }
        } else if schritt == 0 {
            frageKarte("Wie heißt das Kind?", "Ein Vorname oder Spitzname reicht, bitte keinen Nachnamen. Der Name erscheint bei den Eltern.") {
                TextField("Name", text: $name)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .padding(14)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        } else if schritt == 1 {
            frageKarte("In welcher Klasse?", "Danach lädt das Gerät nur passende Aufgabenpakete. Du kannst es später ändern.") {
                VStack(spacing: 10) {
                    ForEach(ProfilDaten.klassen, id: \.self) { k in
                        chip(k, aktiv: klasse == k) { klasse = k }
                    }
                    chip("Weiß ich nicht", aktiv: klasse.isEmpty) { klasse = "" }
                }
            }
        } else if schritt == 2 {
            frageKarte("Auch Sprachen üben?", "Wörter in anderen Sprachen mit Bildern und Vorlesen. Der Bereich ist noch ein Versuch mit wenigen Wörtern. Du kannst es später unter Einstellungen > Bereiche ändern.") {
                VStack(spacing: 10) {
                    chip("Ja, Sprachen anzeigen", aktiv: sprachenAn) { sprachenAn = true }
                    chip("Nein, erstmal nicht", aktiv: !sprachenAn) { sprachenAn = false }
                    if sprachenAn {
                        SprachWahlChips()
                    }
                }
            }
        } else {   // Kind, Schritt 3
            frageKarte("Farben, Ziel und Vorlesen", "Wähle die Farbwelt, wie viele Runden pro Tag das Ziel sind und ob Aufgaben von selbst vorgelesen werden. Alles lässt sich später in den Einstellungen ändern.") {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        farbKarte("Blau und Gelb", "blau")
                        farbKarte("Rosa", "rosa")
                    }
                    Stepper("Tagesziel: \(tagesziel) \(tagesziel == 1 ? "Runde" : "Runden")",
                            value: $tagesziel, in: 1...10)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.white)
                    Toggle("Aufgaben automatisch vorlesen", isOn: $automatischVorlesen)
                        .tint(Theme.gelb)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.white)
                    Text("Sonst liest die App nur vor, wenn das Kind auf den gelben Lautsprecher tippt.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private var familienSchritt: some View {
        frageKarte("Mit der Familie verbinden",
                   istKind
                   ? "Dann sehen deine Eltern deine Ergebnisse und können dir bei Jokern helfen. Das geht nur mit einem QR-Code von Mama oder Papa. Du kannst es auch später machen."
                   : "Lege eine neue Familie an oder scanne den QR-Code von einem anderen Eltern-Gerät. Ohne Familie bleibt alles nur auf diesem Gerät. Du kannst es auch später machen.") {
            if let z = familie.zugang {
                VStack(alignment: .leading, spacing: 10) {
                    if z.aktiv {
                        Label("Verbunden. Das Gerät gehört zur Familie.", systemImage: "checkmark.seal.fill")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.mint)
                    } else if z.wartet {
                        Text("Fast geschafft! Mama oder Papa muss dieses Gerät noch erlauben.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.white)
                        Text("Prüfcode")
                            .font(.caption)
                            .foregroundStyle(Theme.textSanft)
                        Text(z.pruefcode)
                            .font(.system(size: 34, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white)
                        Text("Du kannst schon loslegen. Sobald die Eltern erlaubt haben, gehen Ergebnisse und Joker hin und her.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                    } else {
                        Text(familie.meldung.isEmpty ? "Dieses Gerät wurde nicht erlaubt." : familie.meldung)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.koralle)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                FamilieVerbindenKarten(eltern: !istKind, name: istKind ? $name : $elternName)
            }
        }
    }

    private var knoepfe: some View {
        VStack(spacing: 12) {
            Button {
                if schritt < letzterSchritt {
                    schritt += 1
                } else {
                    fertigstellen()
                }
            } label: {
                Text(schritt < letzterSchritt ? "Weiter" : "Los geht's")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            if schritt > 0 {
                Button("Zurück") { schritt -= 1 }
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textSanft)
            } else {
                Button("Später einrichten") { profilFertig = true }
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textSanft)
            }
        }
    }

    private func fertigstellen() {
        if istKind {
            kindName = name.trimmingCharacters(in: .whitespaces)
            kindKlasse = klasse
            if klasse == "Vorschule" {
                vorschulTab = true
            } else if !klasse.isEmpty {
                vorschulTab = false
            }
        }
        profilFertig = true
    }

    private func frageKarte<Inhalt: View>(_ titel: String, _ text: String,
                                          @ViewBuilder inhalt: () -> Inhalt) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(titel)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
            inhalt()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func chip(_ titel: String, aktiv: Bool, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Text(titel)
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(aktiv ? Theme.navy : Color.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(aktiv ? Theme.gelb : Color.white.opacity(0.10), in: Capsule())
        }
        .buttonStyle(TastenStil())
    }

    private func farbKarte(_ titel: String, _ wert: String) -> some View {
        let aktiv = farbwelt == wert
        let farben: [Color] = wert == "rosa"
            ? [Color(red: 0.36, green: 0.07, blue: 0.31), Color(red: 1.0, green: 0.45, blue: 0.74)]
            : [Color(red: 0.0, green: 0.125, blue: 0.357), Color(red: 1.0, green: 0.93, blue: 0.0)]
        return Button {
            Theme.rosa = (wert == "rosa")
            farbwelt = wert
        } label: {
            VStack(spacing: 8) {
                LinearGradient(colors: farben, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(titel)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(aktiv ? 0.18 : 0.06),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(aktiv ? Theme.gelb : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(TastenStil())
    }
}
