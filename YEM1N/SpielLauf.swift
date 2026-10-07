import SwiftUI
import SpriteKit
import UIKit

// ============================================================
// MARK: - Zahlenlauf: Springen, ausweichen, sammeln
// ============================================================

final class LaufSzene: SKScene {

    /// Wird nach jedem Durchgang mit der Punktzahl aufgerufen.
    var beiEnde: ((Int) -> Void)?

    // Figuren
    private let spieler = SKLabelNode(text: "🦊")
    private let boden = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 5))
    private let punkteLabel = SKLabelNode(text: "0")
    private let infoLabel = SKLabelNode(text: "Tippen und losrennen")
    private let untertitelLabel = SKLabelNode(text: "Tippen zum Springen")

    private var hindernisse: [SKLabelNode] = []
    private var sammler: [SKLabelNode] = []
    private var wolken: [SKLabelNode] = []

    // Zustand
    private var vy: CGFloat = 0
    private var amBoden = true
    private var laeuft = false
    private var vorbei = false
    private var punkte = 0
    private var vorigeZeit: TimeInterval = 0
    private var bisHindernis: CGFloat = 400
    private var bisMuenze: CGFloat = 260

    // Werte, die das Spielgefühl bestimmen
    private let schwerkraft: CGFloat = -2400
    private let sprungKraft: CGFloat = 820
    private let grundTempo: CGFloat = 330
    private let hoechstTempo: CGFloat = 760

    private var bodenY: CGFloat { size.height * 0.24 }
    private var ruheY: CGFloat { bodenY + 26 }
    private var tempo: CGFloat { min(grundTempo + CGFloat(punkte) * 2.2, hoechstTempo) }

    // MARK: Aufbau

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(Theme.tiefNavy)

        boden.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        boden.alpha = 0.35
        boden.zPosition = 1
        addChild(boden)

        spieler.fontSize = 48
        spieler.verticalAlignmentMode = .center
        spieler.horizontalAlignmentMode = .center
        spieler.zPosition = 10
        addChild(spieler)

        punkteLabel.fontName = "AvenirNext-Heavy"
        punkteLabel.fontSize = 30
        punkteLabel.fontColor = UIColor(Theme.gelb)
        punkteLabel.horizontalAlignmentMode = .left
        punkteLabel.verticalAlignmentMode = .top
        punkteLabel.zPosition = 20
        addChild(punkteLabel)

        infoLabel.fontName = "AvenirNext-Heavy"
        infoLabel.fontSize = 34
        infoLabel.fontColor = .white
        infoLabel.verticalAlignmentMode = .center
        infoLabel.zPosition = 20
        addChild(infoLabel)

        untertitelLabel.fontName = "AvenirNext-Medium"
        untertitelLabel.fontSize = 19
        untertitelLabel.fontColor = UIColor(Theme.gelb)
        untertitelLabel.verticalAlignmentMode = .center
        untertitelLabel.zPosition = 20
        addChild(untertitelLabel)

        for _ in 0..<4 {
            let wolke = SKLabelNode(text: "☁️")
            wolke.fontSize = CGFloat.random(in: 26...44)
            wolke.alpha = 0.5
            wolke.verticalAlignmentMode = .center
            wolke.zPosition = 0
            addChild(wolke)
            wolken.append(wolke)
        }
        verteileWolken()
        ordneNeu()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        ordneNeu()
    }

    private func ordneNeu() {
        guard size.width > 0 else { return }
        boden.size = CGSize(width: size.width, height: 5)
        boden.position = CGPoint(x: size.width / 2, y: bodenY)
        if amBoden { spieler.position = CGPoint(x: size.width * 0.22, y: ruheY) }
        spieler.position.x = size.width * 0.22
        punkteLabel.position = CGPoint(x: 24, y: size.height - 24)
        infoLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        untertitelLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62 - 36)
    }

    private func verteileWolken() {
        for wolke in wolken {
            wolke.position = CGPoint(x: CGFloat.random(in: 0...max(size.width, 1)),
                                     y: CGFloat.random(in: size.height * 0.55...size.height * 0.92))
        }
    }

    // MARK: Steuerung

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if vorbei {
            neuStarten()
        } else if !laeuft {
            laeuft = true
            infoLabel.text = ""
            untertitelLabel.text = ""
        } else {
            springen()
        }
    }

    private func springen() {
        guard amBoden else { return }
        vy = sprungKraft
        amBoden = false
        spieler.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.12)
        ]))
    }

    private func neuStarten() {
        for knoten in hindernisse { knoten.removeFromParent() }
        for knoten in sammler { knoten.removeFromParent() }
        hindernisse = []
        sammler = []
        punkte = 0
        vy = 0
        amBoden = true
        vorbei = false
        laeuft = true
        bisHindernis = 400
        bisMuenze = 260
        spieler.text = "🦊"
        spieler.position = CGPoint(x: size.width * 0.22, y: ruheY)
        punkteLabel.text = "0"
        infoLabel.text = ""
        untertitelLabel.text = ""
        verteileWolken()
    }

    // MARK: Spielschleife

    override func update(_ currentTime: TimeInterval) {
        let roh = currentTime - vorigeZeit
        vorigeZeit = currentTime
        guard vorigeZeit > 0, roh > 0 else { return }
        let dt = CGFloat(min(roh, 1.0 / 30.0))

        bewegeWolken(dt)
        guard laeuft, !vorbei else { return }

        // Schwerkraft
        vy += schwerkraft * dt
        spieler.position.y += vy * dt
        if spieler.position.y <= ruheY {
            spieler.position.y = ruheY
            vy = 0
            amBoden = true
        }

        let strecke = tempo * dt

        // Nachschub
        bisHindernis -= strecke
        if bisHindernis <= 0 {
            setzeHindernis()
            bisHindernis = CGFloat.random(in: 300...520)
        }
        bisMuenze -= strecke
        if bisMuenze <= 0 {
            setzeMuenze()
            bisMuenze = CGFloat.random(in: 180...360)
        }

        bewegeUndPruefe(strecke)
    }

    private func bewegeWolken(_ dt: CGFloat) {
        for wolke in wolken {
            wolke.position.x -= grundTempo * 0.18 * dt
            if wolke.position.x < -40 {
                wolke.position.x = size.width + 40
                wolke.position.y = CGFloat.random(in: size.height * 0.55...size.height * 0.92)
            }
        }
    }

    private func setzeHindernis() {
        let knoten = SKLabelNode(text: ["🌵", "🪨", "🌵"].randomElement() ?? "🌵")
        knoten.fontSize = 42
        knoten.verticalAlignmentMode = .center
        knoten.horizontalAlignmentMode = .center
        knoten.zPosition = 5
        knoten.position = CGPoint(x: size.width + 60, y: bodenY + 22)
        addChild(knoten)
        hindernisse.append(knoten)
    }

    private func setzeMuenze() {
        let knoten = SKLabelNode(text: "🪙")
        knoten.fontSize = 30
        knoten.verticalAlignmentMode = .center
        knoten.horizontalAlignmentMode = .center
        knoten.zPosition = 5
        knoten.position = CGPoint(x: size.width + 40,
                                  y: bodenY + CGFloat.random(in: 34...170))
        addChild(knoten)
        sammler.append(knoten)
    }

    private func bewegeUndPruefe(_ strecke: CGFloat) {
        // Hindernisse
        var bleiben: [SKLabelNode] = []
        for knoten in hindernisse {
            knoten.position.x -= strecke
            if trifft(knoten, breite: 34, hoehe: 40) {
                ende()
                return
            }
            if knoten.position.x < -60 {
                knoten.removeFromParent()
                punkte += 1
            } else {
                bleiben.append(knoten)
            }
        }
        hindernisse = bleiben

        // Münzen
        var uebrig: [SKLabelNode] = []
        for knoten in sammler {
            knoten.position.x -= strecke
            if trifft(knoten, breite: 32, hoehe: 32) {
                punkte += 10
                knoten.removeFromParent()
                continue
            }
            if knoten.position.x < -40 {
                knoten.removeFromParent()
            } else {
                uebrig.append(knoten)
            }
        }
        sammler = uebrig

        punkteLabel.text = "\(punkte)"
    }

    private func trifft(_ knoten: SKNode, breite: CGFloat, hoehe: CGFloat) -> Bool {
        abs(knoten.position.x - spieler.position.x) < breite
            && abs(knoten.position.y - spieler.position.y) < hoehe
    }

    private func ende() {
        vorbei = true
        laeuft = false
        spieler.text = "😵"
        infoLabel.text = "\(punkte) Punkte"
        untertitelLabel.text = "Tippen für noch einen Versuch"
        beiEnde?(punkte)
    }
}

// MARK: - Die Hülle in SwiftUI

struct SpielLaufView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var szene: LaufSzene = {
        let neu = LaufSzene(size: CGSize(width: 1024, height: 576))
        neu.scaleMode = .resizeFill
        return neu
    }()
    @State private var bestwert = Muenzen.bestwert("lauf")
    @State private var rekord = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
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
                if Muenzen.merkeBestwert("lauf", punkte) {
                    bestwert = punkte
                    rekord = true
                } else {
                    rekord = false
                }
            }
        }
    }
}
