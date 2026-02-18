import Foundation
import Testing
@testable import blockblast

struct MetaProgressionTests {
    @Test func dailyChallengeCanBeCompletedAndClaimedOnce() {
        let store = MetaProgressionStore(keyValueStore: InMemoryKeyValueStore(), now: fixedDate(dayOffset: 0))
        _ = store.markAhaMoment()
        let beforeCoins = store.coins

        let previous = GameState.initial(mode: .classic, gridSize: 8, seed: 1, tuning: .classicDefault)
        let current = previous

        let challenge = try? #require(store.challenges.first(where: { $0.definition.type == .clearRows }))
        let rowsTarget = challenge?.definition.target ?? 8

        for _ in 0..<rowsTarget {
            _ = store.processGameplay(
                previous: previous,
                current: current,
                events: [.linesCleared(count: 1)],
                now: fixedDate(dayOffset: 0)
            )
        }

        let updated = try? #require(store.challenges.first(where: { $0.definition.type == .clearRows }))
        #expect(updated?.isClaimable == true)

        let grant = store.claimDailyChallenge(updated?.id ?? "", now: fixedDate(dayOffset: 0))
        #expect(grant?.source == .dailyChallenge)
        #expect(store.coins == beforeCoins + (grant?.coins ?? 0))

        let secondClaim = store.claimDailyChallenge(updated?.id ?? "", now: fixedDate(dayOffset: 0))
        #expect(secondClaim == nil)
    }

    @Test func streakIncrementsNextDayAndResetsAfterGap() {
        let now = fixedDate(dayOffset: 0)
        let store = MetaProgressionStore(keyValueStore: InMemoryKeyValueStore(), now: now)

        _ = store.claimStreakReward(now: fixedDate(dayOffset: 0))

        let state = GameState.initial(mode: .classic, gridSize: 8, seed: 42, tuning: .classicDefault)
        _ = store.processGameplay(previous: state, current: state, events: [], now: fixedDate(dayOffset: 1))
        #expect(store.streak == 2)

        _ = store.processGameplay(previous: state, current: state, events: [], now: fixedDate(dayOffset: 4))
        #expect(store.streak == 1)
    }

    @Test func themePurchaseConsumesCoinsAndEquipsTheme() {
        let store = MetaProgressionStore(keyValueStore: InMemoryKeyValueStore(), now: fixedDate(dayOffset: 0))
        let targetTheme = try? #require(store.catalog.blockThemes.first(where: { !$0.isFree }))

        let previous = GameState.initial(mode: .classic, gridSize: 8, seed: 7, tuning: .classicDefault)
        let current = comboState(chain: 8)
        _ = store.processGameplay(previous: previous, current: current, events: [], now: fixedDate(dayOffset: 0))
        let coinsBefore = store.coins

        let result = store.purchaseTheme(themeID: targetTheme?.id ?? "")

        switch result {
        case let .purchased(cost):
            #expect(cost == targetTheme?.priceCoins)
            #expect(store.coins == coinsBefore - cost)
            #expect(store.equippedBlockThemeID == targetTheme?.id)
        default:
            Issue.record("Expected theme purchase to succeed")
        }
    }

    @Test func rewardedAdHasCooldown() {
        let store = MetaProgressionStore(keyValueStore: InMemoryKeyValueStore(), now: fixedDate(dayOffset: 0))
        let first = store.claimRewardedAd(now: fixedDate(dayOffset: 0))
        #expect(first != nil)

        let immediate = store.claimRewardedAd(now: fixedDate(dayOffset: 0).addingTimeInterval(30))
        #expect(immediate == nil)

        let afterCooldown = store.claimRewardedAd(now: fixedDate(dayOffset: 0).addingTimeInterval(301))
        #expect(afterCooldown != nil)
    }

    @Test func onboardingAhaRewardGivenOnceOnFirstClear() {
        let store = MetaProgressionStore(keyValueStore: InMemoryKeyValueStore(), now: fixedDate(dayOffset: 0))
        let beforeCoins = store.coins

        let previous = GameState.initial(mode: .classic, gridSize: 8, seed: 9, tuning: .classicDefault)
        let current = previous

        let firstGrants = store.processGameplay(
            previous: previous,
            current: current,
            events: [.linesCleared(count: 1)],
            now: fixedDate(dayOffset: 0)
        )
        let secondGrants = store.processGameplay(
            previous: previous,
            current: current,
            events: [.linesCleared(count: 1)],
            now: fixedDate(dayOffset: 0)
        )

        #expect(firstGrants.contains(where: { $0.source == .onboardingAha }))
        #expect(!secondGrants.contains(where: { $0.source == .onboardingAha }))
        #expect(store.coins == beforeCoins + RewardScheduler.onboardingAhaCoins)
    }

    @Test func dailyResetRefreshesChallengesAndTimerCountsDown() {
        let store = MetaProgressionStore(keyValueStore: InMemoryKeyValueStore(), now: fixedDate(dayOffset: 0))
        let initialTarget = store.challenges.first(where: { $0.definition.type == .clearRows })?.definition.target
        #expect(store.timeUntilDailyReset(now: fixedDate(dayOffset: 0)) > 0)

        let state = GameState.initial(mode: .classic, gridSize: 8, seed: 11, tuning: .classicDefault)
        _ = store.processGameplay(previous: state, current: state, events: [], now: fixedDate(dayOffset: 1))

        let nextTarget = store.challenges.first(where: { $0.definition.type == .clearRows })?.definition.target
        #expect(initialTarget != nextTarget)
    }
}

private func comboState(chain: Int) -> GameState {
    var state = GameState.initial(mode: .classic, gridSize: 8, seed: 77, tuning: .classicDefault)
    for _ in 0..<chain {
        _ = state.score.apply(clearedCells: 4, clearedLines: 1, tuning: .classicDefault)
    }
    return state
}

private func fixedDate(dayOffset: Int) -> Date {
    let calendar = Calendar(identifier: .gregorian)
    let base = Date(timeIntervalSince1970: 1_738_800_000) // 2025-02-10T00:00:00Z
    return calendar.date(byAdding: .day, value: dayOffset, to: base) ?? base
}
