import Testing
@testable import blockblast

struct PieceBagFairnessTests {
    @Test func dotPieceDroughtIsBoundedByTuning() {
        let tuning = DifficultyTuning(
            pieceSlots: 3,
            maxDot1Drought: 8,
            baseCellPoint: 10,
            baseLinePoint: 50,
            multiLineBonusStep: 80,
            comboBonusStep: 30,
            streakBonusStep: 20,
            streakStartsAt: 3
        )

        var bag = PieceBag(seed: 12345)
        var drought = 0
        var worstDrought = 0

        for _ in 0..<500 {
            let piece = bag.draw(tuning: tuning)
            if piece.kind == .dot1 {
                worstDrought = max(worstDrought, drought)
                drought = 0
            } else {
                drought += 1
            }
        }

        #expect(worstDrought <= tuning.maxDot1Drought)
    }
}
