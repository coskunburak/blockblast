import SpriteKit

final class AssistHintSystem {
    private struct AssistHint: Equatable {
        let pieceID: Piece.ID
        let anchor: Cell
        let cells: [Cell]
        let legalPlacements: Int
        let clearLines: Int
    }

    private struct AssistAnalysis {
        let bestHint: AssistHint?
        let totalLegalPlacements: Int
    }

    private let isLowPowerMode: Bool
    private let assistGridNode = SKNode()
    private let assistSceneNode = SKNode()

    private var invalidDropStreak = 0
    private var activeAssistHint: AssistHint?
    private var assistAnalysisSignature: Int?
    private var assistAnalysisCache: AssistAnalysis?
    private var assistVisualsVisible = false

    init(isLowPowerMode: Bool) {
        self.isLowPowerMode = isLowPowerMode
    }

    func attach(to gridNode: GridNode, scene: SKScene) {
        if assistGridNode.parent !== gridNode {
            assistGridNode.removeFromParent()
            gridNode.addChild(assistGridNode)
        }
        if assistSceneNode.parent !== scene {
            assistSceneNode.removeFromParent()
            scene.addChild(assistSceneNode)
        }
        assistGridNode.zPosition = 2_600
        assistSceneNode.zPosition = 4_900
    }

    func process(recentEvents: [GameEvent], pieceNodes: [Piece.ID: PieceNode]) {
        if recentEvents.contains(where: {
            if case .gameStarted = $0 { return true }
            return false
        }) {
            invalidDropStreak = 0
            activeAssistHint = nil
            assistAnalysisSignature = nil
            assistAnalysisCache = nil
            clearAssistHintVisuals(pieceNodes: pieceNodes)
        }

        if recentEvents.contains(where: {
            if case .piecePlaced = $0 { return true }
            return false
        }) {
            registerValidDrop()
        }

        if recentEvents.contains(where: {
            if case .invalidMove = $0 { return true }
            return false
        }) {
            registerInvalidDrop()
        }
    }

    func registerInvalidDrop() {
        invalidDropStreak += 1
    }

    func registerValidDrop() {
        invalidDropStreak = 0
    }

    func clearVisuals(pieceNodes: [Piece.ID: PieceNode]) {
        clearAssistHintVisuals(pieceNodes: pieceNodes)
    }

    func resetForThemeChange(pieceNodes: [Piece.ID: PieceNode]) {
        activeAssistHint = nil
        clearAssistHintVisuals(pieceNodes: pieceNodes)
    }

    func update(
        for state: GameState,
        recentEvents: [GameEvent],
        dragActive: Bool,
        pieceNodes: [Piece.ID: PieceNode],
        gridNode: GridNode,
        theme: GameVisualTheme,
        particles: ParticlePool,
        in scene: SKScene
    ) {
        guard state.runtime == .running else {
            invalidDropStreak = 0
            activeAssistHint = nil
            clearAssistHintVisuals(pieceNodes: pieceNodes)
            return
        }

        guard !dragActive else {
            clearAssistHintVisuals(pieceNodes: pieceNodes)
            return
        }

        let analysis = cachedAssistAnalysis(for: state)
        let lowMoveThreshold = isLowPowerMode ? 5 : 7
        let shouldShowAssist = invalidDropStreak >= 2 || analysis.totalLegalPlacements <= lowMoveThreshold

        guard shouldShowAssist, let hint = analysis.bestHint else {
            activeAssistHint = nil
            clearAssistHintVisuals(pieceNodes: pieceNodes)
            return
        }

        if activeAssistHint == hint, assistVisualsVisible {
            return
        }

        let urgent = invalidDropStreak >= 2 || recentEvents.contains(where: {
            if case .invalidMove = $0 { return true }
            return false
        })
        presentAssistHint(
            hint,
            urgent: urgent,
            pieceNodes: pieceNodes,
            gridNode: gridNode,
            theme: theme,
            particles: particles,
            in: scene
        )
        activeAssistHint = hint
    }

    private func cachedAssistAnalysis(for state: GameState) -> AssistAnalysis {
        let signature = assistSignature(for: state)
        if assistAnalysisSignature == signature, let assistAnalysisCache {
            return assistAnalysisCache
        }

        let analysis = analyzeAssistOptions(for: state)
        assistAnalysisSignature = signature
        assistAnalysisCache = analysis
        return analysis
    }

    private func assistSignature(for state: GameState) -> Int {
        var hasher = Hasher()
        hasher.combine(state.grid.size)
        let sortedCells = state.grid.filled.sorted { lhs, rhs in
            if lhs.row == rhs.row {
                return lhs.column < rhs.column
            }
            return lhs.row < rhs.row
        }
        for cell in sortedCells {
            hasher.combine(cell.row)
            hasher.combine(cell.column)
        }
        for piece in state.upcomingPieces {
            hasher.combine(piece.id)
            hasher.combine(piece.kind.rawValue)
        }
        return hasher.finalize()
    }

    private func analyzeAssistOptions(for state: GameState) -> AssistAnalysis {
        let grid = state.grid
        let boardCenter = Double(grid.size - 1) / 2
        var totalLegalPlacements = 0
        var bestHint: AssistHint?
        var bestScore = Int.min

        var rowCounts = Array(repeating: 0, count: grid.size)
        var columnCounts = Array(repeating: 0, count: grid.size)
        for cell in grid.filled {
            rowCounts[cell.row] += 1
            columnCounts[cell.column] += 1
        }

        var translated: [Cell] = []
        translated.reserveCapacity(4)
        var touchedRows: [Int] = []
        touchedRows.reserveCapacity(4)
        var touchedColumns: [Int] = []
        touchedColumns.reserveCapacity(4)
        var rowDeltas = Array(repeating: 0, count: grid.size)
        var columnDeltas = Array(repeating: 0, count: grid.size)

        for piece in state.upcomingPieces {
            var legalPlacements = 0
            var bestAnchor: Cell?
            var bestCells: [Cell] = []
            var bestClearLines = 0
            var bestLocalScore = Int.min

            for row in 0..<grid.size {
                for column in 0..<grid.size {
                    let anchor = Cell(row: row, column: column)
                    translated.removeAll(keepingCapacity: true)
                    touchedRows.removeAll(keepingCapacity: true)
                    touchedColumns.removeAll(keepingCapacity: true)
                    var rowSum = 0
                    var columnSum = 0
                    var isLegal = true

                    for block in piece.blocks {
                        let cell = Cell(row: anchor.row + block.row, column: anchor.column + block.column)
                        if !grid.isInside(cell) || grid.contains(cell) {
                            isLegal = false
                            break
                        }

                        translated.append(cell)
                        rowSum += cell.row
                        columnSum += cell.column

                        if rowDeltas[cell.row] == 0 {
                            touchedRows.append(cell.row)
                        }
                        rowDeltas[cell.row] += 1

                        if columnDeltas[cell.column] == 0 {
                            touchedColumns.append(cell.column)
                        }
                        columnDeltas[cell.column] += 1
                    }

                    guard isLegal else {
                        for rowIndex in touchedRows {
                            rowDeltas[rowIndex] = 0
                        }
                        for columnIndex in touchedColumns {
                            columnDeltas[columnIndex] = 0
                        }
                        continue
                    }

                    legalPlacements += 1

                    var clearLines = 0
                    for rowIndex in touchedRows {
                        if rowCounts[rowIndex] + rowDeltas[rowIndex] == grid.size {
                            clearLines += 1
                        }
                        rowDeltas[rowIndex] = 0
                    }
                    for columnIndex in touchedColumns {
                        if columnCounts[columnIndex] + columnDeltas[columnIndex] == grid.size {
                            clearLines += 1
                        }
                        columnDeltas[columnIndex] = 0
                    }

                    let centroidRow = Double(rowSum) / Double(translated.count)
                    let centroidColumn = Double(columnSum) / Double(translated.count)
                    let centerDistance = abs(centroidRow - boardCenter) + abs(centroidColumn - boardCenter)
                    let openness = openNeighborCount(for: translated, on: grid)

                    var localScore = (clearLines * 1_600) + (openness * 20) - Int((centerDistance * 8).rounded())
                    if isHelperKindForAssist(piece.kind) {
                        localScore += 36
                    }

                    if localScore > bestLocalScore {
                        bestLocalScore = localScore
                        bestAnchor = anchor
                        bestCells = translated
                        bestClearLines = clearLines
                    }
                }
            }

            totalLegalPlacements += legalPlacements
            guard let bestAnchor else { continue }

            var candidateScore = bestLocalScore + (legalPlacements * 26) + (bestClearLines * 220)
            if isHelperKindForAssist(piece.kind) {
                candidateScore += 80
            }

            if candidateScore > bestScore {
                bestScore = candidateScore
                bestHint = AssistHint(
                    pieceID: piece.id,
                    anchor: bestAnchor,
                    cells: bestCells,
                    legalPlacements: legalPlacements,
                    clearLines: bestClearLines
                )
            }
        }

        return AssistAnalysis(bestHint: bestHint, totalLegalPlacements: totalLegalPlacements)
    }

    private func presentAssistHint(
        _ hint: AssistHint,
        urgent: Bool,
        pieceNodes: [Piece.ID: PieceNode],
        gridNode: GridNode,
        theme: GameVisualTheme,
        particles: ParticlePool,
        in scene: SKScene
    ) {
        clearAssistHintVisuals(pieceNodes: pieceNodes)

        let guideColor = SceneColorMath.blend(theme.validHighlight, with: .white, amount: urgent ? 0.34 : 0.18)
        let cellSize = gridNode.cellSize

        for cell in hint.cells {
            let overlay = SKShapeNode(
                rectOf: CGSize(width: cellSize * 0.80, height: cellSize * 0.80),
                cornerRadius: max(4, cellSize * 0.16)
            )
            overlay.position = gridNode.centerPoint(for: cell)
            overlay.fillColor = guideColor.withAlphaComponent(urgent ? 0.24 : 0.16)
            overlay.strokeColor = guideColor.withAlphaComponent(urgent ? 0.80 : 0.66)
            overlay.lineWidth = 1.2
            overlay.glowWidth = urgent ? 11 : 8
            overlay.alpha = 0
            overlay.zPosition = 5
            assistGridNode.addChild(overlay)

            let appear = SKAction.fadeAlpha(to: 1.0, duration: 0.16)
            appear.timingMode = .easeOut
            let pulse = SKAction.repeatForever(
                .sequence([
                    .fadeAlpha(to: 0.44, duration: 0.72),
                    .fadeAlpha(to: 1.0, duration: 0.72)
                ])
            )
            pulse.timingMode = .easeInEaseOut
            overlay.run(.sequence([appear, pulse]), withKey: "assist_cell_pulse")
        }

        let anchorPoint = gridNode.centerPoint(for: hint.anchor)
        let anchorRing = SKShapeNode(circleOfRadius: cellSize * 0.30)
        anchorRing.position = anchorPoint
        anchorRing.strokeColor = guideColor.withAlphaComponent(0.90)
        anchorRing.fillColor = .clear
        anchorRing.lineWidth = 1.8
        anchorRing.glowWidth = urgent ? 13 : 10
        anchorRing.alpha = 0
        anchorRing.zPosition = 8
        assistGridNode.addChild(anchorRing)
        anchorRing.run(
            .sequence([
                .fadeIn(withDuration: 0.10),
                .repeatForever(
                    .sequence([
                        .scale(to: 1.18, duration: 0.64),
                        .scale(to: 1.0, duration: 0.64)
                    ])
                )
            ]),
            withKey: "assist_anchor_ring"
        )

        removePieceBeacons(pieceNodes: pieceNodes)
        if let pieceNode = pieceNodes[hint.pieceID] {
            let beacon = SKShapeNode(circleOfRadius: cellSize * 0.36)
            beacon.name = "assist_beacon"
            beacon.strokeColor = guideColor.withAlphaComponent(0.82)
            beacon.fillColor = .clear
            beacon.lineWidth = 1.6
            beacon.glowWidth = urgent ? 16 : 12
            beacon.alpha = 0
            beacon.zPosition = 42
            pieceNode.addChild(beacon)
            beacon.run(
                .sequence([
                    .fadeIn(withDuration: 0.12),
                    .repeatForever(
                        .sequence([
                            .fadeAlpha(to: 0.38, duration: 0.70),
                            .fadeAlpha(to: 1.0, duration: 0.70)
                        ])
                    )
                ]),
                withKey: "assist_beacon_pulse"
            )

            if let pieceParent = pieceNode.parent {
                let start = scene.convert(pieceNode.position, from: pieceParent)
                let end = scene.convert(anchorPoint, from: gridNode)
                let guidePath = CGMutablePath()
                guidePath.move(to: start)
                guidePath.addLine(to: end)

                let line = SKShapeNode(path: guidePath)
                line.strokeColor = guideColor.withAlphaComponent(0.58)
                line.lineWidth = max(1.4, cellSize * 0.08)
                line.glowWidth = 6
                line.alpha = 0
                assistSceneNode.addChild(line)

                let core = SKShapeNode(path: guidePath)
                core.strokeColor = SceneColorMath.blend(guideColor, with: .white, amount: 0.28).withAlphaComponent(0.90)
                core.lineWidth = max(0.8, cellSize * 0.05)
                core.glowWidth = 3
                core.alpha = 0
                assistSceneNode.addChild(core)

                let linePulse = SKAction.repeatForever(
                    .sequence([
                        .fadeAlpha(to: 0.76, duration: 0.56),
                        .fadeAlpha(to: 0.30, duration: 0.70)
                    ])
                )
                linePulse.timingMode = .easeInEaseOut
                line.run(.sequence([.fadeIn(withDuration: 0.12), linePulse]), withKey: "assist_line_pulse")
                core.run(.sequence([.fadeIn(withDuration: 0.10), linePulse]), withKey: "assist_core_pulse")
            }
        }

        particles.emit(
            at: anchorPoint,
            color: guideColor.withAlphaComponent(0.92),
            count: isLowPowerMode ? 1 : 2,
            style: .sparkle
        )
        presentAssistMessage(
            for: hint,
            urgent: urgent,
            anchorPoint: anchorPoint,
            guideColor: guideColor,
            cellSize: cellSize,
            gridNode: gridNode,
            in: scene
        )
        assistVisualsVisible = true
    }

    private func clearAssistHintVisuals(pieceNodes: [Piece.ID: PieceNode]) {
        guard assistVisualsVisible else { return }
        assistGridNode.removeAllActions()
        assistGridNode.removeAllChildren()
        assistSceneNode.removeAllActions()
        assistSceneNode.removeAllChildren()
        removePieceBeacons(pieceNodes: pieceNodes)
        assistVisualsVisible = false
    }

    private func removePieceBeacons(pieceNodes: [Piece.ID: PieceNode]) {
        for pieceNode in pieceNodes.values {
            pieceNode.childNode(withName: "assist_beacon")?.removeFromParent()
        }
    }

    private func openNeighborCount(for cells: [Cell], on grid: Grid) -> Int {
        var score = 0
        for cell in cells {
            let neighbors = [
                Cell(row: cell.row + 1, column: cell.column),
                Cell(row: cell.row - 1, column: cell.column),
                Cell(row: cell.row, column: cell.column + 1),
                Cell(row: cell.row, column: cell.column - 1)
            ]
            for neighbor in neighbors where grid.isInside(neighbor) && !grid.contains(neighbor) {
                score += 1
            }
        }
        return score
    }

    private func isHelperKindForAssist(_ kind: Piece.Kind) -> Bool {
        switch kind {
        case .dot1, .line3, .square2, .l3:
            return true
        default:
            return false
        }
    }

    private func presentAssistMessage(
        for hint: AssistHint,
        urgent: Bool,
        anchorPoint: CGPoint,
        guideColor: SKColor,
        cellSize: CGFloat,
        gridNode: GridNode,
        in scene: SKScene
    ) {
        let message = assistMessage(for: hint, urgent: urgent)

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = message
        label.fontSize = max(11, cellSize * 0.32)
        label.fontColor = SceneColorMath.blend(guideColor, with: .white, amount: 0.46).withAlphaComponent(0.97)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        let labelPaddingX = max(10, cellSize * 0.34)
        let labelPaddingY = max(6, cellSize * 0.20)
        let labelFrame = label.frame.insetBy(dx: -labelPaddingX, dy: -labelPaddingY)
        let bubble = SKShapeNode(
            rectOf: CGSize(width: labelFrame.width, height: labelFrame.height),
            cornerRadius: max(8, cellSize * 0.22)
        )
        bubble.fillColor = SceneColorMath.blend(.black, with: guideColor, amount: 0.18).withAlphaComponent(0.66)
        bubble.strokeColor = guideColor.withAlphaComponent(0.58)
        bubble.lineWidth = 1.0
        bubble.glowWidth = 6

        let container = SKNode()
        container.alpha = 0
        container.zPosition = 4_905
        container.addChild(bubble)
        container.addChild(label)
        assistSceneNode.addChild(container)

        let anchorInScene = scene.convert(anchorPoint, from: gridNode)
        container.position = CGPoint(
            x: anchorInScene.x,
            y: anchorInScene.y + max(cellSize * 1.35, 24)
        )

        let appear = SKAction.fadeAlpha(to: 1.0, duration: 0.14)
        appear.timingMode = .easeOut
        let pulse = SKAction.repeatForever(
            .sequence([
                .fadeAlpha(to: 0.78, duration: 0.78),
                .fadeAlpha(to: 1.0, duration: 0.78)
            ])
        )
        pulse.timingMode = .easeInEaseOut
        container.run(.sequence([appear, pulse]), withKey: "assist_message_pulse")
    }

    private func assistMessage(for hint: AssistHint, urgent: Bool) -> String {
        if hint.clearLines >= 2 {
            return "Great move: clears \(hint.clearLines) lines"
        }
        if hint.clearLines == 1 {
            return "Try this for a clean line clear"
        }
        if urgent {
            return "Safe move: keeps the run alive"
        }
        if hint.legalPlacements <= 2 {
            return "This placement preserves options"
        }
        return "Hint: this spot keeps the board flexible"
    }
}
