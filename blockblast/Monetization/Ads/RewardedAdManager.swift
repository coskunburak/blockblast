import Foundation

enum RewardedPlacement {
    case continueRun
    case bonusCoins
}

@MainActor
final class RewardedAdManager: ObservableObject {
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isReady: Bool = false
    @Published private(set) var isShowing: Bool = false

    private let provider: AdProvider
    private let configProvider: () -> MonetizationRemoteConfig
    private let canRequestAds: () -> Bool
    private let now: () -> Date
    private let analytics: AnalyticsTracking?
    private var lastWatchedAt: Date?

    init(
        provider: AdProvider = MockAdProvider(),
        configProvider: @escaping () -> MonetizationRemoteConfig = { .fallback },
        canRequestAds: @escaping () -> Bool = { true },
        now: @escaping () -> Date = Date.init,
        analytics: AnalyticsTracking? = nil
    ) {
        self.provider = provider
        self.configProvider = configProvider
        self.canRequestAds = canRequestAds
        self.now = now
        self.analytics = analytics
    }

    func warmupIfNeeded() {
        guard canRequestAds() else { return }
        guard !isLoading, !isReady else { return }
        Task { await preload() }
    }

    func canPresent(placement: RewardedPlacement, now: Date = Date()) -> Bool {
        guard canRequestAds() else { return false }

        let config = configProvider()
        switch placement {
        case .continueRun:
            guard config.rewardedContinueEnabled else { return false }
        case .bonusCoins:
            guard config.rewardedCoinsEnabled else { return false }
        }

        if cooldownRemainingSeconds(now: now) > 0 {
            return false
        }

        return isReady && !isShowing
    }

    func cooldownRemainingSeconds(now: Date = Date()) -> Int {
        guard let lastWatchedAt else { return 0 }
        let cooldown = TimeInterval(max(0, configProvider().rewardedGlobalCooldownSeconds))
        let remaining = cooldown - now.timeIntervalSince(lastWatchedAt)
        return max(0, Int(remaining.rounded(.up)))
    }

    @discardableResult
    func showAd(for placement: RewardedPlacement) async -> Bool {
        if !isReady {
            await preload()
        }
        guard canPresent(placement: placement, now: now()) else { return false }

        isShowing = true
        defer { isShowing = false }

        let watched = await provider.presentRewardedAd()
        isReady = await provider.isRewardedAdReady()
        if watched {
            lastWatchedAt = now()
            analytics?.track(
                AnalyticsFunnels.adImpression(
                    adType: "rewarded",
                    placement: placement.analyticsPlacement
                )
            )
        }
        Task { await preload() }
        return watched
    }

    @discardableResult
    func showAdAndReward(
        for placement: RewardedPlacement,
        onReward: () -> RewardGrant?
    ) async -> RewardGrant? {
        let watched = await showAd(for: placement)

        guard watched else { return nil }
        return onReward()
    }

    private func preload() async {
        guard !isLoading else { return }
        guard canRequestAds() else {
            isLoading = false
            isReady = false
            return
        }
        isLoading = true
        await provider.preloadRewardedAd()
        isReady = await provider.isRewardedAdReady()
        isLoading = false
    }
}

private extension RewardedPlacement {
    var analyticsPlacement: String {
        switch self {
        case .continueRun:
            return "continue"
        case .bonusCoins:
            return "bonus_coins"
        }
    }
}
