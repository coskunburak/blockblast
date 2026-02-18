import Foundation

struct Grid: Codable, Equatable {
    let size: Int
    private(set) var filled: Set<Cell>

    init(size: Int, filled: Set<Cell> = []) {
        self.size = size
        self.filled = filled
    }

    func contains(_ cell: Cell) -> Bool {
        filled.contains(cell)
    }

    func isInside(_ cell: Cell) -> Bool {
        (0..<size).contains(cell.row) && (0..<size).contains(cell.column)
    }

    mutating func fill(_ cells: [Cell]) {
        for cell in cells {
            filled.insert(cell)
        }
    }

    mutating func clear(_ cells: Set<Cell>) {
        filled.subtract(cells)
    }

    func isRowFull(_ row: Int) -> Bool {
        (0..<size).allSatisfy { filled.contains(Cell(row: row, column: $0)) }
    }

    func isColumnFull(_ column: Int) -> Bool {
        (0..<size).allSatisfy { filled.contains(Cell(row: $0, column: column)) }
    }
}
