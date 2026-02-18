import Testing
@testable import blockblast

struct ClearRulesTests {
    @Test func clearsCompletedRowAndColumn() {
        var grid = Grid(size: 8)

        let fullRow = (0..<8).map { Cell(row: 3, column: $0) }
        let fullColumn = (0..<8).map { Cell(row: $0, column: 5) }
        grid.fill(fullRow + fullColumn)

        let result = ClearRules.evaluate(on: grid)

        #expect(result.clearedLineCount == 2)
        #expect(result.clearedCells.count == 15)
        #expect(result.clearedCells.contains(Cell(row: 3, column: 5)))
    }
}
