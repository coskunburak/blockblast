import Foundation

struct GameResultSummary: Identifiable, Hashable {
    let id: UUID
    let mode: GameMode
    let score: Int
    let turn: Int
    let clears: Int
    let comboMax: Int
    let durationSeconds: Int
    let rewardedContinues: Int
    let date: Date

    init(
        id: UUID = UUID(),
        mode: GameMode,
        score: Int,
        turn: Int,
        clears: Int,
        comboMax: Int,
        durationSeconds: Int,
        rewardedContinues: Int,
        date: Date = Date()
    ) {
        self.id = id
        self.mode = mode
        self.score = score
        self.turn = turn
        self.clears = clears
        self.comboMax = comboMax
        self.durationSeconds = durationSeconds
        self.rewardedContinues = rewardedContinues
        self.date = date
    }
}
