import Testing
@testable import blockblast

struct ScoringComboTests {
    @Test func multiLineClearGivesHigherScore() {
        let tuning = DifficultyTuning.classicDefault
        var score = ScoreState()

        let singleLine = score.apply(clearedCells: 8, clearedLines: 1, tuning: tuning)
        let multiLine = score.apply(clearedCells: 16, clearedLines: 2, tuning: tuning)

        #expect(multiLine > singleLine)
        #expect(score.total == singleLine + multiLine)
    }

    @Test func comboCarriesAcrossThreeMissesAndResetsOnFourthMiss() {
        let tuning = DifficultyTuning.classicDefault
        var score = ScoreState()

        _ = score.apply(clearedCells: 8, clearedLines: 1, tuning: tuning)
        _ = score.apply(clearedCells: 8, clearedLines: 1, tuning: tuning)
        #expect(score.comboChain == 2)
        #expect(score.streakChain == 2)

        _ = score.apply(clearedCells: 0, clearedLines: 0, tuning: tuning)
        _ = score.apply(clearedCells: 0, clearedLines: 0, tuning: tuning)
        _ = score.apply(clearedCells: 0, clearedLines: 0, tuning: tuning)
        #expect(score.comboChain == 2)
        #expect(score.streakChain == 0)

        let carriedClearGain = score.apply(clearedCells: 8, clearedLines: 1, tuning: tuning)
        #expect(score.comboChain == 3)
        #expect(carriedClearGain == 380)

        _ = score.apply(clearedCells: 0, clearedLines: 0, tuning: tuning)
        _ = score.apply(clearedCells: 0, clearedLines: 0, tuning: tuning)
        _ = score.apply(clearedCells: 0, clearedLines: 0, tuning: tuning)
        _ = score.apply(clearedCells: 0, clearedLines: 0, tuning: tuning)
        #expect(score.comboChain == 0)
    }

    @Test func scoringUsesConfiguredComboAndStreakSteps() {
        let tuning = DifficultyTuning(
            pieceSlots: 3,
            maxDot1Drought: 14,
            baseCellPoint: 10,
            baseLinePoint: 50,
            multiLineBonusStep: 80,
            comboBonusStep: 30,
            streakBonusStep: 20,
            streakStartsAt: 3
        )

        var score = ScoreState()
        let first = score.apply(clearedCells: 8, clearedLines: 1, tuning: tuning)   // 130 * x1
        let second = score.apply(clearedCells: 8, clearedLines: 1, tuning: tuning)  // 160 * x2
        let third = score.apply(clearedCells: 8, clearedLines: 1, tuning: tuning)   // 210 * x2

        #expect(first == 130)
        #expect(second == 320)
        #expect(third == 420)
        #expect(score.total == 870)
    }

    @Test func comboMultiplierEscalatesAtChains() {
        #expect(ScoreState.comboMultiplier(for: 1) == 1)
        #expect(ScoreState.comboMultiplier(for: 2) == 2)
        #expect(ScoreState.comboMultiplier(for: 4) == 3)
        #expect(ScoreState.comboMultiplier(for: 6) == 4)
    }
}
