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
    @AppStorage("jokerIch") private var jokerIch = ""
    @AppStorage("profilFertig") private var profilFertig = false
    @State private var schritt = 0
    @State private var name = ""
    @State private var klasse = ""
    @State private var geladen = false
    private let joker = JokerStand.shared

    private var istKind: Bool { modus == "kind" }
    private var letzterSchritt: Int { istKind ? 3 : 0 }

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
                    if istKind {
                        Text("Schritt \(schritt + 1) von 4")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textSanft)
                    }
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
    }

    @ViewBuilder
    private var inhalt: some View {
        if !istKind {
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
            frageKarte("Wie heißt das Kind?", "Ein Vorname oder Spitzname reicht. Der Name erscheint bei den Eltern.") {
                TextField("Name", text: $name)
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
            frageKarte("Welche Sprachen möchtest du lernen?", "Tippe an, was du lernen willst. Du kannst es später in den Einstellungen ändern. Wenn du nichts wählst, gibt es keinen Sprachen-Bereich.") {
                SprachWahlChips()
            }
        } else {
            frageKarte("Farben und Ziel", "Wähle die Farbwelt und wie viele Runden pro Tag das Ziel sind.") {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        farbKarte("Blau und Gelb", "blau")
                        farbKarte("Rosa", "rosa")
                    }
                    Stepper("Tagesziel: \(tagesziel) \(tagesziel == 1 ? "Runde" : "Runden")",
                            value: $tagesziel, in: 1...10)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.white)
                }
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
