import Foundation
import Testing
@testable import blockblast

@MainActor
struct InterstitialAdManagerTests {
    @Test func interstitialFollowsConfiguredGameOverCadence() async {
        let provider = SpyAdProvider()
        let meta = MetaProgressionStore(keyValueStore: InMemoryKeyValueStore())
        var config = MonetizationRemoteConfig.fallback
        config.interstitialGameOverInterval = 3

        let manager = InterstitialAdManager(
            provider: provider,
            meta: meta,
            configProvider: { config }
        )

        manager.warmupIfNeeded()
        _ = await manager.handleGameOver()
        _ = await manager.handleGameOver()
        let thirdShown = await manager.handleGameOver()

        #expect(thirdShown == true)
        #expect(await provider.presentInterstitialCallCount == 1)
    }

    @Test func interstitialSkippedWhenRemoveAdsEntitled() async {
        let provider = SpyAdProvider()
        let meta = MetaProgressionStore(keyValueStore: InMemoryKeyValueStore())
        meta.unlockRemoveAds()

        let manager = InterstitialAdManager(provider: provider, meta: meta)
        let shown = await manager.handleGameOver()

        #expect(shown == false)
        #expect(await provider.presentInterstitialCallCount == 0)
    }
}

actor SpyAdProvider: AdProvider {
    private(set) var rewardedReady = true
    private(set) var interstitialReady = true

    private(set) var presentInterstitialCallCount = 0

    func preloadRewardedAd() async {
        rewardedReady = true
    }

    func preloadInterstitialAd() async {
        interstitialReady = true
    }

    func isRewardedAdReady() async -> Bool {
        rewardedReady
    }

    func isInterstitialAdReady() async -> Bool {
        interstitialReady
    }

    func presentRewardedAd() async -> Bool {
        guard rewardedReady else { return false }
        rewardedReady = false
        return true
    }

    func presentInterstitialAd() async -> Bool {
        guard interstitialReady else { return false }
        presentInterstitialCallCount += 1
        interstitialReady = false
        return true
    }
}
