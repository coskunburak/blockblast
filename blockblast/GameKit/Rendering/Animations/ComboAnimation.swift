import SpriteKit

enum ComboAnimation {
    static func play(
        on scene: SKScene,
        at origin: CGPoint,
        linesCleared: Int,
        comboChain: Int,
        multiplier: Int
    ) {
        let tier = comboTier(linesCleared: linesCleared, comboChain: comboChain, multiplier: multiplier)
        let praise = tier.phrase
        let primary = tier.primary
        let accent = tier.accent
        let hasHotCombo = comboChain >= 2 || multiplier >= 2

        let container = SKNode()
        container.position = origin
        container.zPosition = 8_000
        container.alpha = 0
        container.setScale(0.82)
        scene.addChild(container)

        let glow = SKShapeNode(circleOfRadius: 62 + CGFloat(tier.level * 8))
        glow.fillColor = accent.withAlphaComponent(0.25)
        glow.strokeColor = .clear
        glow.glowWidth = 28
        glow.alpha = 0.90
        container.addChild(glow)

        let auraRing = SKShapeNode(circleOfRadius: 54 + CGFloat(tier.level * 7))
        auraRing.strokeColor = mixed(accent, with: .white, amount: 0.26).withAlphaComponent(0.82)
        auraRing.fillColor = .clear
        auraRing.lineWidth = 2.0
        auraRing.glowWidth = 12
        auraRing.alpha = 0.84
        container.addChild(auraRing)

        let primaryShadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        primaryShadow.text = hasHotCombo ? "COMBO \(comboChain)" : clearLabel(for: linesCleared)
        primaryShadow.fontSize = hasHotCombo ? CGFloat(44 + min(10, tier.level * 2)) : 34
        primaryShadow.fontColor = .black.withAlphaComponent(0.42)
        primaryShadow.position = CGPoint(x: 0, y: -4)
        primaryShadow.zPosition = 2
        container.addChild(primaryShadow)

        let primaryTitle = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        primaryTitle.text = hasHotCombo ? "COMBO \(comboChain)" : clearLabel(for: linesCleared)
        primaryTitle.fontSize = hasHotCombo ? CGFloat(44 + min(10, tier.level * 2)) : 34
        primaryTitle.fontColor = primary
        primaryTitle.position = CGPoint(x: 0, y: 0)
        primaryTitle.zPosition = 3
        container.addChild(primaryTitle)

        let shadowTitle = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        shadowTitle.text = praise.uppercased()
        shadowTitle.fontSize = hasHotCombo ? 24 : 18
        shadowTitle.fontColor = .black.withAlphaComponent(0.42)
        shadowTitle.position = CGPoint(x: 0, y: hasHotCombo ? 42 : 28)
        shadowTitle.zPosition = 2
        container.addChild(shadowTitle)

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = praise.uppercased()
        title.fontSize = hasHotCombo ? 24 : 18
        title.fontColor = primary
        title.position = CGPoint(x: 0, y: hasHotCombo ? 46 : 32)
        title.zPosition = 3
        container.addChild(title)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        subtitle.text = hasHotCombo ? "x\(max(2, multiplier)) CHAIN BONUS" : "+\(max(1, linesCleared)) LINE"
        subtitle.fontSize = hasHotCombo ? 18 : 15
        subtitle.fontColor = SKColor(white: 1.0, alpha: 0.92)
        subtitle.position = CGPoint(x: 0, y: -(hasHotCombo ? 44 : 26))
        subtitle.zPosition = 3
        container.addChild(subtitle)

        if hasHotCombo {
            let comboCountShadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            comboCountShadow.text = "x\(max(2, multiplier))"
            comboCountShadow.fontSize = 54
            comboCountShadow.fontColor = .black.withAlphaComponent(0.46)
            comboCountShadow.position = CGPoint(x: 128, y: -8)
            comboCountShadow.zPosition = 4
            container.addChild(comboCountShadow)

            let comboCount = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            comboCount.text = "x\(max(2, multiplier))"
            comboCount.fontSize = 54
            comboCount.fontColor = SKColor(red: 1.0, green: 0.86, blue: 0.30, alpha: 1.0)
            comboCount.position = CGPoint(x: 124, y: -4)
            comboCount.zPosition = 5
            container.addChild(comboCount)
        }

        emitSparkles(in: container, color: accent, count: 9 + tier.level * 4)
        emitMist(in: container, color: mixed(accent, with: .white, amount: 0.32), count: 5 + tier.level)

        let swayDistance = hasHotCombo ? CGFloat(2 + tier.level) : 2.0
        let sway = SKAction.sequence([
            SKAction.moveBy(x: -swayDistance, y: 1.0, duration: 0.07),
            SKAction.moveBy(x: swayDistance * 2, y: -2.0, duration: 0.12),
            SKAction.moveBy(x: -swayDistance, y: 1.0, duration: 0.07)
        ])
        sway.timingMode = .easeInEaseOut

        let showDuration = max(0.10, 0.16 - (Double(tier.level) * 0.004))
        let settleDuration = 0.16 + (Double(tier.level) * 0.012)
        let holdDuration = 0.34 + (Double(tier.level) * 0.07)
        let hideDuration = 0.30 + (Double(tier.level) * 0.024)
        let peakScale = min(1.18, 1.05 + (CGFloat(tier.level) * 0.025))

        let show = SKAction.group([
            SKAction.fadeIn(withDuration: showDuration),
            SKAction.scale(to: peakScale, duration: showDuration + 0.03)
        ])
        show.timingMode = .easeOut

        let settle = SKAction.scale(to: 1.0, duration: settleDuration)
        settle.timingMode = .easeOut

        let hide = SKAction.group([
            SKAction.fadeOut(withDuration: hideDuration),
            SKAction.moveBy(x: 0, y: 20 + CGFloat(tier.level * 2), duration: hideDuration),
            SKAction.scale(to: 1.05, duration: hideDuration)
        ])
        hide.timingMode = .easeIn

        let breathe = SKAction.repeatForever(
            .sequence([
                .scale(to: 1.03, duration: 0.34),
                .scale(to: 1.0, duration: 0.34)
            ])
        )
        breathe.timingMode = .easeInEaseOut
        glow.run(breathe, withKey: "combo_glow_breathe")
        auraRing.run(
            .repeatForever(
                .sequence([
                    .fadeAlpha(to: 0.56, duration: 0.28),
                    .fadeAlpha(to: 0.86, duration: 0.30)
                ])
            ),
            withKey: "combo_ring_pulse"
        )

        let drift = SKAction.repeatForever(
            .sequence([
                .moveBy(x: 0, y: 2, duration: 0.34),
                .moveBy(x: 0, y: -2, duration: 0.34)
            ])
        )
        drift.timingMode = .easeInEaseOut
        container.run(drift, withKey: "combo_container_drift")

        scene.run(sway)
        container.run(.sequence([show, settle, SKAction.wait(forDuration: holdDuration), hide])) {
            container.removeFromParent()
        }
    }

    private static func clearLabel(for linesCleared: Int) -> String {
        switch linesCleared {
        case 3...:
            return "TRIPLE CLEAR"
        case 2:
            return "DOUBLE CLEAR"
        default:
            return "CLEAR"
        }
    }

    private static func emitSparkles(in container: SKNode, color: SKColor, count: Int) {
        for _ in 0..<count {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.0...3.8))
            sparkle.fillColor = color.withAlphaComponent(0.85)
            sparkle.strokeColor = .clear
            sparkle.glowWidth = 8
            sparkle.position = CGPoint(
                x: CGFloat.random(in: -120...120),
                y: CGFloat.random(in: -58...64)
            )
            sparkle.alpha = 0
            sparkle.zPosition = 1
            container.addChild(sparkle)

            let delay = SKAction.wait(forDuration: TimeInterval(CGFloat.random(in: 0.00...0.10)))
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.08)
            let drift = SKAction.moveBy(
                x: CGFloat.random(in: -10...10),
                y: CGFloat.random(in: 14...28),
                duration: 0.34
            )
            drift.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.30)
            fadeOut.timingMode = .easeIn
            let shrink = SKAction.scale(to: 0.16, duration: 0.30)
            shrink.timingMode = .easeIn

            sparkle.run(.sequence([delay, fadeIn, .group([drift, fadeOut, shrink])])) {
                sparkle.removeFromParent()
            }
        }
    }

    private static func emitMist(in container: SKNode, color: SKColor, count: Int) {
        for _ in 0..<count {
            let mist = SKShapeNode(circleOfRadius: CGFloat.random(in: 8.0...16.0))
            mist.fillColor = color.withAlphaComponent(0.22)
            mist.strokeColor = .clear
            mist.glowWidth = 12
            mist.position = CGPoint(
                x: CGFloat.random(in: -82...82),
                y: CGFloat.random(in: -42...46)
            )
            mist.alpha = 0
            mist.zPosition = 0
            container.addChild(mist)

            let delay = SKAction.wait(forDuration: TimeInterval(CGFloat.random(in: 0.00...0.08)))
            let fadeIn = SKAction.fadeAlpha(to: 0.60, duration: 0.14)
            let travel = SKAction.moveBy(
                x: CGFloat.random(in: -7...7),
                y: CGFloat.random(in: 14...24),
                duration: 0.42
            )
            travel.timingMode = .easeInEaseOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.36)
            fadeOut.timingMode = .easeIn
            let scale = SKAction.scale(to: CGFloat.random(in: 0.76...1.22), duration: 0.42)
            scale.timingMode = .easeInEaseOut
            mist.run(.sequence([delay, fadeIn, .group([travel, fadeOut, scale])])) {
                mist.removeFromParent()
            }
        }
    }

    private static func comboTier(linesCleared: Int, comboChain: Int, multiplier: Int) -> ComboTier {
        let score = max(comboChain, multiplier + max(0, linesCleared - 1))

        switch score {
        case 8...:
            return ComboTier(
                level: 6,
                phrase: "Legendary",
                primary: SKColor(red: 1.0, green: 0.93, blue: 0.45, alpha: 1.0),
                accent: SKColor(red: 0.98, green: 0.61, blue: 0.17, alpha: 1.0)
            )
        case 6...7:
            return ComboTier(
                level: 5,
                phrase: "Unbelievable",
                primary: SKColor(red: 1.0, green: 0.91, blue: 0.42, alpha: 1.0),
                accent: SKColor(red: 0.98, green: 0.55, blue: 0.22, alpha: 1.0)
            )
        case 5:
            return ComboTier(
                level: 4,
                phrase: "Perfect",
                primary: SKColor(red: 1.0, green: 0.86, blue: 0.36, alpha: 1.0),
                accent: SKColor(red: 0.95, green: 0.36, blue: 0.43, alpha: 1.0)
            )
        case 4:
            return ComboTier(
                level: 3,
                phrase: "Amazing",
                primary: SKColor(red: 0.84, green: 0.91, blue: 1.0, alpha: 1.0),
                accent: SKColor(red: 0.46, green: 0.47, blue: 1.0, alpha: 1.0)
            )
        case 3:
            return ComboTier(
                level: 2,
                phrase: "Excellent",
                primary: SKColor(red: 0.80, green: 0.89, blue: 1.0, alpha: 1.0),
                accent: SKColor(red: 0.36, green: 0.64, blue: 1.0, alpha: 1.0)
            )
        case 2:
            return ComboTier(
                level: 1,
                phrase: "Great",
                primary: SKColor(red: 0.72, green: 0.86, blue: 1.0, alpha: 1.0),
                accent: SKColor(red: 0.31, green: 0.58, blue: 0.98, alpha: 1.0)
            )
        default:
            return ComboTier(
                level: 0,
                phrase: linesCleared >= 2 ? "Nice" : "Good",
                primary: SKColor(white: 1.0, alpha: 1.0),
                accent: SKColor(red: 0.58, green: 0.77, blue: 0.98, alpha: 1.0)
            )
        }
    }

    private static func mixed(_ lhs: SKColor, with rhs: SKColor, amount: CGFloat) -> SKColor {
        let t = max(0, min(1, amount))
        let l = rgbaComponents(for: lhs)
        let r = rgbaComponents(for: rhs)
        return SKColor(
            red: l.red + ((r.red - l.red) * t),
            green: l.green + ((r.green - l.green) * t),
            blue: l.blue + ((r.blue - l.blue) * t),
            alpha: l.alpha + ((r.alpha - l.alpha) * t)
        )
    }

    private static func rgbaComponents(for color: SKColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}

enum ScorePopupAnimation {
    static func play(on scene: SKScene, delta: Int, at origin: CGPoint) {
        guard delta > 0 else { return }

        let style = popupStyle(for: delta)
        let container = SKNode()
        container.position = origin
        container.zPosition = 7_850
        container.alpha = 0
        container.setScale(0.86)
        scene.addChild(container)

        let text = "+\(delta)"

        let shadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        shadow.text = text
        shadow.fontSize = style.fontSize
        shadow.fontColor = .black.withAlphaComponent(0.45)
        shadow.position = CGPoint(x: 2, y: -3)
        shadow.zPosition = 1
        container.addChild(shadow)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = style.fontSize
        label.fontColor = style.primary
        label.zPosition = 2
        container.addChild(label)

        let glow = SKShapeNode(circleOfRadius: style.fontSize * 0.95)
        glow.fillColor = style.accent.withAlphaComponent(0.21)
        glow.strokeColor = .clear
        glow.glowWidth = 14
        glow.alpha = 0.85
        glow.zPosition = 0
        container.addChild(glow)

        let show = SKAction.group([
            SKAction.fadeIn(withDuration: 0.11),
            SKAction.scale(to: style.peakScale, duration: 0.14)
        ])
        show.timingMode = .easeOut

        let settle = SKAction.scale(to: 1.0, duration: 0.15)
        settle.timingMode = .easeInEaseOut

        let rise = SKAction.moveBy(x: 0, y: style.riseDistance, duration: 0.40)
        rise.timingMode = .easeInEaseOut
        let fade = SKAction.fadeOut(withDuration: 0.40)
        fade.timingMode = .easeIn
        let vanish = SKAction.group([rise, fade])

        container.run(.sequence([show, settle, SKAction.wait(forDuration: 0.10), vanish])) {
            container.removeFromParent()
        }
    }

    private static func popupStyle(for delta: Int) -> ScorePopupStyle {
        switch delta {
        case 900...:
            return ScorePopupStyle(
                fontSize: 42,
                peakScale: 1.15,
                riseDistance: 50,
                primary: SKColor(red: 1.0, green: 0.90, blue: 0.34, alpha: 1.0),
                accent: SKColor(red: 0.98, green: 0.55, blue: 0.20, alpha: 1.0)
            )
        case 500...899:
            return ScorePopupStyle(
                fontSize: 38,
                peakScale: 1.12,
                riseDistance: 45,
                primary: SKColor(red: 1.0, green: 0.86, blue: 0.34, alpha: 1.0),
                accent: SKColor(red: 0.96, green: 0.49, blue: 0.23, alpha: 1.0)
            )
        case 250...499:
            return ScorePopupStyle(
                fontSize: 34,
                peakScale: 1.10,
                riseDistance: 40,
                primary: SKColor(red: 1.0, green: 0.82, blue: 0.32, alpha: 1.0),
                accent: SKColor(red: 0.95, green: 0.43, blue: 0.30, alpha: 1.0)
            )
        default:
            return ScorePopupStyle(
                fontSize: 28,
                peakScale: 1.08,
                riseDistance: 34,
                primary: SKColor(red: 0.90, green: 0.96, blue: 1.0, alpha: 1.0),
                accent: SKColor(red: 0.44, green: 0.69, blue: 1.0, alpha: 1.0)
            )
        }
    }
}

enum LineClearFlyoutAnimation {
    static func play(on scene: SKScene, anchors: [CGPoint], linesCleared: Int) {
        guard linesCleared > 0 else { return }

        let points = anchors.isEmpty ? [CGPoint(x: scene.frame.midX, y: scene.frame.midY)] : anchors
        let maxBubbles = min(points.count, max(linesCleared, 1))

        for (index, point) in points.prefix(maxBubbles).enumerated() {
            let value = index == 0 && linesCleared > 1 ? "+\(linesCleared)" : "+1"
            let bubble = makeBubble(text: value)
            bubble.position = point
            bubble.zPosition = 7_700
            bubble.alpha = 0
            bubble.setScale(0.82)
            scene.addChild(bubble)

            let delay = SKAction.wait(forDuration: Double(index) * 0.04)
            let appear = SKAction.group([
                SKAction.fadeIn(withDuration: 0.10),
                SKAction.scale(to: 1.0, duration: 0.14)
            ])
            appear.timingMode = .easeOut

            let floatUp = SKAction.moveBy(x: 0, y: 24, duration: 0.34)
            floatUp.timingMode = .easeInEaseOut
            let fade = SKAction.fadeOut(withDuration: 0.30)
            fade.timingMode = .easeIn
            let exit = SKAction.group([floatUp, fade])

            bubble.run(.sequence([delay, appear, SKAction.wait(forDuration: 0.11), exit])) {
                bubble.removeFromParent()
            }
        }
    }

    private static func makeBubble(text: String) -> SKNode {
        let container = SKNode()

        let ring = SKShapeNode(circleOfRadius: 19)
        ring.lineWidth = 2.0
        ring.strokeColor = SKColor(red: 0.63, green: 0.86, blue: 1.0, alpha: 0.96)
        ring.fillColor = SKColor(red: 0.33, green: 0.56, blue: 0.94, alpha: 0.26)
        ring.glowWidth = 7
        container.addChild(ring)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 20
        label.fontColor = SKColor(red: 0.93, green: 0.98, blue: 1.0, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        return container
    }
}

private struct ComboTier {
    let level: Int
    let phrase: String
    let primary: SKColor
    let accent: SKColor
}

private struct ScorePopupStyle {
    let fontSize: CGFloat
    let peakScale: CGFloat
    let riseDistance: CGFloat
    let primary: SKColor
    let accent: SKColor
}
