import Foundation

@MainActor
final class InterstitialAdManager: ObservableObject {
    @Published private(set) var isReady: Bool = false
    @Published private(set) var isShowing: Bool = false

    private let provider: AdProvider
    private let meta: MetaProgressionStore
    private let configProvider: () -> MonetizationRemoteConfig
    private let canRequestAds: () -> Bool
    private let analytics: AnalyticsTracking?

    private var gameOversSinceLastInterstitial: Int = 0

    init(
        provider: AdProvider = MockAdProvider(),
        meta: MetaProgressionStore,
        configProvider: @escaping () -> MonetizationRemoteConfig = { .fallback },
        canRequestAds: @escaping () -> Bool = { true },
        analytics: AnalyticsTracking? = nil
    ) {
        self.provider = provider
        self.meta = meta
        self.configProvider = configProvider
        self.canRequestAds = canRequestAds
        self.analytics = analytics
    }

    func warmupIfNeeded() {
        guard shouldServeInterstitials else {
            isReady = false
            return
        }
        Task {
            if !(await provider.isInterstitialAdReady()) {
                await provider.preloadInterstitialAd()
            }
            isReady = await provider.isInterstitialAdReady()
        }
    }

    @discardableResult
    func handleGameOver() async -> Bool {
        guard shouldServeInterstitials else { return false }

        gameOversSinceLastInterstitial += 1
        let frequency = max(1, configProvider().interstitialGameOverInterval)
        guard gameOversSinceLastInterstitial >= frequency else {
            warmupIfNeeded()
            return false
        }

        if !isReady {
            await provider.preloadInterstitialAd()
            isReady = await provider.isInterstitialAdReady()
        }

        guard isReady else { return false }

        isShowing = true
        defer { isShowing = false }

        let shown = await provider.presentInterstitialAd()
        isReady = await provider.isInterstitialAdReady()
        gameOversSinceLastInterstitial = shown ? 0 : gameOversSinceLastInterstitial

        if shown {
            analytics?.track(
                AnalyticsFunnels.adImpression(
                    adType: "interstitial",
                    placement: "game_over"
                )
            )
        }

        warmupIfNeeded()
        return shown
    }

    private var shouldServeInterstitials: Bool {
        let config = configProvider()
        return config.interstitialEnabled && !meta.removeAdsEnabled && canRequestAds()
    }
}
