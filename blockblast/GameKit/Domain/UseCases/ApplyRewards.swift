import Foundation

enum ApplyRewards {
    static func execute(state: inout GameState, clearResult: ClearResult) -> Int {
        ComboRules.applyScoring(state: &state, clearResult: clearResult)
    }
}
