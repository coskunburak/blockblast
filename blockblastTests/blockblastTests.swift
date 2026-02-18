import Foundation
import Testing
@testable import blockblast

struct blockblastSmokeTests {
    @Test func reducerDispatchesInvalidMove() {
        let state = StartNewGame.makeInitialState(
            mode: .classic,
            gridSize: 8,
            seed: 42,
            remoteTuning: nil
        )
        let engine = GameEngine(initialState: state, autoSaveEnabled: false)

        let events = engine.dispatch(.placePiece(pieceID: UUID(), anchor: Cell(row: 0, column: 0)))

        #expect(events.contains(where: { event in
            if case .invalidMove = event {
                return true
            }
            return false
        }))
    }
}
