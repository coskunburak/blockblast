import Foundation

enum PlacePiece {
    static func execute(state: inout GameState, pieceID: Piece.ID, anchor: Cell) -> Bool {
        guard let index = state.upcomingPieces.firstIndex(where: { $0.id == pieceID }) else {
            return false
        }

        let piece = state.upcomingPieces[index]
        guard PlacementRules.canPlace(piece: piece, at: anchor, on: state.grid) else {
            return false
        }

        let translated = PlacementRules.translatedCells(for: piece, anchor: anchor)
        state.grid.fill(translated)
        state.upcomingPieces.remove(at: index)
        state.lastMove = Move(pieceID: pieceID, anchor: anchor)
        state.turn += 1

        return true
    }
}
