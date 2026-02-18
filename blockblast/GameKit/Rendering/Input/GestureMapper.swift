import CoreGraphics

struct GestureMapper {
    static func anchorCell(
        for pointInGrid: CGPoint,
        gridOrigin: CGPoint,
        cellSize: CGFloat
    ) -> Cell {
        let column = Int(((pointInGrid.x - gridOrigin.x) / cellSize).rounded())
        let row = Int(((pointInGrid.y - gridOrigin.y) / cellSize).rounded())
        return Cell(row: row, column: column)
    }

    static func translatedCells(for piece: Piece, anchor: Cell) -> [Cell] {
        PlacementRules.translatedCells(for: piece, anchor: anchor)
    }
}
