import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var title = "Block Blast"
    @Published private(set) var subtitle = "Place, clear, combo."

    @Published private(set) var coins: Int = 0
    @Published private(set) var streak: Int = 1
    @Published private(set) var challenges: [DailyChallengeProgress] = []
    @Published private(set) var canClaimStreakReward: Bool = false
    @Published private(set) var rewardedAdRemainingText: String = "Ready"
    @Published private(set) var dailyResetRemainingText: String = "--:--:--"
    @Published private(set) var canClaimRewardedAd: Bool = false
    @Published var rewardToast: String?

    private let meta: MetaProgressionStore
    private let rewardedAds: RewardedAdManager
    private let analytics: AnalyticsTracking?
    private var cancellables: Set<AnyCancellable> = []
    private var timer: Timer?

    init(meta: MetaProgressionStore, rewardedAds: RewardedAdManager, analytics: AnalyticsTracking? = nil) {
        self.meta = meta
        self.rewardedAds = rewardedAds
        self.analytics = analytics
        bindMeta()
        refresh()
        startTimer()
        rewardedAds.warmupIfNeeded()
    }

    deinit {
        timer?.invalidate()
    }

    var rewardedAdCoinAmount: Int {
        meta.rewardedAdCoinAmount
    }

    func claimStreakReward() {
        guard let grant = meta.claimStreakReward() else { return }
        rewardToast = "+\(grant.coins) coins (streak)"
        refresh()
    }

    func claimDailyReward(challengeID: String) {
        guard let grant = meta.claimDailyChallenge(challengeID) else { return }
        rewardToast = "+\(grant.coins) coins (daily)"
        if let completed = meta.challenges.first(where: { $0.id == challengeID }) {
            analytics?.track(
                AnalyticsFunnels.dailyComplete(
                    challengeID: challengeID,
                    challengeType: completed.definition.type,
                    rewardCoins: grant.coins
                )
            )
        }
        refresh()
    }

    func claimRewardedAd() {
        guard canClaimRewardedAd else { return }
        Task {
            let grant = await rewardedAds.showAdAndReward(for: .bonusCoins) {
                self.meta.claimRewardedAd()
            }
            guard let grant else { return }
            await MainActor.run {
                rewardToast = "+\(grant.coins) coins (rewarded ad)"
                analytics?.track(
                    AnalyticsFunnels.adRewardGranted(
                        placement: "home_bonus_coins",
                        rewardType: "coins",
                        amount: grant.coins
                    )
                )
                refresh()
            }
        }
    }

    private func bindMeta() {
        meta.objectWillChange
            .sink { [weak self] in
                self?.refresh()
            }
            .store(in: &cancellables)

        rewardedAds.objectWillChange
            .sink { [weak self] in
                self?.refreshRewardedAdLabel()
            }
            .store(in: &cancellables)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshRewardedAdLabel()
            }
        }
    }

    private func refresh() {
        coins = meta.coins
        streak = meta.streak
        challenges = meta.challenges
        canClaimStreakReward = meta.canClaimStreakReward
        refreshRewardedAdLabel()
        refreshDailyResetLabel()
    }

    private func refreshRewardedAdLabel() {
        let economyRemaining = Int(meta.timeUntilRewardedAdReady().rounded(.up))
        let adCooldownRemaining = rewardedAds.cooldownRemainingSeconds()
        if rewardedAds.isShowing {
            rewardedAdRemainingText = "Watching..."
            canClaimRewardedAd = false
            return
        }
        if rewardedAds.isLoading {
            rewardedAdRemainingText = "Loading..."
            canClaimRewardedAd = false
            return
        }
        if economyRemaining == 0 && adCooldownRemaining == 0 && rewardedAds.isReady {
            rewardedAdRemainingText = "Ready"
            canClaimRewardedAd = true
        } else {
            let remaining = max(economyRemaining, adCooldownRemaining, rewardedAds.isReady ? 0 : 1)
            let mins = remaining / 60
            let secs = remaining % 60
            rewardedAdRemainingText = remaining > 0 ? String(format: "%d:%02d", mins, secs) : "Loading..."
            canClaimRewardedAd = false
        }
    }

    private func refreshDailyResetLabel() {
        let remaining = Int(meta.timeUntilDailyReset().rounded(.up))
        let hours = remaining / 3600
        let mins = (remaining % 3600) / 60
        let secs = remaining % 60
        dailyResetRemainingText = String(format: "%02d:%02d:%02d", hours, mins, secs)
    }
}
