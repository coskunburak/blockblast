import Testing
@testable import blockblast

struct PieceWeightDistributionTests {
    @Test func highWeightPieceAppearsMoreFrequently() {
        let tuning = DifficultyTuning(
            pieceSlots: 3,
            maxDot1Drought: 12,
            pieceWeights: PieceWeightTuning(
                i4: 20,
                o4: 20,
                t4: 20,
                l4: 20,
                j4: 20,
                s4: 20,
                z4: 20,
                line3: 300,
                square2: 30,
                l3: 20,
                dot1: 20
            ),
            baseCellPoint: 10,
            baseLinePoint: 50,
            multiLineBonusStep: 80,
            comboBonusStep: 30,
            streakBonusStep: 20,
            streakStartsAt: 3
        )

        var bag = PieceBag(seed: 42)
        var line3Count = 0
        var dotCount = 0

        for _ in 0..<600 {
            let piece = bag.draw(tuning: tuning)
            if piece.kind == .line3 {
                line3Count += 1
            } else if piece.kind == .dot1 {
                dotCount += 1
            }
        }

        #expect(line3Count > dotCount)
    }
}
