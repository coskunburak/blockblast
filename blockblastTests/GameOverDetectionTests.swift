import Testing
@testable import blockblast

struct GameOverDetectionTests {
    @Test func detectsNoPossibleMove() {
        let tuning = DifficultyTuning.classicDefault
        var state = GameState.initial(mode: .classic, gridSize: 8, seed: 77, tuning: tuning)

        let allCells = (0..<8).flatMap { row in
            (0..<8).map { column in Cell(row: row, column: column) }
        }
        state.grid.fill(allCells)
        state.upcomingPieces = [Piece.make(kind: .dot1)]

        CheckGameOver.execute(state: &state)
        #expect(state.runtime == .gameOver)
    }

    @Test func staysRunningWhenAnyMoveExists() {
        let tuning = DifficultyTuning.classicDefault
        var state = GameState.initial(mode: .classic, gridSize: 8, seed: 99, tuning: tuning)

        let allExceptOne = (0..<8).flatMap { row in
            (0..<8).compactMap { column -> Cell? in
                if row == 7 && column == 7 { return nil }
                return Cell(row: row, column: column)
            }
        }

        state.grid.fill(allExceptOne)
        state.upcomingPieces = [Piece.make(kind: .dot1)]

        CheckGameOver.execute(state: &state)
        #expect(state.runtime == .running)
    }
}
