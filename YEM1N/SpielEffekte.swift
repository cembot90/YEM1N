import SwiftUI
import SpriteKit
import UIKit

// ============================================================
// MARK: - Effekte für alle Spiele
// Sternenhimmel, Funken, Konfetti, Wackeln und Blitz. Alles wird im Code
// erzeugt, es braucht keine Bilddateien. Die Effekte entfernen sich selbst.
// ============================================================

enum SpielEffekte {

    // MARK: Texturen

    /// Weicher runder Punkt für Funken und Sterne.
    static let punktTextur: SKTexture = {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let bild = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32), format: format).image { ctx in
            let farben = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            if let verlauf = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: farben, locations: [0, 1]) {
                ctx.cgContext.drawRadialGradient(verlauf, startCenter: CGPoint(x: 16, y: 16), startRadius: 0,
                                                 endCenter: CGPoint(x: 16, y: 16), endRadius: 16, options: [])
            }
        }
        return SKTexture(image: bild)
    }()

    /// Kleines Rechteck für Konfetti.
    static let konfettiTextur: SKTexture = {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let bild = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 16), format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 16))
        }
        return SKTexture(image: bild)
    }()

    /// Senkrechter Farbverlauf als Hintergrundbild.
    static func verlauf(oben: UIColor, unten: UIColor, groesse: CGSize) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1
        let klein = CGSize(width: 8, height: 256)
        let bild = UIGraphicsImageRenderer(size: klein, format: format).image { ctx in
            let farben = [oben.cgColor, unten.cgColor] as CFArray
            if let v = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: farben, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(v, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: klein.height),
                                                 options: [])
            }
        }
        return SKTexture(image: bild)
    }

    // MARK: Hintergrund

    /// Legt einen Verlauf mit funkelnden Sternen hinter die Szene.
    static func sternenHimmel(in szene: SKScene, groesse: CGSize,
                              oben: UIColor = UIColor(Theme.glanz), unten: UIColor = UIColor(Theme.tiefNavy),
                              sterne: Int = 40) {
        let grund = SKSpriteNode(texture: verlauf(oben: oben.withAlphaComponent(1), unten: unten, groesse: groesse))
        grund.size = groesse
        grund.position = CGPoint(x: groesse.width / 2, y: groesse.height / 2)
        grund.zPosition = -50
        grund.name = "himmel"
        szene.addChild(grund)

        for _ in 0..<sterne {
            let stern = SKSpriteNode(texture: punktTextur)
            let g = CGFloat.random(in: 3...8)
            stern.size = CGSize(width: g, height: g)
            stern.position = CGPoint(x: CGFloat.random(in: 0...groesse.width),
                                     y: CGFloat.random(in: groesse.height * 0.35...groesse.height))
            stern.alpha = CGFloat.random(in: 0.25...0.9)
            stern.zPosition = -49
            stern.name = "himmel"
            szene.addChild(stern)
            let dauer = Double.random(in: 0.8...2.2)
            stern.run(.repeatForever(.sequence([.fadeAlpha(to: 0.15, duration: dauer),
                                                .fadeAlpha(to: 0.9, duration: dauer)])))
        }
    }

    // MARK: Funken und Konfetti

    /// Kurzer Funkenregen, zum Beispiel beim Einsammeln einer Münze.
    static func funken(in szene: SKScene, ort: CGPoint, farbe: UIColor = UIColor(Theme.gelb), anzahl: Int = 18) {
        let e = SKEmitterNode()
        e.particleTexture = punktTextur
        e.particleBirthRate = 600
        e.numParticlesToEmit = anzahl
        e.particleLifetime = 0.55
        e.particleLifetimeRange = 0.2
        e.emissionAngleRange = .pi * 2
        e.particleSpeed = 220
        e.particleSpeedRange = 120
        e.particleAlphaSpeed = -1.6
        e.particleScale = 0.55
        e.particleScaleRange = 0.3
        e.particleScaleSpeed = -0.6
        e.particleColor = farbe
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .add
        e.position = ort
        e.zPosition = 40
        szene.addChild(e)
        e.run(.sequence([.wait(forDuration: 1.0), .removeFromParent()]))
    }

    /// Bunter Konfettiregen für Tore, Rekorde und geschaffte Level.
    static func konfetti(in szene: SKScene, ort: CGPoint, anzahl: Int = 90) {
        let farben: [UIColor] = [UIColor(Theme.gelb), UIColor(Theme.koralle), UIColor(Theme.mint),
                                 UIColor(Theme.himmel), UIColor(red: 1.0, green: 0.55, blue: 0.85, alpha: 1)]
        for (i, farbe) in farben.enumerated() {
            let e = SKEmitterNode()
            e.particleTexture = konfettiTextur
            e.particleBirthRate = 900
            e.numParticlesToEmit = anzahl / farben.count
            e.particleLifetime = 1.8
            e.particleLifetimeRange = 0.6
            e.emissionAngle = .pi / 2
            e.emissionAngleRange = .pi * 0.9
            e.particleSpeed = 420
            e.particleSpeedRange = 200
            e.yAcceleration = -620
            e.particleRotationRange = .pi * 2
            e.particleRotationSpeed = CGFloat(i % 2 == 0 ? 6 : -6)
            e.particleAlphaSpeed = -0.45
            e.particleScale = 0.9
            e.particleScaleRange = 0.4
            e.particleColor = farbe
            e.particleColorBlendFactor = 1
            e.position = ort
            e.zPosition = 45
            szene.addChild(e)
            e.run(.sequence([.wait(forDuration: 3.0), .removeFromParent()]))
        }
    }

    // MARK: Treffer

    /// Kurzer farbiger Blitz über die ganze Szene.
    static func blitz(in szene: SKScene, farbe: UIColor = UIColor(Theme.koralle)) {
        let decke = SKSpriteNode(color: farbe, size: CGSize(width: szene.size.width * 3, height: szene.size.height * 3))
        decke.position = CGPoint(x: szene.size.width / 2, y: szene.size.height / 2)
        decke.alpha = 0.35
        decke.zPosition = 60
        szene.addChild(decke)
        decke.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
    }

    /// Richtet eine Kamera in der Mitte ein, damit die Szene wackeln kann.
    /// Nur für Szenen mit fester Größe (scaleMode aspectFit).
    static func kamera(in szene: SKScene) {
        guard szene.camera == nil else { return }
        let k = SKCameraNode()
        k.position = CGPoint(x: szene.size.width / 2, y: szene.size.height / 2)
        szene.addChild(k)
        szene.camera = k
    }

    /// Lässt die Szene kurz wackeln. Ohne Kamera passiert nichts.
    static func wackeln(in szene: SKScene, staerke: CGFloat = 10) {
        guard let k = szene.camera else { return }
        k.removeAction(forKey: "wackeln")
        let mitte = CGPoint(x: szene.size.width / 2, y: szene.size.height / 2)
        var schritte: [SKAction] = []
        for i in 0..<6 {
            let s = staerke * CGFloat(6 - i) / 6
            schritte.append(.move(to: CGPoint(x: mitte.x + CGFloat.random(in: -s...s),
                                              y: mitte.y + CGFloat.random(in: -s...s)), duration: 0.04))
        }
        schritte.append(.move(to: mitte, duration: 0.05))
        k.run(.sequence(schritte), withKey: "wackeln")
    }

    /// Große Zahl oder großes Wort, das kurz aufspringt und verschwindet.
    static func aufspringen(in szene: SKScene, ort: CGPoint, text: String,
                            farbe: UIColor = UIColor(Theme.gelb), groesse: CGFloat = 44) {
        let l = SKLabelNode(text: text)
        l.fontName = "AvenirNext-Heavy"
        l.fontSize = groesse
        l.fontColor = farbe
        l.verticalAlignmentMode = .center
        l.position = ort
        l.zPosition = 50
        l.setScale(0.2)
        szene.addChild(l)
        let auf = SKAction.scale(to: 1.15, duration: 0.18)
        auf.timingMode = .easeOut
        l.run(.sequence([auf, .scale(to: 1.0, duration: 0.1), .wait(forDuration: 0.5),
                         .group([.moveBy(x: 0, y: 40, duration: 0.4), .fadeOut(withDuration: 0.4)]),
                         .removeFromParent()]))
    }
}
