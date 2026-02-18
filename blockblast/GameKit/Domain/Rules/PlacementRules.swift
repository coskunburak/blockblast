import Foundation

enum PlacementRules {
    static func translatedCells(for piece: Piece, anchor: Cell) -> [Cell] {
        piece.blocks.map { block in
            Cell(row: anchor.row + block.row, column: anchor.column + block.column)
        }
    }

    static func canPlace(piece: Piece, at anchor: Cell, on grid: Grid) -> Bool {
        translatedCells(for: piece, anchor: anchor).allSatisfy { cell in
            grid.isInside(cell) && !grid.contains(cell)
        }
    }

    static func hasAnyValidPlacement(piece: Piece, on grid: Grid) -> Bool {
        for row in 0..<grid.size {
            for column in 0..<grid.size {
                if canPlace(piece: piece, at: Cell(row: row, column: column), on: grid) {
                    return true
                }
            }
        }
        return false
    }
}
