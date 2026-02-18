import SpriteKit

final class PieceNode: SKNode {
    let piece: Piece
    var homePosition: CGPoint = .zero

    private var blockSize: CGFloat
    private var blockNodes: [SKShapeNode] = []
    private var glossNodes: [SKShapeNode] = []
    private var theme: GameVisualTheme = .default
    private var palette: [SKColor] = []
    private var activeTravelTarget: CGPoint?
    private var dragValidity: Bool?
    private var shimmerEnabled = true

    init(piece: Piece, blockSize: CGFloat) {
        self.piece = piece
        self.blockSize = blockSize
        super.init()
        isUserInteractionEnabled = false
        name = "piece_\(piece.id.uuidString)"
        rebuildBlocks()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func applyTheme(_ theme: GameVisualTheme) {
        self.theme = theme
        if palette.isEmpty {
            palette = [theme.pieceA, theme.pieceB, theme.pieceC]
        }
        repaintForCurrentState()
    }

    func applyPalette(_ palette: [SKColor]) {
        self.palette = palette.isEmpty ? [theme.pieceA, theme.pieceB, theme.pieceC] : palette
        repaintForCurrentState()
    }

    func updateBlockSize(_ newSize: CGFloat) {
        guard abs(blockSize - newSize) > 0.1 else { return }
        blockSize = newSize
        rebuildBlocks()
    }

    func setShimmerEnabled(_ enabled: Bool) {
        guard shimmerEnabled != enabled else { return }
        shimmerEnabled = enabled

        if !enabled {
            for gloss in glossNodes {
                gloss.removeAction(forKey: "piece_gloss_shimmer")
                gloss.alpha = min(gloss.alpha, 0.36)
            }
            return
        }

        runGlossShimmer()
    }

    func preferredDragLocalYRange() -> ClosedRange<CGFloat> {
        guard let minRow = piece.blocks.map(\.row).min(),
              let maxRow = piece.blocks.map(\.row).max()
        else {
            return -blockSize * 0.1...blockSize * 0.3
        }

        let baseY = CGFloat(minRow) * blockSize
        let height = CGFloat(maxRow - minRow + 1) * blockSize
        let minY = baseY - blockSize * 0.12
        let maxY = baseY + (height * 0.34)
        return minY...maxY
    }

    func startDragging() {
        removeAllActions()
        zPosition = 5_000
        let lift = SKAction.group([
            SKAction.scale(to: 1.07, duration: 0.12),
            SKAction.rotate(toAngle: CGFloat.random(in: -0.02...0.02), duration: 0.12, shortestUnitArc: true)
        ])
        lift.timingMode = .easeOut
        run(lift, withKey: "piece_drag_lift")
    }

    func stopDragging() {
        zPosition = 0
        let settle = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.16),
            SKAction.rotate(toAngle: 0, duration: 0.16, shortestUnitArc: true)
        ])
        settle.timingMode = .easeInEaseOut
        run(settle, withKey: "piece_drag_settle")
    }

    func setDragValidity(_ valid: Bool?) {
        guard dragValidity != valid else { return }
        dragValidity = valid
        applyDragValidityTint(valid)
    }

    func returnHome(animated: Bool) {
        stopDragging()
        setDragValidity(nil)
        if !animated {
            removeAction(forKey: "piece_travel")
            position = homePosition
            activeTravelTarget = nil
            return
        }

        let distanceToHome = hypot(position.x - homePosition.x, position.y - homePosition.y)
        guard distanceToHome > 0.35 else {
            removeAction(forKey: "piece_travel")
            position = homePosition
            activeTravelTarget = nil
            return
        }

        if action(forKey: "piece_travel") != nil,
           let target = activeTravelTarget,
           hypot(target.x - homePosition.x, target.y - homePosition.y) < 0.2 {
            return
        }

        removeAction(forKey: "piece_travel")
        activeTravelTarget = homePosition

        let move = SKAction.move(to: homePosition, duration: 0.20)
        move.timingMode = .easeInEaseOut
        run(.sequence([move, SKAction.run { [weak self] in
            self?.activeTravelTarget = nil
        }]), withKey: "piece_travel")
    }

    func snap(to point: CGPoint, completion: @escaping () -> Void) {
        stopDragging()
        removeAction(forKey: "piece_travel")
        activeTravelTarget = point

        let move = SKAction.move(to: point, duration: 0.12)
        move.timingMode = .easeOut
        let settleOut = SKAction.scale(to: 1.03, duration: 0.08)
        settleOut.timingMode = .easeOut
        let settleIn = SKAction.scale(to: 1.0, duration: 0.10)
        settleIn.timingMode = .easeInEaseOut

        let settle = SKAction.group([move, SKAction.sequence([settleOut, settleIn])])
        run(.sequence([settle, SKAction.run { [weak self] in
            self?.activeTravelTarget = nil
            completion()
        }]), withKey: "piece_travel")
    }

    private func rebuildBlocks() {
        removeAllChildren()
        blockNodes.removeAll(keepingCapacity: true)
        glossNodes.removeAll(keepingCapacity: true)

        for block in piece.blocks {
            let node = SKShapeNode(
                rectOf: CGSize(width: blockSize - 2, height: blockSize - 2),
                cornerRadius: max(4, blockSize * 0.15)
            )
            node.lineWidth = 1
            node.strokeColor = theme.cellStroke
            node.position = CGPoint(
                x: CGFloat(block.column) * blockSize,
                y: CGFloat(block.row) * blockSize
            )
            configureGemLayers(for: node)
            addChild(node)
            blockNodes.append(node)
        }

        repaintForCurrentState()
    }

    private func repaintForCurrentState() {
        repaintBlocks()
        if let dragValidity {
            applyDragValidityTint(dragValidity)
        }
    }

    private func applyDragValidityTint(_ valid: Bool?) {
        switch valid {
        case .some(true):
            for block in blockNodes {
                applyGemColors(to: block, baseColor: theme.validHighlight)
            }
        case .some(false):
            for block in blockNodes {
                applyGemColors(to: block, baseColor: theme.invalidHighlight)
            }
        case .none:
            repaintBlocks()
        }
    }

    private func repaintBlocks() {
        let activePalette = palette.isEmpty ? [theme.pieceA, theme.pieceB, theme.pieceC] : palette
        for (index, block) in blockNodes.enumerated() {
            block.strokeColor = mixed(theme.cellStroke, with: .black, ratio: 0.22)
            let paletteIndex = index % max(activePalette.count, 1)
            applyGemColors(to: block, baseColor: activePalette[paletteIndex])
        }
        if shimmerEnabled {
            runGlossShimmer()
        } else {
            for gloss in glossNodes {
                gloss.removeAction(forKey: "piece_gloss_shimmer")
                gloss.alpha = min(gloss.alpha, 0.36)
            }
        }
    }

    private func configureGemLayers(for block: SKShapeNode) {
        let size = max(8, blockSize - 2)
        let half = size / 2
        let inset = max(1.5, blockSize * 0.08)

        let topHighlight = SKShapeNode(path: CGMutablePath())
        let highlightPath = CGMutablePath()
        highlightPath.move(to: CGPoint(x: -half + inset, y: half - inset))
        highlightPath.addLine(to: CGPoint(x: half - inset, y: half - inset))
        highlightPath.addLine(to: CGPoint(x: half * 0.05, y: half * 0.18))
        highlightPath.addLine(to: CGPoint(x: -half + inset, y: half * 0.12))
        highlightPath.closeSubpath()
        topHighlight.path = highlightPath
        topHighlight.lineWidth = 0
        topHighlight.zPosition = 2
        topHighlight.blendMode = .add
        block.addChild(topHighlight)

        let cornerShadow = SKShapeNode(path: CGMutablePath())
        let shadowPath = CGMutablePath()
        shadowPath.move(to: CGPoint(x: half - inset, y: -half + inset))
        shadowPath.addLine(to: CGPoint(x: half - inset, y: half - inset))
        shadowPath.addLine(to: CGPoint(x: -half * 0.03, y: -half * 0.04))
        shadowPath.addLine(to: CGPoint(x: -half * 0.03, y: -half + inset))
        shadowPath.closeSubpath()
        cornerShadow.path = shadowPath
        cornerShadow.lineWidth = 0
        cornerShadow.zPosition = 1
        block.addChild(cornerShadow)

        let gloss = SKShapeNode(ellipseOf: CGSize(width: size * 0.42, height: size * 0.25))
        gloss.position = CGPoint(x: -size * 0.12, y: size * 0.16)
        gloss.lineWidth = 0
        gloss.zPosition = 3
        gloss.blendMode = .add
        block.addChild(gloss)
        glossNodes.append(gloss)
    }

    private func applyGemColors(to block: SKShapeNode, baseColor: SKColor) {
        block.fillColor = baseColor
        block.glowWidth = 1.4

        guard block.children.count >= 3,
              let topHighlight = block.children[0] as? SKShapeNode,
              let cornerShadow = block.children[1] as? SKShapeNode,
              let gloss = block.children[2] as? SKShapeNode
        else {
            return
        }

        topHighlight.fillColor = mixed(baseColor, with: .white, ratio: 0.34).withAlphaComponent(0.92)
        cornerShadow.fillColor = mixed(baseColor, with: .black, ratio: 0.28).withAlphaComponent(0.82)
        gloss.fillColor = SKColor.white.withAlphaComponent(0.36)
        gloss.alpha = shimmerEnabled ? 0.50 : 0.36
    }

    private func runGlossShimmer() {
        guard shimmerEnabled else { return }
        for gloss in glossNodes {
            if gloss.action(forKey: "piece_gloss_shimmer") != nil {
                continue
            }

            let delay = SKAction.wait(forDuration: TimeInterval(CGFloat.random(in: 0...0.8)))
            let brighten = SKAction.fadeAlpha(to: 0.78, duration: 0.30)
            brighten.timingMode = .easeOut
            let dim = SKAction.fadeAlpha(to: 0.46, duration: 0.40)
            dim.timingMode = .easeInEaseOut
            let cooldown = SKAction.wait(forDuration: TimeInterval(CGFloat.random(in: 1.6...3.0)))

            gloss.run(.sequence([delay, .repeatForever(.sequence([brighten, dim, cooldown]))]), withKey: "piece_gloss_shimmer")
        }
    }

    private func mixed(_ lhs: SKColor, with rhs: SKColor, ratio: CGFloat) -> SKColor {
        let t = min(max(0, ratio), 1)
        let l = rgba(lhs)
        let r = rgba(rhs)
        return SKColor(
            red: l.red + ((r.red - l.red) * t),
            green: l.green + ((r.green - l.green) * t),
            blue: l.blue + ((r.blue - l.blue) * t),
            alpha: l.alpha + ((r.alpha - l.alpha) * t)
        )
    }

    private func rgba(_ color: SKColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}
