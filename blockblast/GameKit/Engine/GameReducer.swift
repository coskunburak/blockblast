import Foundation

enum GameReducer {
    static func reduce(state: inout GameState, action: GameAction) -> [GameEvent] {
        switch action {
        case let .startNewGame(mode, seed):
            state = StartNewGame.makeInitialState(
                mode: mode,
                gridSize: state.grid.size,
                seed: seed,
                remoteTuning: nil
            )
            return [.gameStarted(mode: mode)]

        case let .placePiece(pieceID, anchor):
            guard state.runtime == .running else { return [] }
            guard !state.isPowerUpModeActive else { return [] }

            let placed = PlacePiece.execute(state: &state, pieceID: pieceID, anchor: anchor)
            guard placed else {
                return [.invalidMove]
            }

            var events: [GameEvent] = [.piecePlaced(pieceID: pieceID)]
            runResolvePipeline(state: &state, events: &events)
            return events

        case let .selectPowerUp(type):
            guard state.runtime == .running else { return [] }
            guard state.powerUpInventory.count(for: type) > 0 else { return [] }

            let mode = PowerUpMode(powerUpType: type)
            if mode == .rainbow {
                guard state.powerUpInventory.use(type: .rainbow) else { return [] }
                PowerUpUseService.applyRainbow(to: &state)
                exitPowerUpMode(state: &state)
                return [
                    .powerUpSelected(.rainbow),
                    .powerUpApplied(.rainbow),
                    .inventoryUpdated(.rainbow, newCount: state.powerUpInventory.count(for: .rainbow))
                ]
            }

            enterPowerUpMode(mode, state: &state)
            return [.powerUpSelected(type)]

        case let .tapBoard(position):
            guard state.runtime == .running else { return [] }
            guard state.isPowerUpModeActive else { return [] }

            switch state.interactionState.selectedPowerUp {
            case .none, .rainbow:
                return []

            case .hammer:
                let result = PowerUpUseService.applyHammer(on: state.grid, at: position)
                guard result.didApply else { return [] }
                guard state.powerUpInventory.use(type: .hammer) else { return [] }

                state.grid = result.grid
                var events: [GameEvent] = [
                    .powerUpApplied(.hammer),
                    .inventoryUpdated(.hammer, newCount: state.powerUpInventory.count(for: .hammer))
                ]
                runResolvePipeline(state: &state, events: &events)
                exitPowerUpMode(state: &state)
                return events

            case .bomb:
                guard state.grid.isInside(position) else { return [] }
                guard state.powerUpInventory.use(type: .bomb) else { return [] }

                state.grid = PowerUpUseService.applyBomb(on: state.grid, center: position)
                var events: [GameEvent] = [
                    .powerUpApplied(.bomb),
                    .inventoryUpdated(.bomb, newCount: state.powerUpInventory.count(for: .bomb))
                ]
                runResolvePipeline(state: &state, events: &events)
                exitPowerUpMode(state: &state)
                return events
            }

        case .cancelPowerUpSelection:
            guard state.isPowerUpModeActive else { return [] }
            exitPowerUpMode(state: &state)
            return [.powerUpCancelled]

        case .pause:
            guard state.runtime == .running else { return [] }
            state.runtime = .paused
            return [.paused]

        case .resume:
            guard state.runtime == .paused else { return [] }
            state.runtime = .running
            return [.resumed]

        case .continueAfterGameOver:
            guard state.runtime == .gameOver else { return [] }

            state.runtime = .running
            state.upcomingPieces = makeRescueRack(
                slotCount: state.tuning.pieceSlots,
                tuning: state.tuning,
                grid: state.grid,
                bag: &state.bag
            )

            if !hasAnyLegalMove(pieces: state.upcomingPieces, on: state.grid),
               let rescueCell = rescueCellToClear(in: state.grid) {
                state.grid.clear([rescueCell])
            }

            CheckGameOver.execute(state: &state)
            guard state.runtime == .running else { return [] }
            return [.continuedFromGameOver]
        }
    }

    private static func runResolvePipeline(state: inout GameState, events: inout [GameEvent]) {
        let clearResult = EvaluateClears.execute(state: &state)
        if clearResult.clearedLineCount > 0 {
            events.append(.linesCleared(count: clearResult.clearedLineCount))
        }

        let scoreDelta = ApplyRewards.execute(state: &state, clearResult: clearResult)
        if scoreDelta > 0 {
            events.append(.scoreChanged(delta: scoreDelta, total: state.score.total))
        }

        state.comboTracker.update(linesClearedInMove: clearResult.clearedLineCount)
        events.append(.comboChanged(state.comboTracker.currentCombo))

        if clearResult.clearedLineCount > 0 {
            let multiplier = ScoreState.comboMultiplier(for: state.score.comboChain)
            if multiplier > 1 {
                events.append(.comboTriggered(multiplier: multiplier, chain: state.score.comboChain))
            }
        }

        let earnedPowerUps = PowerUpEarningService.earnedPowerUps(
            linesClearedInMove: clearResult.clearedLineCount,
            comboState: state.comboTracker
        )
        for powerUp in earnedPowerUps {
            if state.powerUpInventory.add(type: powerUp) {
                events.append(.powerUpEarned(powerUp, newCount: state.powerUpInventory.count(for: powerUp)))
            } else {
                events.append(.powerUpInventoryFull(powerUp))
            }
        }

        GenerateNextPieces.refillIfNeeded(state: &state)
        CheckGameOver.execute(state: &state)

        if state.runtime == .gameOver {
            events.append(.gameOver(finalScore: state.score.total))
        }
    }

    private static func enterPowerUpMode(_ mode: PowerUpMode, state: inout GameState) {
        state.interactionState.selectedPowerUp = mode
        state.interactionState.isPowerUpActive = mode != .none
    }

    private static func exitPowerUpMode(state: inout GameState) {
        state.interactionState.selectedPowerUp = .none
        state.interactionState.isPowerUpActive = false
    }

    private static func hasAnyLegalMove(pieces: [Piece], on grid: Grid) -> Bool {
        pieces.contains { piece in
            PlacementRules.hasAnyValidPlacement(piece: piece, on: grid)
        }
    }

    private static func makeRescueRack(
        slotCount: Int,
        tuning: DifficultyTuning,
        grid: Grid,
        bag: inout PieceBag
    ) -> [Piece] {
        guard slotCount > 0 else { return [] }

        var rack: [Piece] = [.make(kind: .dot1)]
        if slotCount > 1 {
            let supportPieces = bag.drawRack(
                slotCount: slotCount - 1,
                tuning: tuning,
                on: grid
            )
            rack.append(contentsOf: supportPieces)
        }
        return rack
    }

    private static func rescueCellToClear(in grid: Grid) -> Cell? {
        guard !grid.filled.isEmpty else { return nil }

        let center = Cell(row: grid.size / 2, column: grid.size / 2)
        if grid.contains(center) {
            return center
        }
        return grid.filled.first
    }
}
