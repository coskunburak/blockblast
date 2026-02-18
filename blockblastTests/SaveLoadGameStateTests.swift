import Testing
@testable import blockblast

struct SaveLoadGameStateTests {
    @Test func savesAndRestoresGameState() throws {
        let keyValue = InMemoryKeyValueStore()
        let store = SaveGameStore(keyValueStore: keyValue, key: "test.save")
        let tuning = DifficultyTuning.classicDefault
        let state = GameState.initial(mode: .classic, gridSize: 8, seed: 444, tuning: tuning)

        let engine = GameEngine(initialState: state, saveStore: store, autoSaveEnabled: true)
        guard let piece = engine.state.upcomingPieces.first else {
            Issue.record("Expected at least one piece")
            return
        }

        _ = engine.dispatch(.placePiece(pieceID: piece.id, anchor: Cell(row: 0, column: 0)))

        let restored = GameEngine(initialState: state, saveStore: store)
        let loaded = try restored.restoreLastGameIfAvailable()

        #expect(loaded == true)
        #expect(restored.state.turn == 1)
        #expect(restored.state.grid.filled.isEmpty == false)
    }
}
