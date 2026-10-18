import SwiftUI
import SpriteKit

// ============================================================
// MARK: - Einhorn-Flug
// Tippen lässt das Einhorn steigen. Es sammelt Sterne und Regenbögen und
// weicht Gewitterwolken aus. Alles funktioniert über Bilder, ohne Lesen.
// ============================================================

final class EinhornSzene: SKScene, SpielSzene {

    var beiEnde: ((Int) -> Void)?

    private typealias R = EinhornRegeln

    static func neu() -> EinhornSzene {
        let szene = EinhornSzene(size: CGSize(width: R.breite, height: R.hoehe))
        szene.scaleMode = .aspectFit
        return szene
    }

    private struct Objekt {
        let knoten: SKLabelNode
        let ding: R.Ding
    }

    // MARK: Knoten

    private let einhorn = SKLabelNode(text: "🦄")
    private let spur = SKEmitterNode()
    private let punkteLabel = SKLabelNode(text: "⭐ 0")
    private let tippHand = SKLabelNode(text: "👆")
    private let grossLabel = SKLabelNode(text: "")
    private var herzen: [SKLabelNode] = []
    private var wolken: [SKNode] = []

    // MARK: Zustand

    private var objekte: [Objekt] = []
    private var vy: CGFloat = 0
    private var punkte = 0
    private var leben = R.maxLeben
    private var level = 1
    private var laeuft = false
    private var vorbei = false
    private var schutz: CGFloat = 0
    private var bisNaechstes: Double = 1
    private var vorigeZeit: TimeInterval = 0

    // MARK: Aufbau

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.62, green: 0.80, blue: 1.0, alpha: 1)
        let himmel = SKSpriteNode(texture: SpielEffekte.verlauf(
            oben: UIColor(red: 0.50, green: 0.72, blue: 1.0, alpha: 1),
            unten: UIColor(red: 1.0, green: 0.82, blue: 0.93, alpha: 1), groesse: size))
        himmel.size = size
        himmel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        himmel.zPosition = -50
        addChild(himmel)
        SpielEffekte.kamera(in: self)

        let sonne = SKSpriteNode(texture: SpielEffekte.punktTextur)
        sonne.size = CGSize(width: 220, height: 220)
        sonne.color = UIColor(red: 1.0, green: 0.92, blue: 0.5, alpha: 1)
        sonne.colorBlendFactor = 1
        sonne.position = CGPoint(x: R.breite - 130, y: R.hoehe - 110)
        sonne.zPosition = -45
        addChild(sonne)
        sonne.run(.repeatForever(.sequence([.scale(to: 1.08, duration: 1.6), .scale(to: 1.0, duration: 1.6)])))

        for i in 0..<6 {
            let w = baueWolke(gross: i < 3)
            w.position = CGPoint(x: CGFloat.random(in: 0...R.breite), y: CGFloat.random(in: 120...(R.hoehe - 60)))
            w.zPosition = i < 3 ? -30 : -20
            w.alpha = i < 3 ? 0.55 : 0.85
            addChild(w)
            wolken.append(w)
        }

        einhorn.fontSize = 84
        einhorn.verticalAlignmentMode = .center
        einhorn.xScale = -1
        einhorn.zPosition = 20
        addChild(einhorn)

        baueRegenbogenSpur()

        SpielHilfe.beschrifte(punkteLabel, groesse: 40, farbe: UIColor(red: 0.45, green: 0.20, blue: 0.55, alpha: 1),
                              fett: true)
        punkteLabel.verticalAlignmentMode = .center
        punkteLabel.position = CGPoint(x: R.breite / 2, y: R.hoehe - 40)
        addChild(punkteLabel)

        for i in 0..<R.maxLeben {
            let h = SKLabelNode(text: "💖")
            h.fontSize = 34
            h.verticalAlignmentMode = .center
            h.position = CGPoint(x: 40 + CGFloat(i) * 44, y: R.hoehe - 40)
            h.zPosition = 30
            addChild(h)
            herzen.append(h)
        }

        grossLabel.fontName = "AvenirNext-Heavy"
        grossLabel.fontSize = 72
        grossLabel.fontColor = UIColor(red: 0.45, green: 0.20, blue: 0.55, alpha: 1)
        grossLabel.verticalAlignmentMode = .center
        grossLabel.position = CGPoint(x: R.breite / 2, y: R.hoehe / 2 + 60)
        grossLabel.zPosition = 40
        addChild(grossLabel)

        tippHand.fontSize = 80
        tippHand.verticalAlignmentMode = .center
        tippHand.position = CGPoint(x: R.breite / 2, y: R.hoehe / 2 - 50)
        tippHand.zPosition = 40
        addChild(tippHand)
        tippHand.run(.repeatForever(.sequence([.moveBy(x: 0, y: -18, duration: 0.35),
                                               .moveBy(x: 0, y: 18, duration: 0.35)])), withKey: "zeigen")

        stelleAuf()
    }

    private func baueWolke(gross: Bool) -> SKNode {
        let w = SKNode()
        let f: CGFloat = gross ? 1.6 : 1.0
        for (dx, dy, r) in [(CGFloat(-36), CGFloat(0), CGFloat(28)), (0, 14, 38), (38, 2, 30), (10, -10, 30)] {
            let teil = SKShapeNode(circleOfRadius: r * f)
            teil.fillColor = .white
            teil.strokeColor = .clear
            teil.position = CGPoint(x: dx * f, y: dy * f)
            w.addChild(teil)
        }
        return w
    }

    private func baueRegenbogenSpur() {
        spur.particleTexture = SpielEffekte.punktTextur
        spur.particleBirthRate = 70
        spur.particleLifetime = 0.9
        spur.particlePositionRange = CGVector(dx: 6, dy: 26)
        spur.emissionAngle = .pi
        spur.particleSpeed = 120
        spur.particleAlphaSpeed = -1.1
        spur.particleScale = 0.9
        spur.particleScaleSpeed = -0.8
        spur.particleColorBlendFactor = 1
        spur.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.cyan,
                             UIColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 1)],
            times: [0, 0.18, 0.36, 0.54, 0.72, 1])
        spur.zPosition = 18
        spur.targetNode = self
        addChild(spur)
    }

    private func stelleAuf() {
        einhorn.position = CGPoint(x: 220, y: R.hoehe / 2)
        einhorn.zRotation = 0
        einhorn.alpha = 1
        vy = 0
        spur.position = CGPoint(x: einhorn.position.x - 40, y: einhorn.position.y - 6)
        zeichneHerzen()
    }

    private func zeichneHerzen() {
        for (i, h) in herzen.enumerated() {
            h.alpha = i < leben ? 1 : 0.2
        }
        punkteLabel.text = "⭐ \(punkte)"
    }

    // MARK: Steuerung

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if vorbei {
            neuStarten()
            return
        }
        if !laeuft {
            laeuft = true
            tippHand.isHidden = true
            grossLabel.text = ""
        }
        vy = R.flugStoss
        einhorn.run(.sequence([.scaleY(to: 1.12, duration: 0.08), .scaleY(to: 1.0, duration: 0.12)]))
    }

    // MARK: Spielschleife

    override func update(_ currentTime: TimeInterval) {
        let dt: CGFloat = vorigeZeit == 0 ? 0 : min(CGFloat(currentTime - vorigeZeit), 1.0 / 30.0)
        vorigeZeit = currentTime

        // Wolken ziehen immer, auch vor dem Start
        for (i, w) in wolken.enumerated() {
            w.position.x -= (i < 3 ? 30 : 60) * dt
            if w.position.x < -120 {
                w.position = CGPoint(x: R.breite + 120, y: CGFloat.random(in: 120...(R.hoehe - 60)))
            }
        }

        guard laeuft, !vorbei else {
            // Vor dem Start schwebt das Einhorn sanft
            einhorn.position.y = R.hoehe / 2 + sin(CGFloat(currentTime) * 2) * 14
            spur.position = CGPoint(x: einhorn.position.x - 40, y: einhorn.position.y - 6)
            return
        }

        // Fliegen: sanfte Schwerkraft, oben und unten ein weicher Rand
        vy -= R.schwerkraft * dt
        einhorn.position.y += vy * dt
        if einhorn.position.y < 60 {
            einhorn.position.y = 60
            vy = R.flugStoss * 0.6
        }
        if einhorn.position.y > R.hoehe - 70 {
            einhorn.position.y = R.hoehe - 70
            vy = min(vy, 0)
        }
        einhorn.zRotation = max(-0.35, min(0.35, vy / 900))
        spur.position = CGPoint(x: einhorn.position.x - 40, y: einhorn.position.y - 6)

        if schutz > 0 {
            schutz -= dt
            einhorn.alpha = Int(schutz * 10) % 2 == 0 ? 0.4 : 1
            if schutz <= 0 { einhorn.alpha = 1 }
        }

        // Neue Dinge
        bisNaechstes -= Double(dt)
        if bisNaechstes <= 0 {
            bisNaechstes = R.abstand(level: level) * Double.random(in: 0.8...1.2)
            erzeuge()
        }

        // Bewegen und fangen
        let tempo = R.tempo(level: level)
        var bleiben: [Objekt] = []
        for o in objekte {
            o.knoten.position.x -= tempo * dt
            let abstand = hypot(o.knoten.position.x - einhorn.position.x, o.knoten.position.y - einhorn.position.y)
            if abstand < R.fangAbstand {
                if o.ding == .gewitter && schutz > 0 {
                    bleiben.append(o)
                    continue
                }
                fange(o)
                continue
            }
            if o.knoten.position.x < -80 {
                o.knoten.removeFromParent()
                continue
            }
            bleiben.append(o)
        }
        objekte = bleiben
    }

    private func erzeuge() {
        let ding = R.naechstes(zufall: Double.random(in: 0...1), level: level, leben: leben)
        let k = SKLabelNode(text: ding.bild)
        k.fontSize = ding == .gewitter ? 70 : 56
        k.verticalAlignmentMode = .center
        k.position = CGPoint(x: R.breite + 60, y: CGFloat.random(in: 90...(R.hoehe - 100)))
        k.zPosition = 15
        if ding != .gewitter {
            k.run(.repeatForever(.sequence([.scale(to: 1.15, duration: 0.4), .scale(to: 1.0, duration: 0.4)])))
        } else {
            k.run(.repeatForever(.sequence([.moveBy(x: 0, y: 12, duration: 0.6), .moveBy(x: 0, y: -12, duration: 0.6)])))
        }
        addChild(k)
        objekte.append(Objekt(knoten: k, ding: ding))
    }

    private func fange(_ o: Objekt) {
        let vorher = level
        (punkte, leben) = R.fange(o.ding, punkte: punkte, leben: leben)
        switch o.ding {
        case .gewitter:
            schutz = 1.6
            SpielEffekte.blitz(in: self, farbe: UIColor(red: 0.5, green: 0.5, blue: 0.9, alpha: 1))
            SpielEffekte.wackeln(in: self, staerke: 9)
            Haptik.fehler()
        case .herz:
            SpielEffekte.funken(in: self, ort: o.knoten.position,
                                farbe: UIColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 1), anzahl: 24)
            Haptik.erfolg()
        case .regenbogen:
            SpielEffekte.konfetti(in: self, ort: o.knoten.position, anzahl: 40)
            SpielEffekte.aufspringen(in: self, ort: o.knoten.position, text: "+3",
                                     farbe: UIColor(red: 0.45, green: 0.20, blue: 0.55, alpha: 1))
            Haptik.leicht()
        case .stern:
            SpielEffekte.funken(in: self, ort: o.knoten.position)
            Haptik.leicht()
        }
        o.knoten.removeFromParent()
        level = R.level(punkte: punkte)
        if level > vorher {
            SpielEffekte.konfetti(in: self, ort: CGPoint(x: R.breite / 2, y: R.hoehe * 0.6))
            SpielEffekte.aufspringen(in: self, ort: CGPoint(x: R.breite / 2, y: R.hoehe / 2), text: "🌟",
                                     groesse: 90)
        }
        zeichneHerzen()
        if leben <= 0 { ende() }
    }

    private func ende() {
        vorbei = true
        laeuft = false
        einhorn.alpha = 1
        for o in objekte { o.knoten.removeFromParent() }
        objekte = []
        grossLabel.text = "⭐ \(punkte)"
        tippHand.isHidden = false
        SpielEffekte.konfetti(in: self, ort: CGPoint(x: R.breite / 2, y: R.hoehe / 2))
        beiEnde?(punkte)
    }

    private func neuStarten() {
        vorbei = false
        punkte = 0
        leben = R.maxLeben
        level = 1
        schutz = 0
        bisNaechstes = 1
        grossLabel.text = ""
        tippHand.isHidden = true
        stelleAuf()
        laeuft = true
        vy = R.flugStoss
    }
}

struct SpielEinhornView: View {
    var body: some View {
        SpielHuelle(schluessel: "einhorn", szene: EinhornSzene.neu())
    }
}
