import SwiftUI
import SpriteKit
import UIKit

// ============================================================
// MARK: - Zahlenlauf: Springen, ausweichen, sammeln
// Grafiken: Jumper Pack von Kenney (www.kenney.nl), CC0
// ============================================================

enum SpielBild {
    static let held = ["held_lauf1", "held_lauf2"]
    static let heldSprung = "held_sprung"
    static let heldAua = "held_aua"
    static let hindernisse = ["hindernis_kaktus", "hindernis_kugel", "hindernis_pilz"]
    static let muenze = "muenze"
    static let boden = "boden"
    static let huegel = "huegel"
}

final class LaufSzene: SKScene {

    /// Wird nach jedem Durchgang mit der Punktzahl aufgerufen.
    var beiEnde: ((Int) -> Void)?

    // Figuren
    private let spieler = SKSpriteNode(imageNamed: SpielBild.held[0])
    private let punkteLabel = SKLabelNode(text: "0")
    private let infoLabel = SKLabelNode(text: "Tippen und losrennen")
    private let untertitelLabel = SKLabelNode(text: "Tippen zum Springen")

    private var laufBilder: [SKTexture] = []
    private var sprungBild = SKTexture(imageNamed: SpielBild.heldSprung)
    private var auaBild = SKTexture(imageNamed: SpielBild.heldAua)

    private var bodenKacheln: [SKSpriteNode] = []
    private var huegel: [SKSpriteNode] = []
    private var hindernisse: [SKSpriteNode] = []
    private var sammler: [SKSpriteNode] = []

    // Zustand
    private var vy: CGFloat = 0
    private var amBoden = true
    private var laeuft = false
    private var vorbei = false
    private var punkte = 0
    private var vorigeZeit: TimeInterval = 0
    private var bisHindernis: CGFloat = 420
    private var bisMuenze: CGFloat = 280

    // Werte, die das Spielgefühl bestimmen
    private let schwerkraft: CGFloat = -2400
    private let sprungKraft: CGFloat = 840
    private let grundTempo: CGFloat = 330
    private let hoechstTempo: CGFloat = 780

    // Größen in Punkten
    private let spielerHoehe: CGFloat = 70
    private let hindernisHoehe: CGFloat = 58
    private let muenzGroesse: CGFloat = 38
    private let bodenHoehe: CGFloat = 56
    private let kachelBreite: CGFloat = 220

    private var bodenY: CGFloat { size.height * 0.24 }
    private var ruheY: CGFloat { bodenY + spielerHoehe / 2 }
    private var tempo: CGFloat { min(grundTempo + CGFloat(punkte) * 2.2, hoechstTempo) }

    // MARK: Aufbau

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(Theme.tiefNavy)
        laufBilder = SpielBild.held.map { SKTexture(imageNamed: $0) }
        for bild in laufBilder { bild.filteringMode = .linear }

        // Hügel im Hintergrund, zwei Stück für den nahtlosen Übergang
        for _ in 0..<2 {
            let berg = SKSpriteNode(imageNamed: SpielBild.huegel)
            berg.anchorPoint = CGPoint(x: 0, y: 0)
            berg.alpha = 0.16
            berg.zPosition = 0
            addChild(berg)
            huegel.append(berg)
        }

        // Boden aus aneinandergereihten Kacheln
        for _ in 0..<8 {
            let kachel = SKSpriteNode(imageNamed: SpielBild.boden)
            kachel.anchorPoint = CGPoint(x: 0, y: 1)
            kachel.size = CGSize(width: kachelBreite, height: bodenHoehe)
            kachel.zPosition = 2
            addChild(kachel)
            bodenKacheln.append(kachel)
        }

        spieler.size = groesse(fuer: laufBilder[0], hoehe: spielerHoehe)
        spieler.zPosition = 10
        addChild(spieler)
        starteLaufBild()

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

        ordneNeu()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        ordneNeu()
    }

    /// Hält das Seitenverhältnis des Bildes bei vorgegebener Höhe.
    private func groesse(fuer bild: SKTexture, hoehe: CGFloat) -> CGSize {
        let roh = bild.size()
        guard roh.height > 0 else { return CGSize(width: hoehe, height: hoehe) }
        return CGSize(width: hoehe * roh.width / roh.height, height: hoehe)
    }

    private func ordneNeu() {
        guard size.width > 0, size.height > 0 else { return }

        for (i, berg) in huegel.enumerated() {
            let breite = max(size.width * 1.2, 600)
            berg.size = CGSize(width: breite, height: breite * 0.5)
            berg.position = CGPoint(x: CGFloat(i) * breite, y: bodenY - 10)
        }

        for (i, kachel) in bodenKacheln.enumerated() {
            kachel.position = CGPoint(x: CGFloat(i) * kachelBreite, y: bodenY)
        }

        spieler.position = CGPoint(x: size.width * 0.22,
                                   y: amBoden ? ruheY : max(spieler.position.y, ruheY))
        punkteLabel.position = CGPoint(x: 24, y: size.height - 24)
        infoLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        untertitelLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62 - 36)
    }

    private func starteLaufBild() {
        spieler.removeAction(forKey: "laufen")
        guard laufBilder.count > 1 else { return }
        spieler.run(SKAction.repeatForever(
            SKAction.animate(with: laufBilder, timePerFrame: 0.13, resize: false, restore: false)
        ), withKey: "laufen")
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
        spieler.removeAction(forKey: "laufen")
        spieler.texture = sprungBild
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
        bisHindernis = 420
        bisMuenze = 280
        spieler.texture = laufBilder.first
        spieler.position = CGPoint(x: size.width * 0.22, y: ruheY)
        punkteLabel.text = "0"
        infoLabel.text = ""
        untertitelLabel.text = ""
        starteLaufBild()
    }

    // MARK: Spielschleife

    override func update(_ currentTime: TimeInterval) {
        let roh = currentTime - vorigeZeit
        vorigeZeit = currentTime
        guard roh > 0 else { return }
        let dt = CGFloat(min(roh, 1.0 / 30.0))

        bewegeHuegel(dt)
        guard laeuft, !vorbei else { return }

        // Schwerkraft
        vy += schwerkraft * dt
        spieler.position.y += vy * dt
        if spieler.position.y <= ruheY {
            spieler.position.y = ruheY
            vy = 0
            if !amBoden {
                amBoden = true
                starteLaufBild()
            }
        }

        let strecke = tempo * dt
        bewegeBoden(strecke)

        // Nachschub
        bisHindernis -= strecke
        if bisHindernis <= 0 {
            setzeHindernis()
            bisHindernis = CGFloat.random(in: 320...560)
        }
        bisMuenze -= strecke
        if bisMuenze <= 0 {
            setzeMuenze()
            bisMuenze = CGFloat.random(in: 190...370)
        }

        bewegeUndPruefe(strecke)
    }

    private func bewegeHuegel(_ dt: CGFloat) {
        let breite = huegel.first?.size.width ?? size.width
        for berg in huegel {
            berg.position.x -= grundTempo * 0.14 * dt
            if berg.position.x <= -breite {
                berg.position.x += breite * CGFloat(huegel.count)
            }
        }
    }

    private func bewegeBoden(_ strecke: CGFloat) {
        let gesamt = kachelBreite * CGFloat(bodenKacheln.count)
        for kachel in bodenKacheln {
            kachel.position.x -= strecke
            if kachel.position.x <= -kachelBreite {
                kachel.position.x += gesamt
            }
        }
    }

    private func setzeHindernis() {
        let name = SpielBild.hindernisse.randomElement() ?? SpielBild.hindernisse[0]
        let knoten = SKSpriteNode(imageNamed: name)
        knoten.size = groesse(fuer: knoten.texture ?? SKTexture(), hoehe: hindernisHoehe)
        knoten.zPosition = 5
        knoten.position = CGPoint(x: size.width + 80, y: bodenY + hindernisHoehe / 2)
        addChild(knoten)
        hindernisse.append(knoten)
    }

    private func setzeMuenze() {
        let knoten = SKSpriteNode(imageNamed: SpielBild.muenze)
        knoten.size = CGSize(width: muenzGroesse, height: muenzGroesse)
        knoten.zPosition = 5
        knoten.position = CGPoint(x: size.width + 50,
                                  y: bodenY + CGFloat.random(in: 46...200))
        knoten.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 0.25, duration: 0.5),
            SKAction.scaleX(to: 1.0, duration: 0.5)
        ])))
        addChild(knoten)
        sammler.append(knoten)
    }

    private func bewegeUndPruefe(_ strecke: CGFloat) {
        var bleiben: [SKSpriteNode] = []
        for knoten in hindernisse {
            knoten.position.x -= strecke
            if trifft(knoten, breite: 38, hoehe: 48) {
                ende()
                return
            }
            if knoten.position.x < -80 {
                knoten.removeFromParent()
                punkte += 1
            } else {
                bleiben.append(knoten)
            }
        }
        hindernisse = bleiben

        var uebrig: [SKSpriteNode] = []
        for knoten in sammler {
            knoten.position.x -= strecke
            if trifft(knoten, breite: 36, hoehe: 40) {
                punkte += 10
                knoten.removeFromParent()
                continue
            }
            if knoten.position.x < -50 {
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
        spieler.removeAction(forKey: "laufen")
        spieler.texture = auaBild
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
