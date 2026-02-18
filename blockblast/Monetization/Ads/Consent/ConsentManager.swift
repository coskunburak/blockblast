import Foundation

enum AdsConsentStatus: String, Codable {
    case unknown
    case required
    case granted
    case denied
    case notRequired
}

struct ConsentSnapshot: Equatable {
    let status: AdsConsentStatus
    let trackingStatus: TrackingAuthorizationStatus
    let canRequestPersonalizedAds: Bool
}

@MainActor
final class ConsentManager: ObservableObject {
    @Published private(set) var status: AdsConsentStatus
    @Published private(set) var trackingStatus: TrackingAuthorizationStatus

    private let trackingClient: TrackingTransparencyClient
    private let keyValueStore: KeyValueStore
    private let requiresExplicitConsent: Bool

    private let consentKey = "com.blockblast.consent.status"
    private let trackingKey = "com.blockblast.consent.tracking.status"

    init(
        trackingClient: TrackingTransparencyClient? = nil,
        keyValueStore: KeyValueStore = UserDefaultsStore(),
        requiresExplicitConsent: Bool = false
    ) {
        self.trackingClient = trackingClient ?? SystemTrackingTransparencyClient()
        self.keyValueStore = keyValueStore
        self.requiresExplicitConsent = requiresExplicitConsent

        if let raw = keyValueStore.data(forKey: consentKey).flatMap({ String(data: $0, encoding: .utf8) }),
           let decoded = AdsConsentStatus(rawValue: raw) {
            self.status = decoded
        } else {
            self.status = .unknown
        }

        if let raw = keyValueStore.data(forKey: trackingKey).flatMap({ String(data: $0, encoding: .utf8) }),
           let decoded = TrackingAuthorizationStatus(rawValue: raw) {
            self.trackingStatus = decoded
        } else {
            self.trackingStatus = self.trackingClient.status
        }
    }

    var snapshot: ConsentSnapshot {
        ConsentSnapshot(
            status: status,
            trackingStatus: trackingStatus,
            canRequestPersonalizedAds: canRequestPersonalizedAds
        )
    }

    // Non-personalized ads are still allowed on denied/restricted ATT, but
    // consent is required before any ad request when status is `.required`.
    var canRequestAds: Bool {
        switch status {
        case .required, .unknown:
            return false
        case .granted, .denied, .notRequired:
            return true
        }
    }

    var canRequestPersonalizedAds: Bool {
        (status == .granted || status == .notRequired) && trackingStatus == .authorized
    }

    func prepareForLaunch() async {
        if status == .unknown {
            status = requiresExplicitConsent ? .required : .notRequired
            persist()
        }

        if status != .required {
            _ = await requestTrackingIfNeeded()
        }
    }

    func submitUserConsent(granted: Bool) async {
        status = granted ? .granted : .denied
        persist()
        _ = await requestTrackingIfNeeded()
    }

    @discardableResult
    func requestTrackingIfNeeded() async -> TrackingAuthorizationStatus {
        let current = trackingClient.status
        if current != .notDetermined {
            trackingStatus = current
            persist()
            return current
        }

        let requested = await trackingClient.requestAuthorization()
        trackingStatus = requested
        persist()
        return requested
    }

    private func persist() {
        keyValueStore.set(Data(status.rawValue.utf8), forKey: consentKey)
        keyValueStore.set(Data(trackingStatus.rawValue.utf8), forKey: trackingKey)
    }
}
