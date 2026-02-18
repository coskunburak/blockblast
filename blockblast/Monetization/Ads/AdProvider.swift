import Foundation

protocol AdProvider {
    func preloadRewardedAd() async
    func preloadInterstitialAd() async

    func isRewardedAdReady() async -> Bool
    func isInterstitialAdReady() async -> Bool

    func presentRewardedAd() async -> Bool
    func presentInterstitialAd() async -> Bool
}

actor MockAdProvider: AdProvider {
    private var rewardedReady = false
    private var interstitialReady = false

    private let loadDelayNanos: UInt64
    private let presentDelayNanos: UInt64

    init(loadDelayNanos: UInt64 = 150_000_000, presentDelayNanos: UInt64 = 900_000_000) {
        self.loadDelayNanos = loadDelayNanos
        self.presentDelayNanos = presentDelayNanos
    }

    func preloadRewardedAd() async {
        if rewardedReady { return }
        try? await Task.sleep(nanoseconds: loadDelayNanos)
        rewardedReady = true
    }

    func preloadInterstitialAd() async {
        if interstitialReady { return }
        try? await Task.sleep(nanoseconds: loadDelayNanos)
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
        try? await Task.sleep(nanoseconds: presentDelayNanos)
        return true
    }

    func presentInterstitialAd() async -> Bool {
        guard interstitialReady else { return false }
        interstitialReady = false
        try? await Task.sleep(nanoseconds: presentDelayNanos / 2)
        return true
    }
}
