import Testing
@testable import blockblast

struct GameReducerFlowTests {
    @Test func validPlacementEmitsEventAndConsumesRackPiece() {
        let initial = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 777,
            remoteTuning: nil
        )
        let engine = GameEngine(initialState: initial, autoSaveEnabled: false)
        let firstPiece = engine.state.upcomingPieces[0]

        let events = engine.dispatch(.placePiece(pieceID: firstPiece.id, anchor: Cell(row: 0, column: 0)))

        #expect(events.contains(.piecePlaced(pieceID: firstPiece.id)))
        #expect(engine.state.upcomingPieces.count == initial.tuning.pieceSlots - 1)
        #expect(engine.state.turn == 1)
    }

    @Test func rackRefillsOnlyAfterAllPiecesAreUsed() {
        var initial = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 801,
            remoteTuning: nil
        )
        initial.upcomingPieces = [.make(kind: .dot1), .make(kind: .dot1), .make(kind: .dot1)]
        let engine = GameEngine(initialState: initial, autoSaveEnabled: false)

        for index in 0..<3 {
            guard let piece = engine.state.upcomingPieces.first else {
                Issue.record("Expected a rack piece before move \(index)")
                return
            }
            _ = engine.dispatch(.placePiece(pieceID: piece.id, anchor: Cell(row: 0, column: index)))
        }

        #expect(engine.state.upcomingPieces.count == engine.state.tuning.pieceSlots)
        #expect(engine.state.turn == 3)
    }

    @Test func pauseAndResumeTransitionsRuntimeState() {
        var state = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 5,
            remoteTuning: nil
        )

        let pauseEvents = GameReducer.reduce(state: &state, action: .pause)
        #expect(state.runtime == .paused)
        #expect(pauseEvents.contains(.paused))

        let resumeEvents = GameReducer.reduce(state: &state, action: .resume)
        #expect(state.runtime == .running)
        #expect(resumeEvents.contains(.resumed))
    }

    @Test func restartCreatesFreshRunAndResetsTurn() {
        let initial = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 1234,
            remoteTuning: nil
        )
        let engine = GameEngine(initialState: initial, autoSaveEnabled: false)
        let firstPiece = engine.state.upcomingPieces[0]

        _ = engine.dispatch(.placePiece(pieceID: firstPiece.id, anchor: Cell(row: 0, column: 0)))
        #expect(engine.state.turn == 1)

        let restartEvents = engine.dispatch(.startNewGame(mode: .classic, seed: nil))
        #expect(restartEvents.contains(.gameStarted(mode: .classic)))
        #expect(engine.state.turn == 0)
        #expect(engine.state.runtime == .running)
        #expect(engine.state.upcomingPieces.count == engine.state.tuning.pieceSlots)
    }

    @Test func consecutiveExplosionsEmitComboMultiplierEvent() {
        var initial = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 123,
            remoteTuning: nil
        )

        // Leave one hole at the end of row 0 and row 1 for back-to-back clears.
        let nearFullRows = (0..<7).flatMap { column in
            [Cell(row: 0, column: column), Cell(row: 1, column: column)]
        }
        initial.grid.fill(nearFullRows)
        initial.upcomingPieces = [.make(kind: .dot1), .make(kind: .dot1), .make(kind: .dot1)]

        let engine = GameEngine(initialState: initial, autoSaveEnabled: false)

        let firstPiece = engine.state.upcomingPieces[0]
        let firstEvents = engine.dispatch(.placePiece(pieceID: firstPiece.id, anchor: Cell(row: 0, column: 7)))
        #expect(firstEvents.contains(.linesCleared(count: 1)))
        #expect(!firstEvents.contains(where: {
            if case .comboTriggered = $0 { return true }
            return false
        }))

        let secondPiece = engine.state.upcomingPieces[0]
        let secondEvents = engine.dispatch(.placePiece(pieceID: secondPiece.id, anchor: Cell(row: 1, column: 7)))
        #expect(secondEvents.contains(.linesCleared(count: 1)))
        #expect(secondEvents.contains(.comboTriggered(multiplier: 2, chain: 2)))
    }

    @Test func moveResolutionEmitsComboAndPowerUpEvents() {
        var initial = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 918,
            remoteTuning: nil
        )

        let nearFullRows = (0..<7).flatMap { column in
            [Cell(row: 0, column: column), Cell(row: 1, column: column), Cell(row: 2, column: column)]
        }
        initial.grid.fill(nearFullRows)
        initial.upcomingPieces = [.make(kind: .dot1), .make(kind: .dot1), .make(kind: .dot1)]

        let engine = GameEngine(initialState: initial, autoSaveEnabled: false)

        let first = engine.state.upcomingPieces[0]
        let firstEvents = engine.dispatch(.placePiece(pieceID: first.id, anchor: Cell(row: 0, column: 7)))
        #expect(firstEvents.contains(.comboChanged(1)))

        let second = engine.state.upcomingPieces[0]
        let secondEvents = engine.dispatch(.placePiece(pieceID: second.id, anchor: Cell(row: 1, column: 7)))
        #expect(secondEvents.contains(.comboChanged(2)))

        let third = engine.state.upcomingPieces[0]
        let thirdEvents = engine.dispatch(.placePiece(pieceID: third.id, anchor: Cell(row: 2, column: 7)))
        #expect(thirdEvents.contains(.comboChanged(3)))
        #expect(thirdEvents.contains(.powerUpEarned(.hammer, newCount: 1)))
        #expect(engine.state.powerUpInventory.count(for: .hammer) == 1)
    }

    @Test func fullInventoryEmitsPowerUpFullEvent() {
        var initial = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 414,
            remoteTuning: nil
        )

        let nearFullRow = (0..<7).map { Cell(row: 0, column: $0) }
        initial.grid.fill(nearFullRow)
        initial.upcomingPieces = [.make(kind: .dot1), .make(kind: .dot1), .make(kind: .dot1)]

        // Preload combo so the next clear lands exactly on combo 3.
        initial.comboTracker = ComboTracker(currentCombo: 2)
        _ = initial.score.apply(clearedCells: 8, clearedLines: 1, tuning: initial.tuning)
        _ = initial.score.apply(clearedCells: 8, clearedLines: 1, tuning: initial.tuning)

        // Fill hammer inventory to cap.
        let firstAdd = initial.powerUpInventory.add(type: .hammer)
        let secondAdd = initial.powerUpInventory.add(type: .hammer)
        let thirdAdd = initial.powerUpInventory.add(type: .hammer)
        #expect(firstAdd)
        #expect(secondAdd)
        #expect(thirdAdd)

        let engine = GameEngine(initialState: initial, autoSaveEnabled: false)
        let piece = engine.state.upcomingPieces[0]
        let events = engine.dispatch(.placePiece(pieceID: piece.id, anchor: Cell(row: 0, column: 7)))

        #expect(events.contains(.powerUpInventoryFull(.hammer)))
        #expect(engine.state.powerUpInventory.count(for: .hammer) == PowerUpInventory.hammerCap)
    }

    @Test func clearAfterThreeMovesStillCountsAsCombo() {
        var initial = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 771,
            remoteTuning: nil
        )

        // Setup row 0 and row 4 to be completed in separate clears.
        initial.grid.fill((0..<7).map { Cell(row: 0, column: $0) })
        initial.grid.fill((0..<7).map { Cell(row: 4, column: $0) })
        initial.upcomingPieces = [
            .make(kind: .dot1), // clear row 0
            .make(kind: .dot1), // miss move 1
            .make(kind: .dot1), // miss move 2
            .make(kind: .dot1), // miss move 3
            .make(kind: .dot1)  // clear row 4
        ]

        let engine = GameEngine(initialState: initial, autoSaveEnabled: false)

        let firstClear = engine.state.upcomingPieces[0]
        let firstEvents = engine.dispatch(.placePiece(pieceID: firstClear.id, anchor: Cell(row: 0, column: 7)))
        #expect(firstEvents.contains(.comboChanged(1)))

        let missOne = engine.state.upcomingPieces[0]
        _ = engine.dispatch(.placePiece(pieceID: missOne.id, anchor: Cell(row: 7, column: 7)))

        let missTwo = engine.state.upcomingPieces[0]
        _ = engine.dispatch(.placePiece(pieceID: missTwo.id, anchor: Cell(row: 7, column: 6)))

        let missThree = engine.state.upcomingPieces[0]
        _ = engine.dispatch(.placePiece(pieceID: missThree.id, anchor: Cell(row: 7, column: 5)))

        let delayedClear = engine.state.upcomingPieces[0]
        let delayedEvents = engine.dispatch(.placePiece(pieceID: delayedClear.id, anchor: Cell(row: 4, column: 7)))

        #expect(delayedEvents.contains(.comboChanged(2)))
        #expect(delayedEvents.contains(.comboTriggered(multiplier: 2, chain: 2)))
    }
}
