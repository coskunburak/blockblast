import Foundation

enum StartNewGame {
    static func makeInitialState(
        mode: GameMode,
        gridSize: Int,
        seed: UInt64?,
        remoteTuning: DifficultyTuning?
    ) -> GameState {
        let resolvedSeed = seed ?? UInt64(Date().timeIntervalSince1970)
        let tuning = DifficultyTuning.forMode(mode, remoteOverride: remoteTuning)

        return GameState.initial(
            mode: mode,
            gridSize: gridSize,
            seed: resolvedSeed,
            tuning: tuning
        )
    }
}
