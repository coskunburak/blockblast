import Foundation

enum ComboRules {
    static func applyScoring(state: inout GameState, clearResult: ClearResult) -> Int {
        state.score.apply(
            clearedCells: clearResult.clearedCells.count,
            clearedLines: clearResult.clearedLineCount,
            tuning: state.tuning
        )
    }
}
