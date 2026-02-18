import SpriteKit

enum ClearAnimation {
    static func play(
        on gridNode: GridNode,
        cells: Set<Cell>,
        particles: ParticlePool,
        palette: [SKColor],
        quality: CGFloat = 1.0
    ) {
        guard !cells.isEmpty else { return }

        let warm = palette.first ?? SKColor(red: 1.0, green: 0.82, blue: 0.18, alpha: 1.0)
        let budget = max(0.5, min(1.0, quality))
        let intensity = max(1, min(4, (cells.count + 3) / 4))
        let cool = palette.dropFirst().first ?? SKColor(red: 0.53, green: 0.77, blue: 1.0, alpha: 1.0)
        let bright = mixed(cool, with: .white, amount: 0.42)
        let clearedLines = inferredClearedLines(cells: cells, gridSize: gridNode.gridSize)
        let hasCompletedLine = !clearedLines.rows.isEmpty || !clearedLines.columns.isEmpty
        let preExplosionDelay: TimeInterval = hasCompletedLine ? 0.18 : 0

        runLineGuides(
            on: gridNode,
            rows: clearedLines.rows,
            columns: clearedLines.columns,
            color: mixed(warm, with: .white, amount: 0.18),
            budget: budget
        )
        runRetintPass(
            on: gridNode,
            cells: cells,
            primary: warm,
            secondary: cool,
            budget: budget
        )
        runLineSweeps(
            on: gridNode,
            rows: clearedLines.rows,
            columns: clearedLines.columns,
            color: mixed(warm, with: cool, amount: 0.24),
            budget: budget,
            baseDelay: preExplosionDelay
        )
        gridNode.runClearFlash(cells: cells, tintColor: warm, startDelay: preExplosionDelay)

        let sortedCells = cells.sorted { lhs, rhs in
            lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
        }

        for (index, cell) in sortedCells.enumerated() {
            let point = gridNode.centerPoint(for: cell)
            let delay = preExplosionDelay + (Double(index) * 0.012)

            particles.emit(
                at: point,
                color: warm,
                count: scaledCount(base: 5 + intensity, budget: budget),
                style: .burst
            )
            particles.emit(
                at: point,
                color: bright,
                count: scaledCount(base: 3 + (intensity / 2), budget: budget),
                style: .sparkle
            )
            particles.emit(
                at: point,
                color: mixed(cool, with: .white, amount: 0.25).withAlphaComponent(0.94),
                count: scaledCount(base: 3 + intensity, budget: budget),
                style: .mist
            )

            runShockwave(
                on: gridNode,
                at: point,
                color: mixed(warm, with: .white, amount: 0.20),
                cellSize: gridNode.cellSize,
                delay: delay,
                radiusScale: 1.0,
                alpha: 0.88
            )
            if intensity >= 2 && budget > 0.74 {
                runShockwave(
                    on: gridNode,
                    at: point,
                    color: mixed(cool, with: .white, amount: 0.16),
                    cellSize: gridNode.cellSize,
                    delay: delay + 0.05,
                    radiusScale: 1.42,
                    alpha: 0.58
                )
            }
            runSoftBloom(
                on: gridNode,
                at: point,
                color: mixed(warm, with: cool, amount: 0.35),
                cellSize: gridNode.cellSize,
                delay: delay
            )
        }
    }

    private static func runShockwave(
        on gridNode: GridNode,
        at point: CGPoint,
        color: SKColor,
        cellSize: CGFloat,
        delay: TimeInterval,
        radiusScale: CGFloat,
        alpha: CGFloat
    ) {
        let ring = SKShapeNode(circleOfRadius: cellSize * 0.22 * radiusScale)
        ring.position = point
        ring.lineWidth = 2.2
        ring.strokeColor = color.withAlphaComponent(alpha)
        ring.fillColor = .clear
        ring.glowWidth = 8
        ring.zPosition = 2_000

        gridNode.addChild(ring)

        let expand = SKAction.scale(to: 1.96, duration: 0.30)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.30)
        fade.timingMode = .easeIn
        let wait = SKAction.wait(forDuration: delay)

        ring.run(.sequence([wait, .group([expand, fade])])) {
            ring.removeFromParent()
        }
    }

    private static func runSoftBloom(
        on gridNode: GridNode,
        at point: CGPoint,
        color: SKColor,
        cellSize: CGFloat,
        delay: TimeInterval
    ) {
        let bloom = SKShapeNode(circleOfRadius: cellSize * 0.34)
        bloom.fillColor = color.withAlphaComponent(0.34)
        bloom.strokeColor = .clear
        bloom.glowWidth = 16
        bloom.position = point
        bloom.alpha = 0
        bloom.zPosition = 1_980
        gridNode.addChild(bloom)

        let wait = SKAction.wait(forDuration: delay)
        let fadeIn = SKAction.fadeAlpha(to: 0.78, duration: 0.10)
        fadeIn.timingMode = .easeOut
        let expand = SKAction.scale(to: 1.88, duration: 0.34)
        expand.timingMode = .easeInEaseOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.34)
        fadeOut.timingMode = .easeIn

        bloom.run(.sequence([wait, fadeIn, .group([expand, fadeOut])])) {
            bloom.removeFromParent()
        }
    }

    private static func runLineSweeps(
        on gridNode: GridNode,
        rows: [Int],
        columns: [Int],
        color: SKColor,
        budget: CGFloat,
        baseDelay: TimeInterval
    ) {
        guard budget > 0.60 else { return }
        guard !rows.isEmpty || !columns.isEmpty else { return }

        let boardSpan = CGFloat(gridNode.gridSize) * gridNode.cellSize
        let fill = mixed(color, with: .white, amount: 0.10).withAlphaComponent(0.42)
        let stroke = mixed(color, with: .white, amount: 0.45).withAlphaComponent(0.88)

        for (index, row) in rows.enumerated() {
            let y = gridNode.centerPoint(for: Cell(row: row, column: 0)).y
            let left = gridNode.centerPoint(for: Cell(row: row, column: 0)).x
            let right = gridNode.centerPoint(for: Cell(row: row, column: max(0, gridNode.gridSize - 1))).x
            runSweepBand(
                on: gridNode,
                size: CGSize(width: boardSpan * 0.98, height: gridNode.cellSize * 0.76),
                position: CGPoint(x: (left + right) / 2, y: y),
                fill: fill,
                stroke: stroke,
                delay: baseDelay + (Double(index) * 0.015)
            )
        }

        let columnDelayStart = Double(rows.count) * 0.015
        for (index, column) in columns.enumerated() {
            let x = gridNode.centerPoint(for: Cell(row: 0, column: column)).x
            let bottom = gridNode.centerPoint(for: Cell(row: 0, column: column)).y
            let top = gridNode.centerPoint(for: Cell(row: max(0, gridNode.gridSize - 1), column: column)).y
            runSweepBand(
                on: gridNode,
                size: CGSize(width: gridNode.cellSize * 0.76, height: boardSpan * 0.98),
                position: CGPoint(x: x, y: (bottom + top) / 2),
                fill: fill,
                stroke: stroke,
                delay: baseDelay + columnDelayStart + (Double(index) * 0.015)
            )
        }
    }

    private static func runSweepBand(
        on gridNode: GridNode,
        size: CGSize,
        position: CGPoint,
        fill: SKColor,
        stroke: SKColor,
        delay: TimeInterval
    ) {
        let band = SKShapeNode(
            rectOf: size,
            cornerRadius: min(size.width, size.height) * 0.40
        )
        band.lineWidth = 1.2
        band.fillColor = fill
        band.strokeColor = stroke
        band.blendMode = .add
        band.glowWidth = 9
        band.alpha = 0
        band.position = position
        band.zPosition = 1_920
        gridNode.addChild(band)

        let wait = SKAction.wait(forDuration: delay)
        let appear = SKAction.group([
            SKAction.fadeAlpha(to: 0.95, duration: 0.08),
            SKAction.scale(to: 1.02, duration: 0.10)
        ])
        appear.timingMode = .easeOut
        let hold = SKAction.wait(forDuration: 0.03)
        let fade = SKAction.group([
            SKAction.fadeOut(withDuration: 0.24),
            SKAction.scale(to: 1.07, duration: 0.24)
        ])
        fade.timingMode = .easeInEaseOut

        band.run(.sequence([wait, appear, hold, fade])) {
            band.removeFromParent()
        }
    }

    private static func runRetintPass(
        on gridNode: GridNode,
        cells: Set<Cell>,
        primary: SKColor,
        secondary: SKColor,
        budget: CGFloat
    ) {
        let sortedCells = cells.sorted { lhs, rhs in
            lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
        }
        let maxCells = max(1, Int((CGFloat(sortedCells.count) * min(1.0, budget + 0.08)).rounded()))
        for (index, cell) in sortedCells.prefix(maxCells).enumerated() {
            let block = tintedBlockNode(
                cellSize: gridNode.cellSize,
                primary: primary,
                secondary: secondary
            )
            block.position = gridNode.centerPoint(for: cell)
            block.zPosition = 1_860
            block.alpha = 0
            block.setScale(0.88)
            gridNode.addChild(block)

            let wait = SKAction.wait(forDuration: Double(index) * 0.006)
            let appear = SKAction.group([
                SKAction.fadeAlpha(to: 0.98, duration: 0.06),
                SKAction.scale(to: 1.03, duration: 0.07)
            ])
            appear.timingMode = .easeOut
            let hold = SKAction.wait(forDuration: 0.03)
            let burst = SKAction.group([
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.scale(to: 1.18, duration: 0.15)
            ])
            burst.timingMode = .easeIn

            block.run(.sequence([wait, appear, hold, burst])) {
                block.removeFromParent()
            }
        }
    }

    private static func tintedBlockNode(
        cellSize: CGFloat,
        primary: SKColor,
        secondary: SKColor
    ) -> SKNode {
        let container = SKNode()
        let size = max(8, cellSize - 2)
        let corner = max(4, cellSize * 0.15)

        let base = SKShapeNode(
            rectOf: CGSize(width: size, height: size),
            cornerRadius: corner
        )
        base.lineWidth = 1.0
        base.fillColor = primary
        base.strokeColor = mixed(primary, with: .black, amount: 0.26).withAlphaComponent(0.92)
        base.glowWidth = 1.8
        base.blendMode = .alpha
        container.addChild(base)

        let half = size / 2
        let inset = max(1.5, cellSize * 0.08)

        let highlightPath = CGMutablePath()
        highlightPath.move(to: CGPoint(x: -half + inset, y: half - inset))
        highlightPath.addLine(to: CGPoint(x: half - inset, y: half - inset))
        highlightPath.addLine(to: CGPoint(x: half * 0.08, y: half * 0.18))
        highlightPath.addLine(to: CGPoint(x: -half + inset, y: half * 0.12))
        highlightPath.closeSubpath()
        let highlight = SKShapeNode(path: highlightPath)
        highlight.lineWidth = 0
        highlight.fillColor = mixed(primary, with: .white, amount: 0.38).withAlphaComponent(0.92)
        highlight.blendMode = .add
        highlight.zPosition = 2
        container.addChild(highlight)

        let shadowPath = CGMutablePath()
        shadowPath.move(to: CGPoint(x: half - inset, y: -half + inset))
        shadowPath.addLine(to: CGPoint(x: half - inset, y: half - inset))
        shadowPath.addLine(to: CGPoint(x: -half * 0.03, y: -half * 0.03))
        shadowPath.addLine(to: CGPoint(x: -half * 0.03, y: -half + inset))
        shadowPath.closeSubpath()
        let shadow = SKShapeNode(path: shadowPath)
        shadow.lineWidth = 0
        shadow.fillColor = mixed(secondary, with: .black, amount: 0.28).withAlphaComponent(0.80)
        shadow.zPosition = 1
        container.addChild(shadow)

        let gloss = SKShapeNode(ellipseOf: CGSize(width: size * 0.42, height: size * 0.24))
        gloss.position = CGPoint(x: -size * 0.10, y: size * 0.16)
        gloss.lineWidth = 0
        gloss.fillColor = .white.withAlphaComponent(0.36)
        gloss.blendMode = .add
        gloss.zPosition = 3
        container.addChild(gloss)

        return container
    }

    private static func runLineGuides(
        on gridNode: GridNode,
        rows: [Int],
        columns: [Int],
        color: SKColor,
        budget: CGFloat
    ) {
        guard budget > 0.52 else { return }
        guard !rows.isEmpty || !columns.isEmpty else { return }

        let boardSpan = CGFloat(gridNode.gridSize) * gridNode.cellSize
        let fill = color.withAlphaComponent(0.52)
        let stroke = mixed(color, with: .white, amount: 0.34).withAlphaComponent(0.92)

        for (index, row) in rows.enumerated() {
            let y = gridNode.centerPoint(for: Cell(row: row, column: 0)).y
            let left = gridNode.centerPoint(for: Cell(row: row, column: 0)).x
            let right = gridNode.centerPoint(for: Cell(row: row, column: max(0, gridNode.gridSize - 1))).x
            runGuideBand(
                on: gridNode,
                size: CGSize(width: boardSpan * 1.01, height: gridNode.cellSize * 0.94),
                position: CGPoint(x: (left + right) / 2, y: y),
                fill: fill,
                stroke: stroke,
                delay: Double(index) * 0.012
            )
        }

        let columnDelayStart = Double(rows.count) * 0.012
        for (index, column) in columns.enumerated() {
            let x = gridNode.centerPoint(for: Cell(row: 0, column: column)).x
            let bottom = gridNode.centerPoint(for: Cell(row: 0, column: column)).y
            let top = gridNode.centerPoint(for: Cell(row: max(0, gridNode.gridSize - 1), column: column)).y
            runGuideBand(
                on: gridNode,
                size: CGSize(width: gridNode.cellSize * 0.94, height: boardSpan * 1.01),
                position: CGPoint(x: x, y: (bottom + top) / 2),
                fill: fill,
                stroke: stroke,
                delay: columnDelayStart + (Double(index) * 0.012)
            )
        }
    }

    private static func runGuideBand(
        on gridNode: GridNode,
        size: CGSize,
        position: CGPoint,
        fill: SKColor,
        stroke: SKColor,
        delay: TimeInterval
    ) {
        let band = SKShapeNode(
            rectOf: size,
            cornerRadius: min(size.width, size.height) * 0.36
        )
        band.lineWidth = 1.8
        band.fillColor = fill
        band.strokeColor = stroke
        band.blendMode = .add
        band.glowWidth = 12
        band.alpha = 0
        band.position = position
        band.zPosition = 1_840
        gridNode.addChild(band)

        let wait = SKAction.wait(forDuration: delay)
        let show = SKAction.fadeAlpha(to: 0.96, duration: 0.05)
        show.timingMode = .easeOut
        let hold = SKAction.wait(forDuration: 0.08)
        let fade = SKAction.fadeOut(withDuration: 0.20)
        fade.timingMode = .easeIn

        band.run(.sequence([wait, show, hold, fade])) {
            band.removeFromParent()
        }
    }

    private static func inferredClearedLines(cells: Set<Cell>, gridSize: Int) -> (rows: [Int], columns: [Int]) {
        var rowCounts: [Int: Int] = [:]
        var columnCounts: [Int: Int] = [:]
        for cell in cells {
            rowCounts[cell.row, default: 0] += 1
            columnCounts[cell.column, default: 0] += 1
        }

        let rows = rowCounts
            .filter { $0.value == gridSize }
            .map(\.key)
            .sorted()
        let columns = columnCounts
            .filter { $0.value == gridSize }
            .map(\.key)
            .sorted()
        return (rows, columns)
    }

    private static func scaledCount(base: Int, budget: CGFloat) -> Int {
        max(1, Int((CGFloat(base) * budget).rounded()))
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
