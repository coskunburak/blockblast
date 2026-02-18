import SpriteKit

final class GridNode: SKNode {
    private(set) var gridSize: Int
    private(set) var cellSize: CGFloat
    private(set) var localOrigin: CGPoint = .zero

    private var cellNodes: [Cell: CellNode] = [:]
    private var theme: GameVisualTheme = .default
    private var filledColorOverrides: [Cell: SKColor] = [:]
    private var highlightedCells: Set<Cell> = []
    private var highlightStyle: HighlightStyle?
    private var lowPowerModeEnabled = false
    private var reduceMotionEnabled = false
    private var dynamicGlossShimmerEnabled = true

    init(gridSize: Int, cellSize: CGFloat) {
        self.gridSize = gridSize
        self.cellSize = cellSize
        super.init()
        rebuildCells()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func applyTheme(_ theme: GameVisualTheme) {
        self.theme = theme
        for node in cellNodes.values {
            node.applyTheme(theme)
        }
    }

    func configurePerformance(isLowPowerMode: Bool, reduceMotion: Bool) {
        lowPowerModeEnabled = isLowPowerMode
        reduceMotionEnabled = reduceMotion
        refreshGlossPolicy(force: true, fillRatio: nil)
    }

    func updateLayout(gridSize: Int, cellSize: CGFloat) {
        let sizeChanged = self.gridSize != gridSize
        let cellSizeChanged = abs(self.cellSize - cellSize) > 0.1
        self.gridSize = gridSize
        self.cellSize = cellSize

        if sizeChanged {
            rebuildCells()
            return
        }

        let boardSize = CGFloat(gridSize) * cellSize
        let newOrigin = CGPoint(x: -boardSize / 2 + cellSize / 2, y: -boardSize / 2 + cellSize / 2)
        let originChanged = distance(from: localOrigin, to: newOrigin) > 0.1
        guard sizeChanged || cellSizeChanged || originChanged else { return }

        localOrigin = newOrigin

        for row in 0..<gridSize {
            for column in 0..<gridSize {
                let cell = Cell(row: row, column: column)
                guard let node = cellNodes[cell] else { continue }
                node.position = centerPoint(for: cell)
                if cellSizeChanged {
                    node.setCellSize(cellSize)
                }
            }
        }
    }

    func render(grid: Grid) {
        let totalCells = max(1, gridSize * gridSize)
        let fillRatio = Double(grid.filled.count) / Double(totalCells)
        refreshGlossPolicy(force: false, fillRatio: fillRatio)

        for row in 0..<gridSize {
            for column in 0..<gridSize {
                let cell = Cell(row: row, column: column)
                let color = filledColorOverrides[cell]
                cellNodes[cell]?.setFilled(grid.contains(cell), colorOverride: color)
            }
        }
    }

    func setFilledColor(_ color: SKColor, for cell: Cell) {
        guard isInside(cell) else { return }
        filledColorOverrides[cell] = color
    }

    func clearFilledColor(for cell: Cell) {
        filledColorOverrides.removeValue(forKey: cell)
    }

    func clearAllFilledColors() {
        filledColorOverrides.removeAll(keepingCapacity: true)
    }

    func showHighlight(cells: [Cell], isValid: Bool) {
        let style: HighlightStyle = isValid ? .valid : .invalid
        let nextHighlightedCells = Set(cells.filter { isInside($0) })
        guard nextHighlightedCells != highlightedCells || highlightStyle != style else {
            return
        }

        if highlightStyle != style {
            for cell in highlightedCells {
                cellNodes[cell]?.setHighlight(nil)
            }
        } else {
            for cell in highlightedCells.subtracting(nextHighlightedCells) {
                cellNodes[cell]?.setHighlight(nil)
            }
        }

        let cellsToHighlight = highlightStyle == style
            ? nextHighlightedCells.subtracting(highlightedCells)
            : nextHighlightedCells
        for cell in cellsToHighlight {
            cellNodes[cell]?.setHighlight(style)
        }

        highlightedCells = nextHighlightedCells
        highlightStyle = style
    }

    func clearHighlight() {
        guard !highlightedCells.isEmpty || highlightStyle != nil else { return }
        for cell in highlightedCells {
            cellNodes[cell]?.setHighlight(nil)
        }
        highlightedCells.removeAll(keepingCapacity: true)
        highlightStyle = nil
    }

    func centerPoint(for cell: Cell) -> CGPoint {
        CGPoint(
            x: localOrigin.x + CGFloat(cell.column) * cellSize,
            y: localOrigin.y + CGFloat(cell.row) * cellSize
        )
    }

    func isInside(_ cell: Cell) -> Bool {
        (0..<gridSize).contains(cell.row) && (0..<gridSize).contains(cell.column)
    }

    func runPlacementPop(cells: [Cell]) {
        let sortedCells = cells.sorted { lhs, rhs in
            lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
        }

        for (index, cell) in sortedCells.enumerated() where isInside(cell) {
            let delay = SKAction.wait(forDuration: Double(index) * 0.012)
            let popOut = SKAction.scale(to: 1.11, duration: 0.08)
            popOut.timingMode = .easeOut
            let settle = SKAction.scale(to: 0.98, duration: 0.06)
            settle.timingMode = .easeInEaseOut
            let popIn = SKAction.scale(to: 1.0, duration: 0.10)
            popIn.timingMode = .easeInEaseOut
            let pop = SKAction.sequence([delay, popOut, settle, popIn])
            cellNodes[cell]?.run(pop)
        }
    }

    func runClearFlash(cells: Set<Cell>, tintColor: SKColor, startDelay: TimeInterval = 0) {
        let sortedCells = cells.sorted { lhs, rhs in
            lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
        }

        for (index, cell) in sortedCells.enumerated() where isInside(cell) {
            let delay = SKAction.wait(forDuration: startDelay + (Double(index) * 0.010))
            let brighten = SKAction.group([
                SKAction.fadeAlpha(to: 0.18, duration: 0.08),
                SKAction.scale(to: 1.10, duration: 0.08)
            ])
            brighten.timingMode = .easeOut

            let restore = SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.18),
                SKAction.scale(to: 1.0, duration: 0.18)
            ])
            restore.timingMode = .easeInEaseOut

            cellNodes[cell]?.run(.sequence([delay, brighten, restore]))

            let overlay = SKShapeNode(
                rectOf: CGSize(width: cellSize - 2, height: cellSize - 2),
                cornerRadius: max(4, cellSize * 0.15)
            )
            overlay.lineWidth = 0
            overlay.blendMode = .add
            overlay.fillColor = SceneColorMath
                .blend(tintColor, with: .white, amount: 0.22)
                .withAlphaComponent(0.82)
            overlay.alpha = 0
            overlay.position = centerPoint(for: cell)
            overlay.zPosition = 1_600
            addChild(overlay)

            let overlayAppear = SKAction.group([
                SKAction.fadeAlpha(to: 0.86, duration: 0.06),
                SKAction.scale(to: 1.08, duration: 0.08)
            ])
            overlayAppear.timingMode = .easeOut

            let overlayFade = SKAction.group([
                SKAction.fadeOut(withDuration: 0.20),
                SKAction.scale(to: 1.16, duration: 0.20)
            ])
            overlayFade.timingMode = .easeInEaseOut

            overlay.run(.sequence([delay, overlayAppear, overlayFade])) {
                overlay.removeFromParent()
            }
        }
    }

    private func rebuildCells() {
        removeAllChildren()
        cellNodes.removeAll(keepingCapacity: true)
        highlightedCells.removeAll(keepingCapacity: true)
        highlightStyle = nil

        for row in 0..<gridSize {
            for column in 0..<gridSize {
                let cell = Cell(row: row, column: column)
                let node = CellNode(cell: cell, size: cellSize)
                node.applyTheme(theme)
                node.setGlossShimmerEnabled(dynamicGlossShimmerEnabled)
                addChild(node)
                cellNodes[cell] = node
            }
        }

        updateLayout(gridSize: gridSize, cellSize: cellSize)
    }

    private func refreshGlossPolicy(force: Bool, fillRatio: Double?) {
        let resolvedFillRatio = fillRatio ?? 0
        let shouldEnable = !lowPowerModeEnabled &&
            !reduceMotionEnabled &&
            resolvedFillRatio < 0.58
        guard force || shouldEnable != dynamicGlossShimmerEnabled else { return }

        dynamicGlossShimmerEnabled = shouldEnable
        for node in cellNodes.values {
            node.setGlossShimmerEnabled(shouldEnable)
        }
    }

    private func distance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}
