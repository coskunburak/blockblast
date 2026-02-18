import Foundation

enum AnalyticsFunnels {
    static func sessionStart(
        environment: AppEnvironment,
        appVersion: String,
        build: String
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: .sessionStart,
            params: [
                "environment": .string(environment.rawValue),
                "app_version": .string(appVersion),
                "build": .string(build)
            ]
        )
    }

    static func gameStart(mode: GameMode) -> AnalyticsEvent {
        AnalyticsEvent(
            name: .gameStart,
            params: [
                "mode": .string(mode.rawValue)
            ]
        )
    }

    static func gameOver(
        mode: GameMode,
        score: Int,
        durationSeconds: Int,
        clears: Int,
        comboMax: Int
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: .gameOver,
            params: [
                "mode": .string(mode.rawValue),
                "score": .int(score),
                "duration": .int(durationSeconds),
                "clears": .int(clears),
                "combo_max": .int(comboMax)
            ]
        )
    }

    static func adImpression(adType: String, placement: String) -> AnalyticsEvent {
        AnalyticsEvent(
            name: .adImpression,
            params: [
                "ad_type": .string(adType),
                "placement": .string(placement)
            ]
        )
    }

    static func adRewardGranted(placement: String, rewardType: String, amount: Int) -> AnalyticsEvent {
        AnalyticsEvent(
            name: .adRewardGranted,
            params: [
                "placement": .string(placement),
                "reward_type": .string(rewardType),
                "amount": .int(amount)
            ]
        )
    }

    static func paywallView(placement: PaywallPlacement, variant: PaywallExperimentVariant) -> AnalyticsEvent {
        AnalyticsEvent(
            name: .paywallView,
            params: [
                "placement": .string(placement.analyticsKey),
                "variant": .string(variant.rawValue)
            ]
        )
    }

    static func purchaseSuccess(productID: String, placement: PaywallPlacement?) -> AnalyticsEvent {
        var params: [String: AnalyticsValue] = [
            "product_id": .string(productID)
        ]
        if let placement {
            params["placement"] = .string(placement.analyticsKey)
        }
        return AnalyticsEvent(name: .purchaseSuccess, params: params)
    }

    static func purchaseFail(productID: String, placement: PaywallPlacement?, reason: String) -> AnalyticsEvent {
        var params: [String: AnalyticsValue] = [
            "product_id": .string(productID),
            "reason": .string(reason)
        ]
        if let placement {
            params["placement"] = .string(placement.analyticsKey)
        }
        return AnalyticsEvent(name: .purchaseFail, params: params)
    }

    static func dailyComplete(challengeID: String, challengeType: DailyChallengeType, rewardCoins: Int) -> AnalyticsEvent {
        AnalyticsEvent(
            name: .dailyComplete,
            params: [
                "challenge_id": .string(challengeID),
                "challenge_type": .string(challengeType.rawValue),
                "reward_coins": .int(rewardCoins)
            ]
        )
    }

    static func tutorialStep(step: String, status: String) -> AnalyticsEvent {
        AnalyticsEvent(
            name: .tutorialStep,
            params: [
                "step": .string(step),
                "status": .string(status)
            ]
        )
    }
}

private extension PaywallPlacement {
    var analyticsKey: String {
        switch self {
        case .store:
            return "store"
        case .gameOver:
            return "game_over"
        }
    }
}
