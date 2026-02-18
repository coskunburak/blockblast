import Foundation

struct ReplayFrame: Codable {
    let action: GameActionSnapshot
    let turn: Int
}

enum GameActionSnapshot: Codable {
    case placePiece(pieceID: UUID, row: Int, column: Int)
    case pause
    case resume
}
