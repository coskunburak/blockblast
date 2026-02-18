import Foundation

enum PowerUpUseService {
    struct HammerResult: Equatable {
        let grid: Grid
        let didApply: Bool
    }

    static func applyHammer(on board: Grid, at position: Cell) -> HammerResult {
        guard board.isInside(position), board.contains(position) else {
            return HammerResult(grid: board, didApply: false)
        }

        var updated = board
        updated.clear([position])
        return HammerResult(grid: updated, didApply: true)
    }

    static func applyBomb(on board: Grid, center: Cell) -> Grid {
        var updated = board
        var clearedCells: Set<Cell> = []

        for row in (center.row - 1)...(center.row + 1) {
            for column in (center.column - 1)...(center.column + 1) {
                let cell = Cell(row: row, column: column)
                guard updated.isInside(cell) else { continue }
                clearedCells.insert(cell)
            }
        }

        updated.clear(clearedCells)
        return updated
    }

    static func applyRainbow(to state: inout GameState) {
        state.nextSpawnIsWildcard = true
    }
}
