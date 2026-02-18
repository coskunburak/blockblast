import Foundation

enum CheckGameOver {
    static func execute(state: inout GameState) {
        guard state.runtime == .running else { return }

        let hasLegalMove = state.upcomingPieces.contains { piece in
            PlacementRules.hasAnyValidPlacement(piece: piece, on: state.grid)
        }

        if !hasLegalMove {
            state.runtime = .gameOver
        }
    }
}
