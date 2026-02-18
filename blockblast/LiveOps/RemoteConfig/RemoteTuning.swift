import Foundation

struct GameplayRemoteConfig: Codable, Equatable {
    var classicTuning: DifficultyTuning
    var dailyTuning: DifficultyTuning
    var dailyChallenge: DailyChallengeRemoteTuning

    static let fallback = GameplayRemoteConfig(
        classicTuning: .classicDefault,
        dailyTuning: .dailyDefault,
        dailyChallenge: .default
    )
}

enum PaywallExperimentVariant: String, Codable, CaseIterable {
    case control
    case valueBundle
}

struct GameOverPaywallConfig: Codable, Equatable {
    var enabled: Bool
    var firstOfferAfterGameOvers: Int
    var repeatEveryGameOvers: Int
    var showStarterPackUpsell: Bool

    func shouldPresent(totalGameOvers: Int) -> Bool {
        guard enabled else { return false }
        guard totalGameOvers >= max(1, firstOfferAfterGameOvers) else { return false }

        if totalGameOvers == max(1, firstOfferAfterGameOvers) {
            return true
        }

        let cadence = max(1, repeatEveryGameOvers)
        return (totalGameOvers - firstOfferAfterGameOvers) % cadence == 0
    }
}

struct MonetizationRemoteConfig: Codable, Equatable {
    var interstitialEnabled: Bool
    var interstitialGameOverInterval: Int

    var rewardedContinueEnabled: Bool
    var rewardedContinueLimitPerRun: Int
    var rewardedCoinsEnabled: Bool
    var rewardedGlobalCooldownSeconds: Int

    var gameOverPaywall: GameOverPaywallConfig
    var paywallVariant: PaywallExperimentVariant
    var removeAdsBundleBonusThemeID: String?
    var starterPackEnabled: Bool
    var rewardedCoinAmount: Int

    var gameplay: GameplayRemoteConfig

    static let fallback = MonetizationRemoteConfig(
        interstitialEnabled: true,
        interstitialGameOverInterval: 2,
        rewardedContinueEnabled: true,
        rewardedContinueLimitPerRun: 1,
        rewardedCoinsEnabled: true,
        rewardedGlobalCooldownSeconds: 20,
        gameOverPaywall: GameOverPaywallConfig(
            enabled: true,
            firstOfferAfterGameOvers: 2,
            repeatEveryGameOvers: 3,
            showStarterPackUpsell: true
        ),
        paywallVariant: .control,
        removeAdsBundleBonusThemeID: "theme.grid.ember",
        starterPackEnabled: true,
        rewardedCoinAmount: RewardScheduler.rewardedAdCoins,
        gameplay: .fallback
    )
}

enum RemoteTuning {
    static func productionMonetization(for installationID: String) -> MonetizationRemoteConfig {
        let paywallVariant = ABTesting.paywallVariant(for: installationID)
        let interstitialInterval = ABTesting.interstitialGameOverInterval(for: installationID)
        let rewardCoins = ABTesting.rewardedCoinAmount(for: installationID)
        let gameplay = gameplayConfig(for: installationID)

        return MonetizationRemoteConfig(
            interstitialEnabled: true,
            interstitialGameOverInterval: interstitialInterval,
            rewardedContinueEnabled: true,
            rewardedContinueLimitPerRun: 1,
            rewardedCoinsEnabled: true,
            rewardedGlobalCooldownSeconds: 20,
            gameOverPaywall: GameOverPaywallConfig(
                enabled: true,
                firstOfferAfterGameOvers: 2,
                repeatEveryGameOvers: 3,
                showStarterPackUpsell: true
            ),
            paywallVariant: paywallVariant,
            removeAdsBundleBonusThemeID: paywallVariant == .valueBundle ? "theme.grid.ember" : nil,
            starterPackEnabled: true,
            rewardedCoinAmount: rewardCoins,
            gameplay: gameplay
        )
    }

    private static func gameplayConfig(for installationID: String) -> GameplayRemoteConfig {
        let weightProfile = ABTesting.pieceWeightProfile(for: installationID)
        let dailyTier = ABTesting.dailyDifficultyTier(for: installationID)

        let weights: PieceWeightTuning
        switch weightProfile {
        case .balanced:
            weights = .uniform
        case .comboFriendly:
            weights = .comboFriendly
        case .precision:
            weights = .precision
        }

        var classic = DifficultyTuning.classicDefault
        classic.pieceWeights = weights

        var daily = DifficultyTuning.dailyDefault
        daily.pieceWeights = weights

        let dailyTuning: DailyChallengeRemoteTuning
        switch dailyTier {
        case .relaxed:
            dailyTuning = DailyChallengeRemoteTuning(
                clearRowsTargets: [5, 6, 8],
                comboTargets: [2, 2, 3],
                scoreTargets: [700, 900, 1200],
                rewardMultiplierPercent: 90
            )
        case .standard:
            dailyTuning = .default
        case .hard:
            dailyTuning = DailyChallengeRemoteTuning(
                clearRowsTargets: [8, 10, 12],
                comboTargets: [3, 4, 5],
                scoreTargets: [1400, 1800, 2300],
                rewardMultiplierPercent: 125
            )
        }

        return GameplayRemoteConfig(
            classicTuning: classic,
            dailyTuning: daily,
            dailyChallenge: dailyTuning
        )
    }
}
