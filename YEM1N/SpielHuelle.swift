import SwiftUI
import SpriteKit

// ============================================================
// MARK: - Gemeinsame Hülle für die Spiele mit SpriteKit
// ============================================================

protocol SpielSzene: SKScene {
    /// Wird nach jedem Durchgang mit der Punktzahl aufgerufen.
    var beiEnde: ((Int) -> Void)? { get set }
}

struct SpielHuelle<Szene: SpielSzene>: View {
    @Environment(\.dismiss) private var dismiss
    @State private var szene: Szene
    @State private var bestwert: Int
    @State private var rekord = false
    private let schluessel: String

    init(schluessel: String, szene: Szene) {
        self.schluessel = schluessel
        _szene = State(initialValue: szene)
        _bestwert = State(initialValue: Muenzen.bestwert(schluessel))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.tiefNavy.ignoresSafeArea()
            SpriteView(scene: szene)
                .ignoresSafeArea()

            VStack(alignment: .trailing, spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.navy)
                        .frame(width: 44, height: 44)
                        .background(Theme.gelb, in: Circle())
                }
                if bestwert > 0 {
                    Text(rekord ? "Neuer Rekord: \(bestwert)" : "Bestwert: \(bestwert)")
                        .font(.system(.footnote, design: .rounded).weight(.heavy))
                        .foregroundStyle(rekord ? Theme.navy : Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(rekord ? Theme.gelb : Color.black.opacity(0.35), in: Capsule())
                }
            }
            .padding(16)
        }
        .statusBarHidden()
        .onAppear {
            szene.beiEnde = { punkte in
                if Muenzen.merkeBestwert(schluessel, punkte) {
                    bestwert = punkte
                    rekord = true
                } else {
                    rekord = false
                }
            }
        }
    }
}

/// Gemeinsame kleine Helfer für die Szenen.
enum SpielHilfe {
    static func beschrifte(_ label: SKLabelNode, groesse: CGFloat, farbe: UIColor, fett: Bool) {
        label.fontName = fett ? "AvenirNext-Heavy" : "AvenirNext-Medium"
        label.fontSize = groesse
        label.fontColor = farbe
        label.zPosition = 30
    }

    /// Hält das Seitenverhältnis des Bildes bei vorgegebener Höhe.
    static func groesse(fuer bild: SKTexture, hoehe: CGFloat) -> CGSize {
        let roh = bild.size()
        guard roh.height > 0 else { return CGSize(width: hoehe, height: hoehe) }
        return CGSize(width: hoehe * roh.width / roh.height, height: hoehe)
    }

    static func funkel(in szene: SKScene, ort: CGPoint, text: String = "✦") {
        let stern = SKLabelNode(text: text)
        stern.fontSize = 26
        stern.fontColor = UIColor(Theme.gelb)
        stern.position = ort
        stern.zPosition = 25
        szene.addChild(stern)
        stern.run(SKAction.sequence([
            SKAction.group([SKAction.moveBy(x: 0, y: 36, duration: 0.4),
                            SKAction.fadeOut(withDuration: 0.4)]),
            SKAction.removeFromParent()
        ]))
    }
}
