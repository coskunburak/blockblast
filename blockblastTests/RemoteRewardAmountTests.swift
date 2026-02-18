import Foundation
import Testing
@testable import blockblast

struct RemoteRewardAmountTests {
    @Test func rewardedCoinAmountUsesProviderValue() {
        let store = MetaProgressionStore(
            keyValueStore: InMemoryKeyValueStore(),
            rewardedAdCoinsProvider: { 88 },
            now: fixedDate(dayOffset: 0)
        )

        let grant = store.claimRewardedAd(now: fixedDate(dayOffset: 0))
        #expect(grant?.coins == 88)
        #expect(store.rewardedAdCoinAmount == 88)
    }
}

private func fixedDate(dayOffset: Int) -> Date {
    let calendar = Calendar(identifier: .gregorian)
    let base = Date(timeIntervalSince1970: 1_738_800_000)
    return calendar.date(byAdding: .day, value: dayOffset, to: base) ?? base
}
