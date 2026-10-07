import SwiftUI
import SpriteKit

// ============================================================
// MARK: - Münz-Hockey
// Tischhockey gegen den Computer. Die Münze ist der Puck.
// Wer zuerst fünf Tore hat, gewinnt. Danach wird der Computer besser.
// ============================================================

final class HockeySzene: SKScene, SpielSzene {

    var beiEnde: ((Int) -> Void)?

    private typealias H = HockeyBalance

    static func neu() -> HockeySzene {
        let szene = HockeySzene(size: CGSize(width: H.breite, height: H.hoehe))
        szene.scaleMode = .aspectFit
        return szene
    }

    // MARK: Knoten

    private let puck = SKSpriteNode(imageNamed: "muenze")
    private let meinSchlaeger = SKSpriteNode(imageNamed: "held_sprung")
    private let kiSchlaeger = SKSpriteNode(imageNamed: "hindernis_kugel")
    private let standLabel = SKLabelNode(text: "")
    private let levelLabel = SKLabelNode(text: "Level 1")
    private let infoLabel = SKLabelNode(text: "Münz-Hockey")
    private let untertitelLabel = SKLabelNode(text: "Tippen zum Start. Mit dem Finger den Schläger bewegen.")

    // MARK: Zustand

    private var puckV = CGVector.zero
    private var meinV = CGVector.zero
    private var kiV = CGVector.zero
    private var ziel = CGPoint(x: 170, y: H.hoehe / 2)
    private var letzteMeinePosition = CGPoint(x: 170, y: H.hoehe / 2)
    private var kiVersatz = CGPoint.zero
    private var kiNeuRest: CGFloat = 0

    private var level = 1
    private var toreIch = 0
    private var toreKi = 0
    private var punkte = 0
    private var laeuft = false
    private var vorbei = false
    private var pausiert = false
    private var anstossRest: CGFloat = 0
    private var anstossRichtung: CGFloat = 1
    private var vorigeZeit: TimeInterval = 0

    // MARK: Maße

    private var links: CGFloat { H.rand }
    private var rechts: CGFloat { H.breite - H.rand }
    private var unten: CGFloat { H.rand }
    private var oben: CGFloat { H.hoehe - H.rand }
    private var mitte: CGFloat { H.breite / 2 }
    private var torUnten: CGFloat { (H.hoehe - H.torHoehe) / 2 }
    private var torOben: CGFloat { torUnten + H.torHoehe }
    private var trefferRadius: CGFloat { H.schlaegerRadius - 2 }

    // MARK: Aufbau

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(Theme.tiefNavy)
        zeichneFeld()

        puck.size = CGSize(width: H.puckRadius * 2, height: H.puckRadius * 2)
        puck.zPosition = 6
        addChild(puck)

        richteSchlaegerEin(meinSchlaeger, ring: UIColor(Theme.himmel))
        richteSchlaegerEin(kiSchlaeger, ring: UIColor(Theme.koralle))

        SpielHilfe.beschrifte(standLabel, groesse: 22, farbe: UIColor(Theme.gelb), fett: true)
        standLabel.verticalAlignmentMode = .center
        standLabel.position = CGPoint(x: mitte, y: H.hoehe - 18)
        addChild(standLabel)

        SpielHilfe.beschrifte(levelLabel, groesse: 16, farbe: .white, fett: true)
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: mitte, y: 18)
        addChild(levelLabel)

        SpielHilfe.beschrifte(infoLabel, groesse: 36, farbe: .white, fett: true)
        infoLabel.verticalAlignmentMode = .center
        infoLabel.position = CGPoint(x: mitte, y: H.hoehe / 2 + 70)
        addChild(infoLabel)

        SpielHilfe.beschrifte(untertitelLabel, groesse: 17, farbe: UIColor(Theme.gelb), fett: false)
        untertitelLabel.verticalAlignmentMode = .center
        untertitelLabel.position = CGPoint(x: mitte, y: H.hoehe / 2 + 32)
        addChild(untertitelLabel)

        stelleAuf()
        zeichneStand()
    }

    private func richteSchlaegerEin(_ knoten: SKSpriteNode, ring farbe: UIColor) {
        let textur = knoten.texture ?? SKTexture()
        knoten.size = SpielHilfe.groesse(fuer: textur, hoehe: H.schlaegerRadius * 1.9)
        knoten.zPosition = 7
        let ring = SKShapeNode(circleOfRadius: H.schlaegerRadius)
        ring.strokeColor = farbe
        ring.lineWidth = 5
        ring.fillColor = farbe.withAlphaComponent(0.18)
        ring.zPosition = -1
        knoten.addChild(ring)
        addChild(knoten)
    }

    private func zeichneFeld() {
        let feld = SKShapeNode(rect: CGRect(x: links, y: unten, width: rechts - links, height: oben - unten),
                               cornerRadius: 16)
        feld.fillColor = UIColor(Theme.navy)
        feld.strokeColor = UIColor.white.withAlphaComponent(0.7)
        feld.lineWidth = 5
        feld.zPosition = 1
        addChild(feld)

        let linie = CGMutablePath()
        linie.move(to: CGPoint(x: mitte, y: unten))
        linie.addLine(to: CGPoint(x: mitte, y: oben))
        let mittellinie = SKShapeNode(path: linie)
        mittellinie.strokeColor = UIColor.white.withAlphaComponent(0.35)
        mittellinie.lineWidth = 3
        mittellinie.zPosition = 2
        addChild(mittellinie)

        let kreis = SKShapeNode(circleOfRadius: 74)
        kreis.position = CGPoint(x: mitte, y: H.hoehe / 2)
        kreis.strokeColor = UIColor.white.withAlphaComponent(0.35)
        kreis.lineWidth = 3
        kreis.fillColor = .clear
        kreis.zPosition = 2
        addChild(kreis)

        for (x, farbe) in [(links, UIColor(Theme.himmel)), (rechts, UIColor(Theme.koralle))] {
            let pfad = CGMutablePath()
            pfad.move(to: CGPoint(x: x, y: torUnten))
            pfad.addLine(to: CGPoint(x: x, y: torOben))
            let tor = SKShapeNode(path: pfad)
            tor.strokeColor = farbe
            tor.lineWidth = 12
            tor.zPosition = 3
            addChild(tor)
        }
    }

    private func zeichneStand() {
        standLabel.text = "Du \(toreIch) : \(toreKi) Computer"
        levelLabel.text = "Level \(level)   Punkte \(punkte)"
    }

    /// Stellt Schläger und Puck für einen neuen Anstoß auf.
    private func stelleAuf() {
        meinSchlaeger.position = CGPoint(x: links + 150, y: H.hoehe / 2)
        kiSchlaeger.position = CGPoint(x: rechts - 150, y: H.hoehe / 2)
        ziel = meinSchlaeger.position
        letzteMeinePosition = meinSchlaeger.position
        meinV = .zero
        kiV = .zero
        puck.position = CGPoint(x: mitte, y: H.hoehe / 2)
        puckV = .zero
        puck.zRotation = 0
    }

    // MARK: Steuerung

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if vorbei {
            neuStarten()
        } else if !laeuft {
            laeuft = true
            infoLabel.text = ""
            untertitelLabel.text = ""
            anstossRichtung = 1
            anstossRest = 0.8
        }
        setzeZiel(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        setzeZiel(touches)
    }

    private func setzeZiel(_ touches: Set<UITouch>) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        ziel = CGPoint(x: min(max(p.x, links + trefferRadius), mitte - trefferRadius - 4),
                       y: min(max(p.y, unten + trefferRadius), oben - trefferRadius))
    }

    // MARK: Spielschleife

    override func update(_ currentTime: TimeInterval) {
        let dt: CGFloat = vorigeZeit == 0 ? 0 : min(CGFloat(currentTime - vorigeZeit), 1.0 / 30.0)
        vorigeZeit = currentTime
        guard laeuft, !vorbei, !pausiert, dt > 0 else { return }

        bewegeMeinen(dt)
        bewegeKi(dt)

        if anstossRest > 0 {
            anstossRest -= dt
            if anstossRest <= 0 { anstoss() }
            return
        }

        let teile = 3
        for _ in 0..<teile {
            schritt(dt / CGFloat(teile))
            if pausiert || vorbei { return }
        }
        puck.zRotation += (puckV.dx - puckV.dy) * dt * 0.01
    }

    private func bewegeMeinen(_ dt: CGFloat) {
        let alt = meinSchlaeger.position
        let dx = ziel.x - alt.x
        let dy = ziel.y - alt.y
        let d = hypot(dx, dy)
        let erlaubt: CGFloat = 1700 * dt
        var neu = alt
        if d > 0.5 {
            let s = min(d, erlaubt)
            neu = CGPoint(x: alt.x + dx / d * s, y: alt.y + dy / d * s)
        }
        meinSchlaeger.position = neu
        meinV = CGVector(dx: (neu.x - alt.x) / dt, dy: (neu.y - alt.y) / dt)
    }

    private func bewegeKi(_ dt: CGFloat) {
        kiNeuRest -= dt
        if kiNeuRest <= 0 {
            kiNeuRest = H.kiReaktion(level: level)
            let f = H.kiFehler(level: level)
            kiVersatz = CGPoint(x: CGFloat.random(in: -f...f), y: CGFloat.random(in: -f...f))
        }

        let p = puck.position
        let ki = kiSchlaeger.position
        let pr = H.puckRadius
        let sr = H.schlaegerRadius
        var wunsch: CGPoint

        if anstossRest > 0 {
            wunsch = CGPoint(x: rechts - 150, y: H.hoehe / 2)
        } else if p.x > ki.x - 5 && p.x > mitte {
            // Der Puck liegt hinter dem Schläger. Erst außen herum dahinter stellen.
            let seite: CGFloat = ki.y >= p.y ? 1 : -1
            wunsch = CGPoint(x: p.x + 70, y: p.y + seite * 80)
        } else if p.x > mitte - 20 {
            // Angreifen: hinter den Puck stellen und zum Tor des Spielers schieben.
            let dx = p.x - links
            let dy = p.y - H.hoehe / 2
            let d = max(hypot(dx, dy), 1)
            wunsch = CGPoint(x: p.x + dx / d * (pr + sr - 6), y: p.y + dy / d * (pr + sr - 6))
            wunsch.x += kiVersatz.x
            wunsch.y += kiVersatz.y
        } else {
            // Verteidigen: vor dem eigenen Tor auf Höhe des Pucks bleiben.
            wunsch = CGPoint(x: rechts - 110, y: min(max(p.y, torUnten), torOben))
            wunsch.y += kiVersatz.y
        }

        wunsch.x = min(max(wunsch.x, mitte + sr + 4), rechts - sr)
        wunsch.y = min(max(wunsch.y, unten + sr), oben - sr)

        let dx = wunsch.x - ki.x
        let dy = wunsch.y - ki.y
        let d = hypot(dx, dy)
        var neu = ki
        if d > 0.5 {
            let s = min(d, H.kiTempo(level: level) * dt)
            neu = CGPoint(x: ki.x + dx / d * s, y: ki.y + dy / d * s)
        }
        kiSchlaeger.position = neu
        kiV = CGVector(dx: (neu.x - ki.x) / dt, dy: (neu.y - ki.y) / dt)
    }

    private func schritt(_ d: CGFloat) {
        var p = puck.position
        p.x += puckV.dx * d
        p.y += puckV.dy * d
        let reibung = max(1 - 0.25 * d, 0)
        puckV.dx *= reibung
        puckV.dy *= reibung
        let r = H.puckRadius

        if p.y - r < unten {
            p.y = unten + r
            puckV.dy = abs(puckV.dy) * 0.92
        } else if p.y + r > oben {
            p.y = oben - r
            puckV.dy = -abs(puckV.dy) * 0.92
        }

        let imTor = p.y > torUnten + r * 0.3 && p.y < torOben - r * 0.3
        if p.x - r < links {
            if imTor {
                if p.x + r < links { puck.position = p; torErzielt(ich: false); return }
            } else {
                p.x = links + r
                puckV.dx = abs(puckV.dx) * 0.92
            }
        } else if p.x + r > rechts {
            if imTor {
                if p.x - r > rechts { puck.position = p; torErzielt(ich: true); return }
            } else {
                p.x = rechts - r
                puckV.dx = -abs(puckV.dx) * 0.92
            }
        }
        puck.position = p

        stoss(meinSchlaeger, meinV)
        stoss(kiSchlaeger, kiV)
        begrenze()
    }

    private func stoss(_ schlaeger: SKSpriteNode, _ v: CGVector) {
        let pr = H.puckRadius
        let sr = trefferRadius
        let dx = puck.position.x - schlaeger.position.x
        let dy = puck.position.y - schlaeger.position.y
        let d = hypot(dx, dy)
        guard d < pr + sr else { return }
        let nx = d > 0.001 ? dx / d : (schlaeger === meinSchlaeger ? 1 : -1)
        let ny = d > 0.001 ? dy / d : 0
        puck.position = CGPoint(x: schlaeger.position.x + nx * (pr + sr),
                                y: schlaeger.position.y + ny * (pr + sr))
        let rel = (puckV.dx - v.dx) * nx + (puckV.dy - v.dy) * ny
        if rel < 0 {
            puckV.dx -= 1.9 * rel * nx
            puckV.dy -= 1.9 * rel * ny
        }
        let tempo = hypot(puckV.dx, puckV.dy)
        if tempo < H.puckMinStoss {
            puckV = CGVector(dx: nx * H.puckMinStoss, dy: ny * H.puckMinStoss)
        }
    }

    private func begrenze() {
        let tempo = hypot(puckV.dx, puckV.dy)
        if tempo > H.puckMaxTempo {
            let f = H.puckMaxTempo / tempo
            puckV.dx *= f
            puckV.dy *= f
        }
    }

    // MARK: Tore und Spielstand

    private func anstoss() {
        let winkel = CGFloat.random(in: -0.5...0.5)
        puckV = CGVector(dx: cos(winkel) * 320 * anstossRichtung, dy: sin(winkel) * 320)
    }

    private func torErzielt(ich: Bool) {
        if ich { toreIch += 1 } else { toreKi += 1 }
        zeichneStand()
        SpielHilfe.funkel(in: self, ort: CGPoint(x: ich ? rechts - 60 : links + 60, y: H.hoehe / 2),
                          text: ich ? "Tor!" : "Aua")
        puckV = .zero

        if toreIch >= H.toreZumSieg {
            siegImLevel()
        } else if toreKi >= H.toreZumSieg {
            ende()
        } else {
            // Wer das Tor bekommen hat, bekommt den Puck.
            pausiert = true
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.9),
                SKAction.run { [weak self] in
                    guard let self, !self.vorbei else { return }
                    self.stelleAuf()
                    self.anstossRichtung = ich ? 1 : -1
                    self.anstossRest = 0.9
                    self.pausiert = false
                }
            ]))
        }
    }

    private func siegImLevel() {
        pausiert = true
        punkte += H.punkteFuerSieg(level: level, vorsprung: toreIch - toreKi)
        zeichneStand()
        infoLabel.text = "Level \(level) geschafft!"
        untertitelLabel.text = "Der Computer wird jetzt besser"
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                guard let self, !self.vorbei else { return }
                self.level += 1
                self.toreIch = 0
                self.toreKi = 0
                self.stelleAuf()
                self.zeichneStand()
                self.infoLabel.text = ""
                self.untertitelLabel.text = ""
                self.anstossRichtung = 1
                self.anstossRest = 0.9
                self.pausiert = false
            }
        ]))
    }

    private func ende() {
        vorbei = true
        laeuft = false
        pausiert = false
        infoLabel.text = "\(punkte) Punkte"
        untertitelLabel.text = "Level \(level). Tippen für noch einen Versuch"
        beiEnde?(punkte)
    }

    private func neuStarten() {
        removeAllActions()
        vorbei = false
        pausiert = false
        level = 1
        toreIch = 0
        toreKi = 0
        punkte = 0
        stelleAuf()
        zeichneStand()
        infoLabel.text = ""
        untertitelLabel.text = ""
        anstossRichtung = 1
        anstossRest = 0.8
        laeuft = true
    }
}

struct SpielHockeyView: View {
    var body: some View {
        SpielHuelle(schluessel: "hockey", szene: HockeySzene.neu())
    }
}
