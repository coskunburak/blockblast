import SpriteKit

final class SceneEffectsSystem {
    func configureAmbientBoardAura(
        on ambienceNode: SKNode,
        gridNode: GridNode,
        theme: GameVisualTheme,
        isLowPowerMode: Bool
    ) {
        ambienceNode.removeAllChildren()
        ambienceNode.removeAllActions()

        let boardSize = CGFloat(gridNode.gridSize) * gridNode.cellSize
        let boardFrame = CGRect(
            x: gridNode.position.x - boardSize / 2 - 4,
            y: gridNode.position.y - boardSize / 2 - 4,
            width: boardSize + 8,
            height: boardSize + 8
        )

        let aura = SKShapeNode(rect: boardFrame, cornerRadius: max(12, gridNode.cellSize * 0.30))
        aura.strokeColor = SceneColorMath.blend(theme.cellStroke, with: .white, amount: 0.32).withAlphaComponent(0.62)
        aura.lineWidth = 1.9
        aura.glowWidth = 13
        aura.fillColor = .clear
        aura.alpha = 0.54
        ambienceNode.addChild(aura)

        let pulse = SKAction.repeatForever(
            .sequence([
                .fadeAlpha(to: 0.30, duration: 2.1),
                .fadeAlpha(to: 0.60, duration: 2.3)
            ])
        )
        pulse.timingMode = .easeInEaseOut
        aura.run(pulse, withKey: "ambient_aura_pulse")

        let moteCount = isLowPowerMode ? 5 : 9
        for index in 0..<moteCount {
            let mote = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.4...4.8))
            let moteBase = SceneColorMath.blend(theme.emptyCell, with: .white, amount: 0.58)
            mote.fillColor = moteBase.withAlphaComponent(0.24)
            mote.strokeColor = .clear
            mote.glowWidth = 9
            mote.alpha = 0.0
            mote.zPosition = -1

            mote.position = CGPoint(
                x: CGFloat.random(in: boardFrame.minX...boardFrame.maxX),
                y: CGFloat.random(in: boardFrame.minY...boardFrame.maxY)
            )
            ambienceNode.addChild(mote)

            let delay = SKAction.wait(forDuration: 0.14 * Double(index))
            let fadeIn = SKAction.fadeAlpha(to: 0.50, duration: 1.1)
            fadeIn.timingMode = .easeInEaseOut
            let drift = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 20...48), duration: 3.8)
            drift.timingMode = .easeInEaseOut
            let driftSide = SKAction.moveBy(x: CGFloat.random(in: -10...10), y: 0, duration: 3.2)
            driftSide.timingMode = .easeInEaseOut
            let fadeOut = SKAction.fadeOut(withDuration: 1.5)
            fadeOut.timingMode = .easeIn
            let reset = SKAction.run {
                mote.position = CGPoint(
                    x: CGFloat.random(in: boardFrame.minX...boardFrame.maxX),
                    y: CGFloat.random(in: boardFrame.minY...boardFrame.maxY)
                )
            }

            mote.run(
                .sequence([delay, .repeatForever(.sequence([fadeIn, .group([drift, driftSide, fadeOut]), reset]))]),
                withKey: "ambient_mote"
            )
        }
    }

    func runPlacementTrail(
        from start: CGPoint,
        to end: CGPoint,
        color: SKColor,
        cellSize: CGFloat,
        in scene: SKScene
    ) {
        let trail = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        trail.path = path
        trail.strokeColor = color.withAlphaComponent(0.54)
        trail.lineWidth = max(2.2, cellSize * 0.12)
        trail.glowWidth = 14
        trail.alpha = 0
        trail.zPosition = 3_100
        scene.addChild(trail)

        let core = SKShapeNode(path: path)
        core.strokeColor = SceneColorMath.blend(color, with: .white, amount: 0.34).withAlphaComponent(0.90)
        core.lineWidth = max(1.1, cellSize * 0.055)
        core.glowWidth = 5
        core.alpha = 0
        core.zPosition = 3_101
        scene.addChild(core)

        let fadeIn = SKAction.fadeAlpha(to: 0.84, duration: 0.08)
        fadeIn.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.34)
        fadeOut.timingMode = .easeIn
        trail.run(.sequence([fadeIn, fadeOut])) {
            trail.removeFromParent()
        }

        core.run(.sequence([SKAction.fadeAlpha(to: 1.0, duration: 0.06), SKAction.fadeOut(withDuration: 0.28)])) {
            core.removeFromParent()
        }
    }

    func runPlacementPulse(
        cells: Set<Cell>,
        color: SKColor,
        gridNode: GridNode,
        particles: ParticlePool,
        isLowPowerMode: Bool
    ) {
        let mistCount = isLowPowerMode ? 2 : 3
        let sparkleCount = isLowPowerMode ? 0 : 1
        for cell in cells {
            let point = gridNode.centerPoint(for: cell)
            particles.emit(
                at: point,
                color: SceneColorMath.blend(color, with: .white, amount: 0.30),
                count: mistCount,
                style: .mist
            )
            if sparkleCount > 0 {
                particles.emit(
                    at: point,
                    color: SceneColorMath.blend(color, with: .white, amount: 0.45),
                    count: sparkleCount,
                    style: .sparkle
                )
            }
            runPlacementRipple(at: point, color: color, gridNode: gridNode)
        }
    }

    func runComboBoardAura(
        chain: Int,
        gridNode: GridNode,
        particles: ParticlePool,
        theme: GameVisualTheme,
        isLowPowerMode: Bool
    ) {
        let boardSize = CGFloat(gridNode.gridSize) * gridNode.cellSize
        let inset = max(3, gridNode.cellSize * 0.12)
        let frame = CGRect(
            x: -boardSize / 2 - inset,
            y: -boardSize / 2 - inset,
            width: boardSize + inset * 2,
            height: boardSize + inset * 2
        )

        let aura = SKShapeNode(rect: frame, cornerRadius: max(12, gridNode.cellSize * 0.36))
        let auraColor = SceneColorMath.blend(theme.pieceC, with: .white, amount: 0.22)
        aura.strokeColor = auraColor.withAlphaComponent(0.94)
        aura.lineWidth = 2.4
        aura.glowWidth = 20
        aura.fillColor = .clear
        aura.alpha = 0
        aura.zPosition = 1_900
        gridNode.addChild(aura)

        let popIn = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.12),
            SKAction.scale(to: 1.02, duration: 0.12)
        ])
        popIn.timingMode = .easeOut

        let settle = SKAction.scale(to: 1.0, duration: 0.14)
        settle.timingMode = .easeInEaseOut

        let fadeOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.50),
            SKAction.scale(to: 1.05, duration: 0.50)
        ])
        fadeOut.timingMode = .easeIn

        aura.run(.sequence([popIn, settle, fadeOut])) {
            aura.removeFromParent()
        }

        let sparkleCountBase = max(10, min(38, chain * 7))
        let sparkleCount = isLowPowerMode
            ? max(8, Int((CGFloat(sparkleCountBase) * 0.62).rounded()))
            : sparkleCountBase
        let sparkleColor = SceneColorMath.blend(theme.pieceC, with: .white, amount: 0.24)
        for index in 0..<sparkleCount {
            let point = randomPointOnBoardBorder(boardSize: boardSize)
            particles.emit(at: point, color: sparkleColor, count: 1, style: .sparkle)
            if chain >= 3 && (!isLowPowerMode || index.isMultiple(of: 2)) {
                particles.emit(
                    at: point,
                    color: SceneColorMath.blend(sparkleColor, with: .white, amount: 0.24),
                    count: 1,
                    style: .mist
                )
            }
        }
    }

    private func runPlacementRipple(at point: CGPoint, color: SKColor, gridNode: GridNode) {
        let ring = SKShapeNode(circleOfRadius: gridNode.cellSize * 0.20)
        ring.position = point
        ring.lineWidth = 1.6
        ring.strokeColor = SceneColorMath.blend(color, with: .white, amount: 0.28).withAlphaComponent(0.74)
        ring.fillColor = .clear
        ring.glowWidth = 7
        ring.alpha = 0
        ring.zPosition = 2_040
        gridNode.addChild(ring)

        let appear = SKAction.fadeAlpha(to: 0.88, duration: 0.06)
        appear.timingMode = .easeOut
        let expand = SKAction.scale(to: 1.70, duration: 0.26)
        expand.timingMode = .easeInEaseOut
        let fade = SKAction.fadeOut(withDuration: 0.26)
        fade.timingMode = .easeIn

        ring.run(.sequence([appear, .group([expand, fade])])) {
            ring.removeFromParent()
        }
    }

    private func randomPointOnBoardBorder(boardSize: CGFloat) -> CGPoint {
        let half = boardSize / 2
        switch Int.random(in: 0...3) {
        case 0:
            return CGPoint(x: CGFloat.random(in: -half...half), y: half)
        case 1:
            return CGPoint(x: CGFloat.random(in: -half...half), y: -half)
        case 2:
            return CGPoint(x: -half, y: CGFloat.random(in: -half...half))
        default:
            return CGPoint(x: half, y: CGFloat.random(in: -half...half))
        }
    }
}
