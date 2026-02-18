import Testing
@testable import blockblast

@MainActor
struct RemoteGameplayTuningTests {
    @Test func remoteConfigProvidesTunableRanges() {
        let config = RemoteTuning.productionMonetization(for: "phase5-device")

        #expect((2...3).contains(config.interstitialGameOverInterval))
        #expect((60...80).contains(config.rewardedCoinAmount))
        #expect(config.gameplay.dailyChallenge.clearRowsTargets.isEmpty == false)
        #expect(config.gameplay.classicTuning.pieceWeights.weight(for: .dot1) > 0)
        #expect(config.gameplay.dailyTuning.pieceWeights.weight(for: .dot1) > 0)
    }

    @Test func appContainerUsesRemoteDifficultyForNewGame() async {
        let container = AppContainer(
            environment: .development,
            keyValueStore: InMemoryKeyValueStore()
        )
        await container.remoteConfigClient.refresh()

        let classicEngine = container.makeGameEngine(mode: .classic, seed: 1)
        let dailyEngine = container.makeGameEngine(mode: .dailyChallenge, seed: 1)
        let remote = container.remoteConfigClient.currentMonetizationConfig.gameplay

        #expect(classicEngine.state.tuning == remote.classicTuning)
        #expect(dailyEngine.state.tuning == remote.dailyTuning)
    }
}
