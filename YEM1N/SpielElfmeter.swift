import SwiftUI
import SpriteKit

// ============================================================
// MARK: - Elfmeterschießen
// Vom Ball zum Tor wischen. Der Torwart wird mit jedem Level schneller.
// Schüsse in den Winkel bringen 3 Punkte. Nach drei Fehlschüssen ist Schluss.
// ============================================================

final class ElfmeterSzene: SKScene, SpielSzene {

    var beiEnde: ((Int) -> Void)?

    private typealias R = ElfmeterRegeln

    static func neu() -> ElfmeterSzene {
        let szene = ElfmeterSzene(size: CGSize(width: R.breite, height: R.hoehe))
        szene.scaleMode = .aspectFit
        return szene
    }

    // MARK: Knoten

    private let ball = SKLabelNode(text: "⚽")
    private let torwart = SKNode()
    private let netz = SKNode()
    private let zielLinie = SKShapeNode()
    private let punkteLabel = SKLabelNode(text: "")
    private let levelLabel = SKLabelNode(text: "")
    private let serieLabel = SKLabelNode(text: "")
    private let infoLabel = SKLabelNode(text: "Elfmeterschießen")
    private let untertitelLabel = SKLabelNode(text: "Wische vom Ball zum Tor")
    private var fehlBaelle: [SKLabelNode] = []

    // MARK: Zustand

    private var punkte = 0
    private var tore = 0
    private var serie = 0
    private var fehlschuesse = 0
    private var level = 1
    private var bereit = false
    private var laeuft = false
    private var vorbei = false
    private var wischStart: CGPoint?
    private var wischZeit: TimeInterval = 0

    private let torwartY: CGFloat = R.torUnten + 64

    // MARK: Aufbau

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(Theme.tiefNavy)
        SpielEffekte.sternenHimmel(in: self, groesse: size, sterne: 30)
        SpielEffekte.kamera(in: self)
        zeichneStadion()
        zeichneTor()
        baueTorwart()

        ball.fontSize = 64
        ball.verticalAlignmentMode = .center
        ball.zPosition = 20
        addChild(ball)

        zielLinie.strokeColor = UIColor.white.withAlphaComponent(0.7)
        zielLinie.lineWidth = 4
        zielLinie.lineCap = .round
        zielLinie.zPosition = 15
        addChild(zielLinie)

        SpielHilfe.beschrifte(punkteLabel, groesse: 30, farbe: UIColor(Theme.gelb), fett: true)
        punkteLabel.horizontalAlignmentMode = .left
        punkteLabel.position = CGPoint(x: 28, y: R.hoehe - 46)
        addChild(punkteLabel)

        SpielHilfe.beschrifte(levelLabel, groesse: 18, farbe: .white, fett: true)
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.position = CGPoint(x: 30, y: R.hoehe - 76)
        addChild(levelLabel)

        SpielHilfe.beschrifte(serieLabel, groesse: 22, farbe: UIColor(Theme.koralle), fett: true)
        serieLabel.position = CGPoint(x: R.breite / 2, y: R.hoehe - 50)
        addChild(serieLabel)

        for i in 0..<R.fehlschuesseErlaubt {
            let b = SKLabelNode(text: "⚽")
            b.fontSize = 26
            b.verticalAlignmentMode = .center
            b.position = CGPoint(x: 46 + CGFloat(i) * 34, y: R.hoehe - 106)
            b.zPosition = 30
            addChild(b)
            fehlBaelle.append(b)
        }

        SpielHilfe.beschrifte(infoLabel, groesse: 40, farbe: .white, fett: true)
        infoLabel.verticalAlignmentMode = .center
        infoLabel.position = CGPoint(x: R.breite / 2, y: 228)
        addChild(infoLabel)

        SpielHilfe.beschrifte(untertitelLabel, groesse: 19, farbe: UIColor(Theme.gelb), fett: false)
        untertitelLabel.verticalAlignmentMode = .center
        untertitelLabel.position = CGPoint(x: R.breite / 2, y: 190)
        addChild(untertitelLabel)

        legeBallHin()
        zeichneStand()
        torwart.run(.repeatForever(torwartWippen()), withKey: "wippen")
    }

    private func zeichneStadion() {
        // Rasen mit hellen und dunklen Streifen
        let rasenHoehe: CGFloat = R.torUnten + 8
        let streifen = 8
        for i in 0..<streifen {
            let h = rasenHoehe / CGFloat(streifen)
            let s = SKSpriteNode(color: i % 2 == 0 ? UIColor(red: 0.16, green: 0.62, blue: 0.30, alpha: 1)
                                                   : UIColor(red: 0.13, green: 0.55, blue: 0.27, alpha: 1),
                                 size: CGSize(width: R.breite, height: h))
            s.anchorPoint = CGPoint(x: 0, y: 0)
            s.position = CGPoint(x: 0, y: CGFloat(i) * h)
            s.zPosition = -10
            addChild(s)
        }
        // Strafraumlinien
        let linie = CGMutablePath()
        linie.move(to: CGPoint(x: 150, y: R.torUnten))
        linie.addLine(to: CGPoint(x: 70, y: 40))
        linie.move(to: CGPoint(x: R.breite - 150, y: R.torUnten))
        linie.addLine(to: CGPoint(x: R.breite - 70, y: 40))
        linie.move(to: CGPoint(x: 0, y: R.torUnten))
        linie.addLine(to: CGPoint(x: R.breite, y: R.torUnten))
        let striche = SKShapeNode(path: linie)
        striche.strokeColor = UIColor.white.withAlphaComponent(0.55)
        striche.lineWidth = 4
        striche.zPosition = -9
        addChild(striche)
        // Elfmeterpunkt
        let punkt = SKShapeNode(ellipseOf: CGSize(width: 22, height: 10))
        punkt.fillColor = .white
        punkt.strokeColor = .clear
        punkt.position = CGPoint(x: R.ballStart.x, y: R.ballStart.y - 30)
        punkt.zPosition = -8
        addChild(punkt)
        // Flutlicht
        for x in [CGFloat(120), R.breite - 120] {
            let licht = SKSpriteNode(texture: SpielEffekte.punktTextur)
            licht.size = CGSize(width: 260, height: 260)
            licht.position = CGPoint(x: x, y: R.hoehe - 40)
            licht.alpha = 0.35
            licht.zPosition = -40
            licht.blendMode = .add
            addChild(licht)
        }
    }

    private func zeichneTor() {
        netz.zPosition = 2
        addChild(netz)
        let gitter = CGMutablePath()
        var x = R.torLinks
        while x <= R.torRechts {
            gitter.move(to: CGPoint(x: x, y: R.torUnten))
            gitter.addLine(to: CGPoint(x: x, y: R.torOben))
            x += 26
        }
        var y = R.torUnten
        while y <= R.torOben {
            gitter.move(to: CGPoint(x: R.torLinks, y: y))
            gitter.addLine(to: CGPoint(x: R.torRechts, y: y))
            y += 22
        }
        let maschen = SKShapeNode(path: gitter)
        maschen.strokeColor = UIColor.white.withAlphaComponent(0.25)
        maschen.lineWidth = 1.5
        netz.addChild(maschen)

        let rahmen = CGMutablePath()
        rahmen.move(to: CGPoint(x: R.torLinks, y: R.torUnten))
        rahmen.addLine(to: CGPoint(x: R.torLinks, y: R.torOben))
        rahmen.addLine(to: CGPoint(x: R.torRechts, y: R.torOben))
        rahmen.addLine(to: CGPoint(x: R.torRechts, y: R.torUnten))
        let pfosten = SKShapeNode(path: rahmen)
        pfosten.strokeColor = .white
        pfosten.lineWidth = 12
        pfosten.lineJoin = .round
        pfosten.zPosition = 4
        addChild(pfosten)
    }

    private func baueTorwart() {
        torwart.position = CGPoint(x: R.torMitte, y: torwartY)
        torwart.zPosition = 10
        addChild(torwart)

        let schatten = SKShapeNode(ellipseOf: CGSize(width: 90, height: 16))
        schatten.fillColor = UIColor.black.withAlphaComponent(0.25)
        schatten.strokeColor = .clear
        schatten.position = CGPoint(x: 0, y: -66)
        torwart.addChild(schatten)

        let koerper = SKShapeNode(rectOf: CGSize(width: 58, height: 92), cornerRadius: 24)
        koerper.fillColor = UIColor(Theme.koralle)
        koerper.strokeColor = UIColor.white.withAlphaComponent(0.6)
        koerper.lineWidth = 3
        koerper.position = CGPoint(x: 0, y: -10)
        torwart.addChild(koerper)

        let nummer = SKLabelNode(text: "1")
        nummer.fontName = "AvenirNext-Heavy"
        nummer.fontSize = 30
        nummer.fontColor = .white
        nummer.verticalAlignmentMode = .center
        nummer.position = CGPoint(x: 0, y: -8)
        torwart.addChild(nummer)

        let kopf = SKShapeNode(circleOfRadius: 24)
        kopf.fillColor = UIColor(red: 1.0, green: 0.84, blue: 0.68, alpha: 1)
        kopf.strokeColor = .clear
        kopf.position = CGPoint(x: 0, y: 56)
        torwart.addChild(kopf)
        for dx in [CGFloat(-8), 8] {
            let auge = SKShapeNode(circleOfRadius: 3.5)
            auge.fillColor = .black
            auge.strokeColor = .clear
            auge.position = CGPoint(x: dx, y: 60)
            torwart.addChild(auge)
        }
        for dx in [CGFloat(-48), 48] {
            let hand = SKLabelNode(text: "🧤")
            hand.fontSize = 36
            hand.verticalAlignmentMode = .center
            hand.position = CGPoint(x: dx, y: 24)
            if dx > 0 { hand.xScale = -1 }
            torwart.addChild(hand)
        }
    }

    private func torwartWippen() -> SKAction {
        let links = SKAction.moveBy(x: -36, y: 0, duration: 0.7)
        links.timingMode = .easeInEaseOut
        let rechts = SKAction.moveBy(x: 36, y: 0, duration: 0.7)
        rechts.timingMode = .easeInEaseOut
        return .sequence([links, rechts, rechts, links])
    }

    private func legeBallHin() {
        ball.removeAllActions()
        ball.position = R.ballStart
        ball.setScale(1)
        ball.zRotation = 0
        ball.alpha = 1
        zielLinie.path = nil
    }

    private func zeichneStand() {
        punkteLabel.text = "⭐ \(punkte)"
        levelLabel.text = "Level \(level)"
        serieLabel.text = serie >= 2 ? "🔥 \(serie) in Folge" : ""
        for (i, b) in fehlBaelle.enumerated() {
            b.alpha = i < R.fehlschuesseErlaubt - fehlschuesse ? 1 : 0.2
        }
    }

    // MARK: Steuerung

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        if vorbei {
            neuStarten()
            return
        }
        if !laeuft {
            laeuft = true
            bereit = true
            infoLabel.text = ""
            untertitelLabel.text = ""
        }
        guard bereit else { return }
        let p = t.location(in: self)
        // Der Wisch muss in der unteren Hälfte beginnen, nah am Ball
        guard p.y < R.torUnten - 20 else { return }
        wischStart = p
        wischZeit = t.timestamp
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard bereit, let start = wischStart, let t = touches.first else { return }
        let p = t.location(in: self)
        let pfad = CGMutablePath()
        pfad.move(to: R.ballStart)
        let ziel = R.ziel(wisch: CGVector(dx: p.x - start.x, dy: p.y - start.y))
        pfad.addLine(to: ziel)
        zielLinie.path = pfad.copy(dashingWithPhase: 0, lengths: [14, 12])
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard bereit, let start = wischStart, let t = touches.first else { return }
        wischStart = nil
        zielLinie.path = nil
        let p = t.location(in: self)
        let wisch = CGVector(dx: p.x - start.x, dy: p.y - start.y)
        guard hypot(wisch.dx, wisch.dy) > 50, wisch.dy > 30 else { return }
        let dauer = max(t.timestamp - wischZeit, 0.05)
        let tempo = hypot(wisch.dx, wisch.dy) / CGFloat(dauer)
        schiesse(ziel: R.ziel(wisch: wisch), flugzeit: R.flugzeit(wischTempo: tempo))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        wischStart = nil
        zielLinie.path = nil
    }

    // MARK: Schuss

    private func schiesse(ziel: CGPoint, flugzeit: Double) {
        bereit = false
        torwart.removeAction(forKey: "wippen")
        let (ergebnis, torwartZiel) = R.ergebnis(ziel: ziel, torwartX: torwart.position.x,
                                                  flugzeit: flugzeit, level: level,
                                                  zufall: Double.random(in: 0...1))

        // Torwart springt
        let sprungY = torwartY + min(max(ziel.y - R.torUnten - 40, 0), 120)
        let richtung: CGFloat = torwartZiel < torwart.position.x ? 1 : -1
        let weit = abs(torwartZiel - torwart.position.x) > 90
        let sprung = SKAction.group([
            .move(to: CGPoint(x: torwartZiel, y: sprungY), duration: flugzeit * 0.9),
            .rotate(toAngle: weit ? 0.7 * richtung : 0, duration: flugzeit * 0.6)
        ])
        sprung.timingMode = .easeOut
        torwart.run(.sequence([.wait(forDuration: R.reaktion(level: level)), sprung]))

        // Ball fliegt
        let flug = SKAction.group([
            .move(to: ziel, duration: flugzeit),
            .scale(to: 0.55, duration: flugzeit),
            .rotate(byAngle: -.pi * 4, duration: flugzeit)
        ])
        flug.timingMode = .easeOut
        ball.run(.sequence([flug, .run { [weak self] in self?.landet(ergebnis, ziel: ziel) }]))
        Haptik.leicht()
    }

    private func landet(_ ergebnis: R.Ergebnis, ziel: CGPoint) {
        switch ergebnis {
        case .tor(let winkel):
            tore += 1
            serie += 1
            let neu = R.punkte(winkel: winkel, serie: serie)
            punkte += neu
            ball.run(.moveBy(x: 0, y: 14, duration: 0.15))
            netz.run(.sequence([.scaleY(to: 1.04, duration: 0.08), .scaleY(to: 1.0, duration: 0.2)]))
            SpielEffekte.konfetti(in: self, ort: ziel)
            SpielEffekte.aufspringen(in: self, ort: CGPoint(x: R.breite / 2, y: 228),
                                     text: winkel ? "WINKEL! +\(neu)" : "TOR! +\(neu)")
            SpielEffekte.wackeln(in: self, staerke: winkel ? 12 : 7)
            Haptik.erfolg()
            let neuesLevel = R.level(tore: tore)
            if neuesLevel > level {
                level = neuesLevel
                run(.sequence([.wait(forDuration: 0.9), .run { [weak self] in
                    guard let self else { return }
                    SpielEffekte.aufspringen(in: self, ort: CGPoint(x: R.breite / 2, y: 180),
                                             text: "Level \(self.level)", farbe: .white, groesse: 36)
                }]))
            }
        case .gehalten:
            serie = 0
            fehlschuesse += 1
            let weg: CGFloat = ziel.x < R.torMitte ? -170 : 170
            ball.run(.group([.moveBy(x: weg, y: -150, duration: 0.45), .fadeOut(withDuration: 0.45)]))
            SpielEffekte.aufspringen(in: self, ort: CGPoint(x: R.breite / 2, y: 228), text: "Gehalten!",
                                     farbe: UIColor(Theme.koralle), groesse: 40)
            SpielEffekte.blitz(in: self)
            Haptik.fehler()
        case .daneben:
            serie = 0
            fehlschuesse += 1
            ball.run(.group([.moveBy(x: (ziel.x - R.ballStart.x) * 0.3, y: 80, duration: 0.4),
                             .fadeOut(withDuration: 0.4)]))
            SpielEffekte.aufspringen(in: self, ort: CGPoint(x: R.breite / 2, y: 228), text: "Daneben",
                                     farbe: UIColor(Theme.himmel), groesse: 40)
            Haptik.fehler()
        }
        zeichneStand()

        run(.sequence([.wait(forDuration: 1.3), .run { [weak self] in self?.naechsterSchuss() }]))
    }

    private func naechsterSchuss() {
        guard !vorbei else { return }
        if fehlschuesse >= R.fehlschuesseErlaubt {
            ende()
            return
        }
        legeBallHin()
        torwart.removeAllActions()
        torwart.zRotation = 0
        torwart.run(.move(to: CGPoint(x: R.torMitte, y: torwartY), duration: 0.3))
        torwart.run(.sequence([.wait(forDuration: 0.3), .repeatForever(torwartWippen())]), withKey: "wippen")
        bereit = true
    }

    private func ende() {
        vorbei = true
        laeuft = false
        bereit = false
        infoLabel.text = "\(punkte) Punkte"
        untertitelLabel.text = "\(tore) Tore. Tippen für noch einen Versuch"
        SpielEffekte.konfetti(in: self, ort: CGPoint(x: R.breite / 2, y: 240))
        beiEnde?(punkte)
    }

    private func neuStarten() {
        removeAllActions()
        vorbei = false
        punkte = 0
        tore = 0
        serie = 0
        fehlschuesse = 0
        level = 1
        infoLabel.text = ""
        untertitelLabel.text = ""
        legeBallHin()
        torwart.removeAllActions()
        torwart.zRotation = 0
        torwart.position = CGPoint(x: R.torMitte, y: torwartY)
        torwart.run(.repeatForever(torwartWippen()), withKey: "wippen")
        zeichneStand()
        laeuft = true
        bereit = true
    }
}

struct SpielElfmeterView: View {
    var body: some View {
        SpielHuelle(schluessel: "elfmeter", szene: ElfmeterSzene.neu())
    }
}
