import Foundation

struct ClearResult {
    let clearedCells: Set<Cell>
    let clearedLineCount: Int
}

enum ClearRules {
    static func evaluate(on grid: Grid) -> ClearResult {
        var rowsToClear = Set<Int>()
        var columnsToClear = Set<Int>()

        for idx in 0..<grid.size {
            if grid.isRowFull(idx) { rowsToClear.insert(idx) }
            if grid.isColumnFull(idx) { columnsToClear.insert(idx) }
        }

        var cellsToClear = Set<Cell>()
        for row in rowsToClear {
            for column in 0..<grid.size {
                cellsToClear.insert(Cell(row: row, column: column))
            }
        }
        for column in columnsToClear {
            for row in 0..<grid.size {
                cellsToClear.insert(Cell(row: row, column: column))
            }
        }

        return ClearResult(
            clearedCells: cellsToClear,
            clearedLineCount: rowsToClear.count + columnsToClear.count
        )
    }
}
