import SpriteKit
import UIKit

final class GameScene: SKScene {
    var placePieceHandler: ((Piece.ID, Cell) -> Void)?
    var boardTapHandler: ((Cell) -> Void)?

    private var currentState: GameState?
    private var lastDispatchSerial: Int = -1
    private var lastRenderedGrid: Grid?
    private var visualTheme: GameVisualTheme = .default

    private let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    private let reduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    private let gridNode = GridNode(gridSize: 8, cellSize: 32)
    private let rackNode = SKNode()
    private let dragController = DragController()
    private lazy var particles = ParticlePool(maxParticles: isLowPowerMode ? 64 : 96)
    private let ambienceNode = SKNode()
    private let fpsMonitor = FPSMonitor()
    private let effectsSystem = SceneEffectsSystem()
    private lazy var assistSystem = AssistHintSystem(isLowPowerMode: isLowPowerMode || reduceMotionEnabled)

    private var pieceNodes: [Piece.ID: PieceNode] = [:]
    private var filledCellColors: [Cell: SKColor] = [:]
    private var pendingAnchor: Cell?
    private var pendingValidDrop = false
    private var pendingHighlightedCells: Set<Cell> = []
    private var activeThemeSignature: Int?
    private var needsLayoutUpdate = true
    private var needsAuraRefresh = true
    private var hasResolvedLayout = false
    private var resolvedGridSize: Int = 0
    private var resolvedCellSize: CGFloat = 0
    private var resolvedGridPosition: CGPoint = .zero
    private var resolvedRackPosition: CGPoint = .zero

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = visualTheme.boardBackground

        addChild(gridNode)
        addChild(rackNode)
        addChild(ambienceNode)
        ambienceNode.zPosition = -250
        ambienceNode.alpha = 0.92
        gridNode.addChild(particles)
        gridNode.configurePerformance(isLowPowerMode: isLowPowerMode, reduceMotion: reduceMotionEnabled)
        assistSystem.attach(to: gridNode, scene: self)

        #if DEBUG
        fpsMonitor.attach(to: self)
        #endif

        needsLayoutUpdate = true
        needsAuraRefresh = true
        updateLayoutIfNeeded(gridSize: currentState?.grid.size ?? 8)
        refreshAuraIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        needsLayoutUpdate = true
        updateLayoutIfNeeded(gridSize: currentState?.grid.size ?? 8)
        refreshAuraIfNeeded()
        #if DEBUG
        fpsMonitor.updateLayout(for: self)
        #endif
    }

    override func update(_ currentTime: TimeInterval) {
        #if DEBUG
        fpsMonitor.tick(at: currentTime)
        #endif
    }

    func render(state: GameState, recentEvents: [GameEvent], dispatchSerial: Int, theme: GameVisualTheme) {
        currentState = state
        let themeDidChange = applyThemeIfNeeded(theme)
        updateLayoutIfNeeded(gridSize: state.grid.size)
        refreshAuraIfNeeded()

        let didDispatchChange = dispatchSerial != lastDispatchSerial
        if didDispatchChange {
            processEvents(state: state, recentEvents: recentEvents)
            lastDispatchSerial = dispatchSerial
        }

        if didDispatchChange || lastRenderedGrid != state.grid {
            gridNode.render(grid: state.grid)
            lastRenderedGrid = state.grid
        }

        syncPowerUpHighlights(for: state)

        syncRack(with: state, themeDidChange: themeDidChange)
        assistSystem.update(
            for: state,
            recentEvents: recentEvents,
            dragActive: dragController.activePieceNode != nil,
            pieceNodes: pieceNodes,
            gridNode: gridNode,
            theme: visualTheme,
            particles: particles,
            in: self
        )
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentState?.isPowerUpModeActive == true {
            return
        }

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        guard let pieceNode = pieceNode(at: location) else { return }
        dragController.beginDrag(pieceNode: pieceNode, touchLocationInScene: location)
        AudioEngine.shared.play(.pickup, minimumSpacing: 0.04)
        Task { @MainActor in
            HapticManager.shared.place()
        }
        pendingAnchor = nil
        pendingValidDrop = false
        pendingHighlightedCells.removeAll(keepingCapacity: true)
        assistSystem.clearVisuals(pieceNodes: pieceNodes)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentState?.isPowerUpModeActive == true {
            return
        }

        guard let touch = touches.first,
              let activePiece = dragController.activePieceNode,
              let pieceParent = activePiece.parent,
              let state = currentState
        else {
            return
        }

        let location = touch.location(in: self)
        dragController.updateDrag(to: location)

        let localInGrid = gridNode.convert(activePiece.position, from: pieceParent)
        let anchor = GestureMapper.anchorCell(
            for: localInGrid,
            gridOrigin: gridNode.localOrigin,
            cellSize: gridNode.cellSize
        )
        let translated = GestureMapper.translatedCells(for: activePiece.piece, anchor: anchor)

        let isValid = translated.allSatisfy { cell in
            gridNode.isInside(cell) && !state.grid.contains(cell)
        }

        let translatedSet = Set(translated)
        let shouldUpdateFeedback = pendingAnchor != anchor ||
            pendingValidDrop != isValid ||
            pendingHighlightedCells != translatedSet
        pendingAnchor = anchor
        pendingValidDrop = isValid
        guard shouldUpdateFeedback else { return }
        pendingHighlightedCells = translatedSet

        activePiece.setDragValidity(isValid)
        gridNode.showHighlight(cells: translated, isValid: isValid)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentState?.isPowerUpModeActive == true {
            handleBoardTapForPowerUp(touches)
            return
        }
        finishDrag()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentState?.isPowerUpModeActive == true {
            return
        }
        finishDrag()
    }

    private func finishDrag() {
        guard let pieceNode = dragController.endDrag() else { return }
        guard let pieceParent = pieceNode.parent else { return }

        defer {
            pendingAnchor = nil
            pendingValidDrop = false
            pendingHighlightedCells.removeAll(keepingCapacity: true)
            gridNode.clearHighlight()
        }

        guard let anchor = pendingAnchor, pendingValidDrop else {
            assistSystem.registerInvalidDrop()
            pieceNode.run(invalidShake()) { [weak pieceNode] in
                pieceNode?.returnHome(animated: true)
            }
            Task { @MainActor in
                HapticManager.shared.invalid()
            }
            AudioEngine.shared.play(.invalid)
            if let state = currentState {
                assistSystem.update(
                    for: state,
                    recentEvents: [],
                    dragActive: dragController.activePieceNode != nil,
                    pieceNodes: pieceNodes,
                    gridNode: gridNode,
                    theme: visualTheme,
                    particles: particles,
                    in: self
                )
            }
            return
        }

        assistSystem.registerValidDrop()

        let start = convert(pieceNode.position, from: pieceParent)
        let targetInScene = convert(gridNode.centerPoint(for: anchor), from: gridNode)
        let targetInParent = pieceParent.convert(targetInScene, from: self)

        effectsSystem.runPlacementTrail(
            from: start,
            to: targetInScene,
            color: visualTheme.validHighlight,
            cellSize: gridNode.cellSize,
            in: self
        )
        pieceNode.snap(to: targetInParent) { [weak self] in
            guard let self else { return }
            self.placePieceHandler?(pieceNode.piece.id, anchor)
        }

        Task { @MainActor in
            HapticManager.shared.place()
        }
        AudioEngine.shared.play(.place)
    }

    private func syncPowerUpHighlights(for state: GameState) {
        if state.isPowerUpModeActive {
            gridNode.showHighlight(cells: Array(state.validTargetPositions), isValid: true)
            return
        }

        if dragController.activePieceNode == nil {
            gridNode.clearHighlight()
        }
    }

    private func handleBoardTapForPowerUp(_ touches: Set<UITouch>) {
        guard let touch = touches.first,
              let state = currentState
        else {
            return
        }

        let location = touch.location(in: self)
        let localInGrid = gridNode.convert(location, from: self)
        let tappedCell = GestureMapper.anchorCell(
            for: localInGrid,
            gridOrigin: gridNode.localOrigin,
            cellSize: gridNode.cellSize
        )

        guard gridNode.isInside(tappedCell) else { return }
        guard state.validTargetPositions.contains(tappedCell) else { return }
        boardTapHandler?(tappedCell)
    }

    private func processEvents(state: GameState, recentEvents: [GameEvent]) {
        assistSystem.process(recentEvents: recentEvents, pieceNodes: pieceNodes)

        guard let previousGrid = lastRenderedGrid else { return }

        let placedCells = state.grid.filled.subtracting(previousGrid.filled)
        let clearedCells = previousGrid.filled.subtracting(state.grid.filled)
        let clearedLineAnchors = inferredClearedLineAnchors(previousGrid: previousGrid, placedCells: placedCells)

        if recentEvents.contains(where: {
            if case .gameStarted = $0 { return true }
            return false
        }) {
            filledCellColors.removeAll(keepingCapacity: true)
            gridNode.clearAllFilledColors()
        }

        if !clearedCells.isEmpty {
            for cell in clearedCells {
                filledCellColors.removeValue(forKey: cell)
                gridNode.clearFilledColor(for: cell)
            }
        }

        if !placedCells.isEmpty {
            let placedKind = placedPieceKind(from: recentEvents)
            let fillColor = visualTheme.boardFilledColor(for: placedKind)
            for cell in placedCells {
                filledCellColors[cell] = fillColor
                gridNode.setFilledColor(fillColor, for: cell)
            }
        }

        if !placedCells.isEmpty {
            gridNode.runPlacementPop(cells: Array(placedCells))
            effectsSystem.runPlacementPulse(
                cells: placedCells,
                color: visualTheme.validHighlight,
                gridNode: gridNode,
                particles: particles,
                isLowPowerMode: isLowPowerMode || reduceMotionEnabled
            )
        }

        if !clearedCells.isEmpty {
            let placementPalette = visualTheme.piecePalette(for: placedPieceKind(from: recentEvents))
            ClearAnimation.play(
                on: gridNode,
                cells: clearedCells,
                particles: particles,
                palette: placementPalette,
                quality: isLowPowerMode ? 0.72 : 1.0
            )
            Task { @MainActor in
                HapticManager.shared.clear()
            }
            AudioEngine.shared.play(.clear, minimumSpacing: 0.06)
        }

        if let lines = recentEvents.compactMap({ event -> Int? in
            if case let .linesCleared(count) = event { return count }
            return nil
        }).last {
            LineClearFlyoutAnimation.play(on: self, anchors: clearedLineAnchors, linesCleared: lines)

            let comboPayload = recentEvents.compactMap { event -> (multiplier: Int, chain: Int)? in
                if case let .comboTriggered(multiplier, chain) = event {
                    return (multiplier, chain)
                }
                return nil
            }.last
            let chain = comboPayload?.chain ?? max(1, state.score.comboChain)
            let multiplier = comboPayload?.multiplier ?? ScoreState.comboMultiplier(for: chain)

            ComboAnimation.play(
                on: self,
                at: comboBannerOrigin(),
                linesCleared: lines,
                comboChain: chain,
                multiplier: multiplier
            )

            if comboPayload != nil {
                effectsSystem.runComboBoardAura(
                    chain: chain,
                    gridNode: gridNode,
                    particles: particles,
                    theme: visualTheme,
                    isLowPowerMode: isLowPowerMode || reduceMotionEnabled
                )
            }

            if lines >= 2 || multiplier >= 3 || chain >= 3 {
                Task { @MainActor in
                    HapticManager.shared.bigCombo()
                }
            }

            if comboPayload != nil {
                AudioEngine.shared.play(
                    comboSoundEffect(chain: chain, multiplier: multiplier, linesCleared: lines),
                    minimumSpacing: 0.08
                )
            }
        }

        if let scoreDelta = recentEvents.compactMap({ event -> Int? in
            if case let .scoreChanged(delta, _) = event { return delta }
            return nil
        }).last, scoreDelta > 0 {
            ScorePopupAnimation.play(
                on: self,
                delta: scoreDelta,
                at: scorePopupOrigin(preferredAnchors: clearedLineAnchors)
            )
        }
    }

    private func syncRack(with state: GameState, themeDidChange: Bool) {
        let currentIDs = Set(pieceNodes.keys)
        let targetIDs = Set(state.upcomingPieces.map(\.id))

        for removedID in currentIDs.subtracting(targetIDs) {
            pieceNodes[removedID]?.removeFromParent()
            pieceNodes.removeValue(forKey: removedID)
        }

        let rackBlockSize = max(18, gridNode.cellSize * 0.64)
        let rackTargets = rackTargets(for: state.upcomingPieces, blockSize: rackBlockSize)

        for (index, piece) in state.upcomingPieces.enumerated() {
            let target = index < rackTargets.count ? rackTargets[index] : .zero
            if let existing = pieceNodes[piece.id] {
                existing.updateBlockSize(rackBlockSize)
                existing.setShimmerEnabled(!(isLowPowerMode || reduceMotionEnabled))
                if themeDidChange {
                    existing.applyTheme(visualTheme)
                    existing.applyPalette(visualTheme.piecePalette(for: piece.kind))
                }
            } else {
                let node = PieceNode(piece: piece, blockSize: rackBlockSize)
                node.applyTheme(visualTheme)
                node.applyPalette(visualTheme.piecePalette(for: piece.kind))
                node.setShimmerEnabled(!(isLowPowerMode || reduceMotionEnabled))
                rackNode.addChild(node)
                pieceNodes[piece.id] = node
                node.setScale(0.90)
                node.alpha = 0
                node.position = CGPoint(x: target.x, y: target.y - rackBlockSize * 0.30)
                let delay = SKAction.wait(forDuration: Double(index) * 0.028)
                let appear = SKAction.group([
                    SKAction.fadeIn(withDuration: 0.24),
                    SKAction.scale(to: 1.0, duration: 0.28),
                    SKAction.moveBy(x: 0, y: rackBlockSize * 0.30, duration: 0.28)
                ])
                appear.timingMode = .easeOut
                node.run(.sequence([delay, appear]))
            }
        }

        for (index, piece) in state.upcomingPieces.enumerated() {
            guard let node = pieceNodes[piece.id] else { continue }
            let target = index < rackTargets.count ? rackTargets[index] : .zero
            node.homePosition = target
            node.setDragValidity(nil)

            if dragController.activePieceNode?.piece.id != piece.id {
                node.returnHome(animated: true)
            }

            if isLowPowerMode || reduceMotionEnabled {
                IdleAnimations.stopFloat(on: node)
            } else {
                IdleAnimations.applyGentleFloat(to: node)
            }
        }
    }

    private func comboSoundEffect(chain: Int, multiplier: Int, linesCleared: Int) -> SoundEffect {
        let intensity = max(multiplier, chain + max(0, linesCleared - 1))
        switch intensity {
        case 5...:
            return .bigCombo
        case 4:
            return .comboTier3
        case 3:
            return .comboTier2
        default:
            return .comboTier1
        }
    }

    @discardableResult
    private func applyThemeIfNeeded(_ theme: GameVisualTheme) -> Bool {
        let signature = theme.renderSignature
        if activeThemeSignature == signature {
            return false
        }

        activeThemeSignature = signature
        visualTheme = theme
        backgroundColor = theme.boardBackground
        gridNode.applyTheme(theme)
        assistSystem.resetForThemeChange(pieceNodes: pieceNodes)
        needsAuraRefresh = true
        return true
    }

    private func updateLayoutIfNeeded(gridSize: Int) {
        let topPadding = max(12, size.height * 0.02)
        let rackLaneHeight = max(84, size.height * 0.15)
        let rackBottomPadding = max(12, size.height * 0.02)
        let gridToRackGap = max(18, size.height * 0.03)

        let rackCenterY = -size.height / 2 + rackBottomPadding + rackLaneHeight / 2
        let boardAreaTop = size.height / 2 - topPadding
        let boardAreaBottom = rackCenterY + rackLaneHeight / 2 + gridToRackGap
        let availableHeight = max(320, boardAreaTop - boardAreaBottom)

        let boardWidth = min(size.width * 0.985, availableHeight * 1.02)
        let resolvedGridSizeCandidate = max(1, gridSize)
        let resolvedCellSizeCandidate = max(20, floor(boardWidth / CGFloat(resolvedGridSizeCandidate)))
        let resolvedGridPositionCandidate = CGPoint(x: 0, y: (boardAreaTop + boardAreaBottom) / 2)
        let resolvedRackPositionCandidate = CGPoint(x: 0, y: rackCenterY)

        let shouldUpdateLayout = needsLayoutUpdate || !hasResolvedLayout ||
            resolvedGridSize != resolvedGridSizeCandidate ||
            abs(resolvedCellSize - resolvedCellSizeCandidate) > 0.1 ||
            distance(from: resolvedGridPosition, to: resolvedGridPositionCandidate) > 0.1 ||
            distance(from: resolvedRackPosition, to: resolvedRackPositionCandidate) > 0.1
        guard shouldUpdateLayout else { return }

        gridNode.updateLayout(gridSize: resolvedGridSizeCandidate, cellSize: resolvedCellSizeCandidate)
        gridNode.position = resolvedGridPositionCandidate
        rackNode.position = resolvedRackPositionCandidate

        resolvedGridSize = resolvedGridSizeCandidate
        resolvedCellSize = resolvedCellSizeCandidate
        resolvedGridPosition = resolvedGridPositionCandidate
        resolvedRackPosition = resolvedRackPositionCandidate
        hasResolvedLayout = true
        needsLayoutUpdate = false
        needsAuraRefresh = true
    }

    private func refreshAuraIfNeeded() {
        guard needsAuraRefresh else { return }
        effectsSystem.configureAmbientBoardAura(
            on: ambienceNode,
            gridNode: gridNode,
            theme: visualTheme,
            isLowPowerMode: isLowPowerMode || reduceMotionEnabled
        )
        needsAuraRefresh = false
    }

    private func pieceNode(at location: CGPoint) -> PieceNode? {
        let hitNodes = nodes(at: location)

        for node in hitNodes {
            if let pieceNode = node as? PieceNode {
                return pieceNode
            }
            if let pieceNode = node.parent as? PieceNode {
                return pieceNode
            }
            if let pieceNode = node.parent?.parent as? PieceNode {
                return pieceNode
            }
        }

        return nil
    }

    private func placedPieceKind(from events: [GameEvent]) -> Piece.Kind {
        guard let placedID = events.compactMap({ event -> Piece.ID? in
            if case let .piecePlaced(pieceID) = event { return pieceID }
            return nil
        }).last else {
            return .dot1
        }

        return pieceNodes[placedID]?.piece.kind ?? .dot1
    }

    private func invalidShake() -> SKAction {
        let left = SKAction.moveBy(x: -8, y: 0, duration: 0.06)
        left.timingMode = .easeInEaseOut
        let right = SKAction.moveBy(x: 16, y: 0, duration: 0.10)
        right.timingMode = .easeInEaseOut
        let center = SKAction.moveBy(x: -8, y: 0, duration: 0.08)
        center.timingMode = .easeInEaseOut

        let tilt = SKAction.sequence([
            SKAction.rotate(toAngle: -0.03, duration: 0.06, shortestUnitArc: true),
            SKAction.rotate(toAngle: 0.03, duration: 0.10, shortestUnitArc: true),
            SKAction.rotate(toAngle: 0, duration: 0.08, shortestUnitArc: true)
        ])
        tilt.timingMode = .easeInEaseOut

        return SKAction.group([
            SKAction.sequence([left, right, center]),
            tilt
        ])
    }

    private func comboBannerOrigin() -> CGPoint {
        let boardSize = CGFloat(gridNode.gridSize) * gridNode.cellSize
        return CGPoint(
            x: gridNode.position.x,
            y: gridNode.position.y - (boardSize * 0.06)
        )
    }


    private func inferredClearedLineAnchors(previousGrid: Grid, placedCells: Set<Cell>) -> [CGPoint] {
        guard !placedCells.isEmpty else { return [] }

        var postPlacementFilled = previousGrid.filled
        postPlacementFilled.formUnion(placedCells)

        let size = previousGrid.size
        var anchorsInGrid: [CGPoint] = []

        for row in 0..<size {
            let rowIsFull = (0..<size).allSatisfy { column in
                postPlacementFilled.contains(Cell(row: row, column: column))
            }
            guard rowIsFull else { continue }

            let start = gridNode.centerPoint(for: Cell(row: row, column: 0))
            let end = gridNode.centerPoint(for: Cell(row: row, column: size - 1))
            anchorsInGrid.append(CGPoint(x: (start.x + end.x) / 2, y: start.y))
        }

        for column in 0..<size {
            let columnIsFull = (0..<size).allSatisfy { row in
                postPlacementFilled.contains(Cell(row: row, column: column))
            }
            guard columnIsFull else { continue }

            let start = gridNode.centerPoint(for: Cell(row: 0, column: column))
            let end = gridNode.centerPoint(for: Cell(row: size - 1, column: column))
            anchorsInGrid.append(CGPoint(x: start.x, y: (start.y + end.y) / 2))
        }

        return anchorsInGrid.map { convert($0, from: gridNode) }
    }

    private func scorePopupOrigin(preferredAnchors: [CGPoint]) -> CGPoint {
        if let anchor = preferredAnchors.first {
            return CGPoint(
                x: anchor.x + max(42, gridNode.cellSize * 1.25),
                y: anchor.y + max(8, gridNode.cellSize * 0.28)
            )
        }

        let boardSize = CGFloat(gridNode.gridSize) * gridNode.cellSize
        return CGPoint(
            x: gridNode.position.x + (boardSize * 0.41),
            y: gridNode.position.y + (boardSize * 0.10)
        )
    }

    private func rackTargets(for pieces: [Piece], blockSize: CGFloat) -> [CGPoint] {
        guard !pieces.isEmpty else { return [] }

        let widths = pieces.map { rackVisualWidth(for: $0, blockSize: blockSize) }
        let gap = blockSize * 0.52
        let totalWidth = widths.reduce(0, +) + (gap * CGFloat(max(0, pieces.count - 1)))
        let arcLift = blockSize * 0.09

        var targets: [CGPoint] = []
        targets.reserveCapacity(pieces.count)
        var cursorX = -totalWidth / 2

        for (index, width) in widths.enumerated() {
            let centerX = cursorX + width / 2
            let normalized = pieces.count > 1
                ? (CGFloat(index) / CGFloat(pieces.count - 1)) * 2 - 1
                : 0
            let curveY = (1 - abs(normalized)) * arcLift
            targets.append(CGPoint(x: centerX, y: curveY))
            cursorX += width + gap
        }

        return targets
    }

    private func rackVisualWidth(for piece: Piece, blockSize: CGFloat) -> CGFloat {
        let span = pieceColumnSpan(for: piece)
        return (CGFloat(span) * blockSize) + (blockSize * 0.82)
    }

    private func pieceColumnSpan(for piece: Piece) -> Int {
        let minColumn = piece.blocks.map(\.column).min() ?? 0
        let maxColumn = piece.blocks.map(\.column).max() ?? 0
        return max(1, (maxColumn - minColumn) + 1)
    }

    private func distance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}
