import Testing
@testable import blockblast

@MainActor
struct ConsentManagerTests {
    @Test func prepareLaunchWithoutExplicitConsentMarksNotRequiredAndRequestsATT() async {
        let tracking = TrackingSpy(status: .notDetermined, response: .authorized)
        let manager = ConsentManager(
            trackingClient: tracking,
            keyValueStore: InMemoryKeyValueStore(),
            requiresExplicitConsent: false
        )

        await manager.prepareForLaunch()

        #expect(manager.status == .notRequired)
        #expect(manager.trackingStatus == .authorized)
        #expect(manager.canRequestAds == true)
        #expect(manager.canRequestPersonalizedAds == true)
        #expect(tracking.requestCount == 1)
    }

    @Test func explicitConsentFlowBlocksAdsUntilUserResponds() async {
        let tracking = TrackingSpy(status: .notDetermined, response: .denied)
        let manager = ConsentManager(
            trackingClient: tracking,
            keyValueStore: InMemoryKeyValueStore(),
            requiresExplicitConsent: true
        )

        await manager.prepareForLaunch()
        #expect(manager.status == .required)
        #expect(manager.canRequestAds == false)
        #expect(tracking.requestCount == 0)

        await manager.submitUserConsent(granted: true)
        #expect(manager.status == .granted)
        #expect(manager.trackingStatus == .denied)
        #expect(manager.canRequestAds == true)
        #expect(manager.canRequestPersonalizedAds == false)
        #expect(tracking.requestCount == 1)
    }
}

@MainActor
final class TrackingSpy: TrackingTransparencyClient {
    var status: TrackingAuthorizationStatus
    let response: TrackingAuthorizationStatus
    private(set) var requestCount: Int = 0

    init(status: TrackingAuthorizationStatus, response: TrackingAuthorizationStatus) {
        self.status = status
        self.response = response
    }

    func requestAuthorization() async -> TrackingAuthorizationStatus {
        requestCount += 1
        status = response
        return response
    }
}
