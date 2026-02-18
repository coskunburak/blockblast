import Foundation

enum GenerateNextPieces {
    static func refillIfNeeded(state: inout GameState) {
        guard state.upcomingPieces.isEmpty else { return }
        state.upcomingPieces = state.bag.drawRack(
            slotCount: state.tuning.pieceSlots,
            tuning: state.tuning,
            on: state.grid
        )

        if state.nextSpawnIsWildcard, !state.upcomingPieces.isEmpty {
            state.upcomingPieces[0] = .make(kind: .dot1)
            state.nextSpawnIsWildcard = false
        }
    }
}
