import Testing
@testable import blockblast

struct GameOverContinueTests {
    @Test func continueAfterGameOverRestoresRunningStateWithRescueRack() {
        var state = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 999,
            remoteTuning: nil
        )

        let allCells = (0..<state.grid.size).flatMap { row in
            (0..<state.grid.size).map { column in
                Cell(row: row, column: column)
            }
        }
        state.grid.fill(allCells)
        state.runtime = .gameOver

        let events = GameReducer.reduce(state: &state, action: .continueAfterGameOver)

        #expect(events.contains(.continuedFromGameOver))
        #expect(state.runtime == .running)
        #expect(state.upcomingPieces.count == state.tuning.pieceSlots)
        #expect(state.upcomingPieces.first?.kind == .dot1)
        #expect(state.grid.filled.count == allCells.count - 1)
    }
}
