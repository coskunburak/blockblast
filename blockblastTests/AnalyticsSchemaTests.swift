import Testing
@testable import blockblast

struct AnalyticsSchemaTests {
    @Test func gameOverPayloadIncludesRequiredFields() {
        let event = AnalyticsFunnels.gameOver(
            mode: .classic,
            score: 1200,
            durationSeconds: 95,
            clears: 14,
            comboMax: 4
        )

        #expect(event.name == .gameOver)
        #expect(event.params["score"] == .int(1200))
        #expect(event.params["duration"] == .int(95))
        #expect(event.params["clears"] == .int(14))
        #expect(event.params["combo_max"] == .int(4))
    }

    @Test func minimumSchemaEventNamesAreAvailable() {
        let expected: [AnalyticsEventName] = [
            .sessionStart,
            .gameStart,
            .gameOver,
            .adImpression,
            .adRewardGranted,
            .paywallView,
            .purchaseSuccess,
            .purchaseFail,
            .dailyComplete,
            .tutorialStep
        ]

        #expect(expected.count == 10)
    }
}
