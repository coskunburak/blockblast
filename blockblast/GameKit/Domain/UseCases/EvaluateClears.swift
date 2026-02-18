import Foundation

enum EvaluateClears {
    static func execute(state: inout GameState) -> ClearResult {
        let clearResult = ClearRules.evaluate(on: state.grid)
        if !clearResult.clearedCells.isEmpty {
            state.grid.clear(clearResult.clearedCells)
        }
        return clearResult
    }
}
