import Foundation
import SwiftUI

final class MetaProgressionStore: ObservableObject {
    @Published private(set) var profile: PlayerMetaProfile

    let catalog: ShopCatalog

    private let keyValueStore: KeyValueStore
    private let calendar: Calendar
    private let storageKey = "com.blockblast.meta.profile"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let rewardedAdCoinsProvider: () -> Int
    private let dailyChallengeTuningProvider: () -> DailyChallengeRemoteTuning

    private var comboMilestonesClaimedThisRun: Set<Int> = []

    init(
        keyValueStore: KeyValueStore = UserDefaultsStore(),
        catalog: ShopCatalog = .default,
        calendar: Calendar = .current,
        rewardedAdCoinsProvider: @escaping () -> Int = { RewardScheduler.rewardedAdCoins },
        dailyChallengeTuningProvider: @escaping () -> DailyChallengeRemoteTuning = { .default },
        now: Date = Date()
    ) {
        self.keyValueStore = keyValueStore
        self.catalog = catalog
        self.calendar = calendar
        self.rewardedAdCoinsProvider = rewardedAdCoinsProvider
        self.dailyChallengeTuningProvider = dailyChallengeTuningProvider

        if let data = keyValueStore.data(forKey: storageKey),
           let decoded = try? decoder.decode(PlayerMetaProfile.self, from: data) {
            profile = decoded.sanitized(using: catalog)
        } else {
            let dayStart = calendar.startOfDay(for: now)
            profile = PlayerMetaProfile.defaultProfile(
                catalog: catalog,
                dayStart: dayStart,
                now: now,
                dailyChallengeTuning: dailyChallengeTuningProvider()
            )
        }

        refreshDailyIfNeeded(now: now)
        saveProfile()
    }

    var coins: Int { profile.wallet.coins }
    var removeAdsEnabled: Bool { profile.removeAdsEntitlement }
    var starterPackPurchased: Bool { profile.starterPackPurchased }
    var rewardedAdCoinAmount: Int { max(1, rewardedAdCoinsProvider()) }
    var challenges: [DailyChallengeProgress] { profile.daily.challenges }
    var streak: Int { profile.daily.streak }
    var canClaimStreakReward: Bool {
        let today = profile.daily.dayStart
        return profile.daily.lastActiveDayStart == today && profile.daily.streakClaimedForDayStart != today
    }
    var equippedBlockThemeID: String { profile.equippedBlockThemeID }
    var equippedGridThemeID: String { profile.equippedGridThemeID }
    var shouldShowAhaCoachmark: Bool { !profile.onboarding.ahaMomentUnlocked }

    func beginRun() {
        comboMilestonesClaimedThisRun.removeAll()
    }

    @discardableResult
    func markAhaMoment() -> Bool {
        guard !profile.onboarding.ahaMomentUnlocked else { return false }
        profile.onboarding.ahaMomentUnlocked = true
        saveAndNotify()
        return true
    }

    @discardableResult
    func processGameplay(previous: GameState, current: GameState, events: [GameEvent], now: Date = Date()) -> [RewardGrant] {
        refreshDailyIfNeeded(now: now)
        markDailyActive(now: now)

        var grants: [RewardGrant] = []

        let rowsCleared = events.reduce(into: 0) { partial, event in
            if case let .linesCleared(count) = event {
                partial += count
            }
        }
        applyDailyProgress(type: .clearRows, delta: rowsCleared, now: now)

        let comboDelta = max(0, current.score.comboChain - previous.score.comboChain)
        applyDailyProgress(type: .makeCombos, delta: comboDelta, now: now)

        let scoreDelta = max(0, current.score.total - previous.score.total)
        applyDailyProgress(type: .reachScore, delta: scoreDelta, now: now)

        for milestone in RewardScheduler.comboMilestones where current.score.comboChain >= milestone {
            if comboMilestonesClaimedThisRun.contains(milestone) {
                continue
            }
            let coins = RewardScheduler.comboMilestoneCoins(for: milestone)
            guard coins > 0 else { continue }
            comboMilestonesClaimedThisRun.insert(milestone)
            profile.wallet.credit(coins)
            grants.append(RewardGrant(source: .comboMilestone, coins: coins, reason: "Combo x\(milestone) milestone"))
        }

        if current.runtime == .gameOver {
            comboMilestonesClaimedThisRun.removeAll()
        }

        if rowsCleared > 0, markAhaMoment() {
            let ahaCoins = RewardScheduler.onboardingAhaCoins
            profile.wallet.credit(ahaCoins)
            grants.append(
                RewardGrant(
                    source: .onboardingAha,
                    coins: ahaCoins,
                    reason: "First clear bonus"
                )
            )
        }

        if !grants.isEmpty || rowsCleared > 0 || comboDelta > 0 || scoreDelta > 0 {
            saveAndNotify()
        }

        return grants
    }

    @discardableResult
    func claimDailyChallenge(_ challengeID: String, now: Date = Date()) -> RewardGrant? {
        refreshDailyIfNeeded(now: now)

        guard let index = profile.daily.challenges.firstIndex(where: { $0.id == challengeID }),
              profile.daily.challenges[index].isClaimable
        else {
            return nil
        }

        let reward = profile.daily.challenges[index].definition.rewardCoins
        profile.daily.challenges[index].claimedAt = now
        profile.wallet.credit(reward)

        let grant = RewardGrant(
            source: .dailyChallenge,
            coins: reward,
            reason: profile.daily.challenges[index].definition.title
        )
        saveAndNotify()
        return grant
    }

    @discardableResult
    func claimStreakReward(now: Date = Date()) -> RewardGrant? {
        refreshDailyIfNeeded(now: now)
        markDailyActive(now: now)

        let today = profile.daily.dayStart
        guard canClaimStreakReward else { return nil }

        let reward = RewardScheduler.streakCoins(streak: profile.daily.streak)
        profile.daily.streakClaimedForDayStart = today
        profile.wallet.credit(reward)

        let grant = RewardGrant(
            source: .dailyStreak,
            coins: reward,
            reason: "Day \(profile.daily.streak) streak"
        )
        saveAndNotify()
        return grant
    }

    @discardableResult
    func claimRewardedAd(now: Date = Date()) -> RewardGrant? {
        refreshDailyIfNeeded(now: now)

        if let next = profile.nextRewardedAdAt, now < next {
            return nil
        }

        let reward = rewardedAdCoinAmount
        profile.wallet.credit(reward)
        profile.nextRewardedAdAt = now.addingTimeInterval(300)

        let grant = RewardGrant(source: .rewardedAd, coins: reward, reason: "Rewarded ad")
        saveAndNotify()
        return grant
    }

    @discardableResult
    func purchaseTheme(themeID: String) -> PurchaseThemeResult {
        guard let theme = catalog.theme(id: themeID) else {
            return .notFound
        }

        if profile.ownedThemeIDs.contains(themeID) {
            equipTheme(themeID: themeID)
            return .alreadyOwned
        }

        guard profile.wallet.spend(theme.priceCoins) else {
            return .insufficientFunds(required: theme.priceCoins)
        }

        profile.ownedThemeIDs.insert(themeID)
        equipTheme(themeID: themeID)
        saveAndNotify()
        return .purchased(cost: theme.priceCoins)
    }

    func equipTheme(themeID: String) {
        guard profile.ownedThemeIDs.contains(themeID),
              let theme = catalog.theme(id: themeID) else {
            return
        }

        switch theme.category {
        case .block:
            profile.equippedBlockThemeID = themeID
        case .grid:
            profile.equippedGridThemeID = themeID
        }

        saveAndNotify()
    }

    func unlockRemoveAds() {
        guard !profile.removeAdsEntitlement else { return }
        profile.removeAdsEntitlement = true
        saveAndNotify()
    }

    @discardableResult
    func applyStarterPack(product: StoreProduct = Products.starterPack) -> Bool {
        guard !profile.starterPackPurchased else { return false }

        profile.starterPackPurchased = true

        if product.coinGrant > 0 {
            profile.wallet.credit(product.coinGrant)
        }

        if let themeID = product.bonusThemeID,
           let theme = catalog.theme(id: themeID) {
            profile.ownedThemeIDs.insert(themeID)
            switch theme.category {
            case .block:
                profile.equippedBlockThemeID = themeID
            case .grid:
                profile.equippedGridThemeID = themeID
            }
        }

        saveAndNotify()
        return true
    }

    func grantTheme(themeID: String, autoEquip: Bool = false) {
        guard catalog.theme(id: themeID) != nil else { return }
        profile.ownedThemeIDs.insert(themeID)

        if autoEquip {
            equipTheme(themeID: themeID)
            return
        }

        saveAndNotify()
    }

    func grantCoins(_ amount: Int) {
        guard amount > 0 else { return }
        profile.wallet.credit(amount)
        saveAndNotify()
    }

    func isOwned(themeID: String) -> Bool {
        profile.ownedThemeIDs.contains(themeID)
    }

    func isEquipped(themeID: String) -> Bool {
        themeID == profile.equippedBlockThemeID || themeID == profile.equippedGridThemeID
    }

    func timeUntilRewardedAdReady(now: Date = Date()) -> TimeInterval {
        guard let next = profile.nextRewardedAdAt else { return 0 }
        return max(0, next.timeIntervalSince(now))
    }

    func dailyResetDate(now: Date = Date()) -> Date {
        let dayStart = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(24 * 60 * 60)
    }

    func timeUntilDailyReset(now: Date = Date()) -> TimeInterval {
        max(0, dailyResetDate(now: now).timeIntervalSince(now))
    }

    func equippedBlockTheme() -> ThemeDefinition? {
        catalog.theme(id: profile.equippedBlockThemeID)
    }

    func equippedGridTheme() -> ThemeDefinition? {
        catalog.theme(id: profile.equippedGridThemeID)
    }

    private func applyDailyProgress(type: DailyChallengeType, delta: Int, now: Date) {
        guard delta > 0 else { return }

        guard let index = profile.daily.challenges.firstIndex(where: { $0.definition.type == type }) else {
            return
        }
        profile.daily.challenges[index].apply(delta: delta, at: now)
    }

    private func refreshDailyIfNeeded(now: Date) {
        let dayStart = calendar.startOfDay(for: now)
        guard dayStart != profile.daily.dayStart else { return }

        profile.daily.dayStart = dayStart
        profile.daily.challenges = DailyChallengeFactory.make(
            for: dayStart,
            calendar: calendar,
            tuning: dailyChallengeTuningProvider()
        )
        profile.daily.streakClaimedForDayStart = nil
    }

    private func markDailyActive(now: Date) {
        let today = calendar.startOfDay(for: now)

        if let lastActive = profile.daily.lastActiveDayStart,
           let dayGap = calendar.dateComponents([.day], from: lastActive, to: today).day,
           dayGap > 0 {
            if dayGap == 1 {
                profile.daily.streak += 1
            } else {
                profile.daily.streak = 1
            }
        } else if profile.daily.lastActiveDayStart == nil {
            profile.daily.streak = max(profile.daily.streak, 1)
        }

        profile.daily.lastActiveDayStart = today
    }

    private func saveAndNotify() {
        saveProfile()
        objectWillChange.send()
    }

    private func saveProfile() {
        guard let data = try? encoder.encode(profile) else { return }
        keyValueStore.set(data, forKey: storageKey)
    }
}

struct PlayerMetaProfile: Codable, Equatable {
    var wallet: CurrencyBalance

    var ownedThemeIDs: Set<String>
    var equippedBlockThemeID: String
    var equippedGridThemeID: String

    var removeAdsEntitlement: Bool
    var starterPackPurchased: Bool

    var daily: DailyMetaState
    var onboarding: OnboardingMetaState

    var nextRewardedAdAt: Date?

    enum CodingKeys: String, CodingKey {
        case wallet
        case ownedThemeIDs
        case equippedBlockThemeID
        case equippedGridThemeID
        case removeAdsEntitlement
        case starterPackPurchased
        case daily
        case onboarding
        case nextRewardedAdAt
    }

    init(
        wallet: CurrencyBalance,
        ownedThemeIDs: Set<String>,
        equippedBlockThemeID: String,
        equippedGridThemeID: String,
        removeAdsEntitlement: Bool,
        starterPackPurchased: Bool,
        daily: DailyMetaState,
        onboarding: OnboardingMetaState,
        nextRewardedAdAt: Date?
    ) {
        self.wallet = wallet
        self.ownedThemeIDs = ownedThemeIDs
        self.equippedBlockThemeID = equippedBlockThemeID
        self.equippedGridThemeID = equippedGridThemeID
        self.removeAdsEntitlement = removeAdsEntitlement
        self.starterPackPurchased = starterPackPurchased
        self.daily = daily
        self.onboarding = onboarding
        self.nextRewardedAdAt = nextRewardedAdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        wallet = try container.decode(CurrencyBalance.self, forKey: .wallet)
        ownedThemeIDs = try container.decode(Set<String>.self, forKey: .ownedThemeIDs)
        equippedBlockThemeID = try container.decode(String.self, forKey: .equippedBlockThemeID)
        equippedGridThemeID = try container.decode(String.self, forKey: .equippedGridThemeID)
        removeAdsEntitlement = try container.decode(Bool.self, forKey: .removeAdsEntitlement)
        starterPackPurchased = try container.decodeIfPresent(Bool.self, forKey: .starterPackPurchased) ?? false
        daily = try container.decode(DailyMetaState.self, forKey: .daily)
        onboarding = try container.decode(OnboardingMetaState.self, forKey: .onboarding)
        nextRewardedAdAt = try container.decodeIfPresent(Date.self, forKey: .nextRewardedAdAt)
    }

    static func defaultProfile(
        catalog: ShopCatalog,
        dayStart: Date,
        now: Date,
        dailyChallengeTuning: DailyChallengeRemoteTuning = .default
    ) -> PlayerMetaProfile {
        let owned = Set([catalog.defaultBlockThemeID, catalog.defaultGridThemeID])
        return PlayerMetaProfile(
            wallet: CurrencyBalance(coins: 220),
            ownedThemeIDs: owned,
            equippedBlockThemeID: catalog.defaultBlockThemeID,
            equippedGridThemeID: catalog.defaultGridThemeID,
            removeAdsEntitlement: false,
            starterPackPurchased: false,
            daily: DailyMetaState(
                dayStart: dayStart,
                challenges: DailyChallengeFactory.make(for: dayStart, tuning: dailyChallengeTuning),
                streak: 1,
                lastActiveDayStart: dayStart,
                streakClaimedForDayStart: nil
            ),
            onboarding: OnboardingMetaState(
                firstLaunchAt: now,
                ahaMomentUnlocked: false
            ),
            nextRewardedAdAt: nil
        )
    }

    func sanitized(using catalog: ShopCatalog) -> PlayerMetaProfile {
        var copy = self

        let allowed = catalog.allThemeIDs
        copy.ownedThemeIDs = copy.ownedThemeIDs.filter { allowed.contains($0) }
        copy.ownedThemeIDs.insert(catalog.defaultBlockThemeID)
        copy.ownedThemeIDs.insert(catalog.defaultGridThemeID)

        if !copy.ownedThemeIDs.contains(copy.equippedBlockThemeID) || catalog.theme(id: copy.equippedBlockThemeID)?.category != .block {
            copy.equippedBlockThemeID = catalog.defaultBlockThemeID
        }

        if !copy.ownedThemeIDs.contains(copy.equippedGridThemeID) || catalog.theme(id: copy.equippedGridThemeID)?.category != .grid {
            copy.equippedGridThemeID = catalog.defaultGridThemeID
        }

        return copy
    }
}

struct DailyMetaState: Codable, Equatable {
    var dayStart: Date
    var challenges: [DailyChallengeProgress]
    var streak: Int
    var lastActiveDayStart: Date?
    var streakClaimedForDayStart: Date?
}

struct OnboardingMetaState: Codable, Equatable {
    let firstLaunchAt: Date
    var ahaMomentUnlocked: Bool
}

enum PurchaseThemeResult: Equatable {
    case purchased(cost: Int)
    case alreadyOwned
    case insufficientFunds(required: Int)
    case notFound
}
