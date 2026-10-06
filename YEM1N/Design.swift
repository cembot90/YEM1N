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

// MARK: - Design (Lacivert und Sari)

enum Theme {
    // Farbwelt wird in den Einstellungen gewählt: "blau" (Standard) oder "rosa"
    static var rosa: Bool = UserDefaults.standard.string(forKey: "farbwelt") == "rosa"

    static var gelb: Color {
        rosa ? Color(red: 1.0, green: 0.45, blue: 0.74) : Color(red: 1.0, green: 0.93, blue: 0.0)
    }
    static var navy: Color {
        rosa ? Color(red: 0.36, green: 0.07, blue: 0.31) : Color(red: 0.0, green: 0.125, blue: 0.357)
    }
    static var tiefNavy: Color {
        rosa ? Color(red: 0.14, green: 0.02, blue: 0.14) : Color(red: 0.0, green: 0.045, blue: 0.16)
    }
    static var glanz: Color {
        rosa ? Color(red: 0.92, green: 0.30, blue: 0.66) : Color(red: 0.16, green: 0.4, blue: 0.85)
    }
    static var himmel: Color {
        rosa ? Color(red: 0.80, green: 0.68, blue: 1.0) : Color(red: 0.45, green: 0.78, blue: 1.0)
    }
    static let koralle = Color(red: 1.0, green: 0.42, blue: 0.42)
    static let mint = Color(red: 0.45, green: 0.95, blue: 0.62)
    static let textSanft = Color.white.opacity(0.7)
}

struct HintergrundView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.navy, Theme.tiefNavy],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Theme.glanz.opacity(0.35), .clear],
                           center: .top, startRadius: 0, endRadius: 420)
        }
        .ignoresSafeArea()
    }
}

struct GlasKarteStil: ViewModifier {
    let radius: CGFloat
    @AppStorage("glasEffekt") private var glas = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if !glas {
            content.flachKarte(radius: radius)
        } else {
            // Liquid Glass ab iOS 26, sonst Material mit feiner Kante
            #if compiler(>=6.2)
            if #available(iOS 26.0, *) {
                content.glassEffect(.regular, in: .rect(cornerRadius: radius))
            } else {
                content.materialKarte(radius: radius)
            }
            #else
            content.materialKarte(radius: radius)
            #endif
        }
    }
}

extension View {
    func glasKarte(radius: CGFloat = 24) -> some View {
        modifier(GlasKarteStil(radius: radius))
    }

    func flachKarte(radius: CGFloat) -> some View {
        self
            .background(Color.white.opacity(0.09),
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
    }

    func materialKarte(radius: CGFloat) -> some View {
        self
            .background(.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
    }
}

struct Fortschrittsring: View {
    var wert: Double
    var breite: CGFloat = 7

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.14), lineWidth: breite)
            Circle()
                .trim(from: 0, to: min(max(wert, 0), 1))
                .stroke(Theme.gelb, style: StrokeStyle(lineWidth: breite, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: wert)
        }
    }
}

struct TastenStil: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct GelberKnopf: View {
    let titel: String
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            Text(titel)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.navy)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Theme.gelb, in: Capsule())
        }
        .buttonStyle(TastenStil())
        .padding(.horizontal, 24)
    }
}

// Eingabe für Textaufgaben (Deutsch): normale Tastatur, Umlaute und ß als Tasten
struct TextAntwortFeld: View {
    @Binding var text: String
    var onPruefen: () -> Void
    @FocusState private var fokus: Bool

    private let sonderzeichen = ["ä", "ö", "ü", "ß", "Ä", "Ö", "Ü"]

    var body: some View {
        VStack(spacing: 12) {
            TextField("Antwort", text: $text)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($fokus)
                .onSubmit(onPruefen)
                .frame(minHeight: 62)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.gelb, lineWidth: 2.5)
                )
                .padding(.horizontal, 24)

            HStack(spacing: 8) {
                ForEach(sonderzeichen, id: \.self) { z in
                    Button { text += z } label: {
                        Text(z)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(Color.white)
                            .background(Color.white.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(TastenStil())
                }
            }
            .padding(.horizontal, 24)

            GelberKnopf(titel: "Prüfen", aktion: onPruefen)
        }
        .onAppear { fokus = true }
    }
}
