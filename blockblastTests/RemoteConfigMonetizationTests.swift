import Testing
@testable import blockblast

struct RemoteConfigMonetizationTests {
    @Test func paywallCadenceRespectsFirstAndRepeatValues() {
        let config = GameOverPaywallConfig(
            enabled: true,
            firstOfferAfterGameOvers: 2,
            repeatEveryGameOvers: 3,
            showStarterPackUpsell: true
        )

        #expect(config.shouldPresent(totalGameOvers: 1) == false)
        #expect(config.shouldPresent(totalGameOvers: 2) == true)
        #expect(config.shouldPresent(totalGameOvers: 3) == false)
        #expect(config.shouldPresent(totalGameOvers: 4) == false)
        #expect(config.shouldPresent(totalGameOvers: 5) == true)
    }

    @Test func remoteConfigAssignmentIsDeterministicPerInstallation() {
        let configA1 = RemoteTuning.productionMonetization(for: "device-a")
        let configA2 = RemoteTuning.productionMonetization(for: "device-a")
        let configB = RemoteTuning.productionMonetization(for: "device-b")

        #expect(configA1 == configA2)
        #expect((2...3).contains(configA1.interstitialGameOverInterval))
        #expect((2...3).contains(configB.interstitialGameOverInterval))
    }
}
