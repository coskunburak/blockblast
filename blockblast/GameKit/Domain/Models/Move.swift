import Foundation

struct Move: Hashable, Codable {
    let pieceID: Piece.ID
    let anchor: Cell
}
