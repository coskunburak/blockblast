import Foundation
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

enum TrackingAuthorizationStatus: String, Codable {
    case notDetermined
    case restricted
    case denied
    case authorized
    case unavailable
}

@MainActor
protocol TrackingTransparencyClient {
    var status: TrackingAuthorizationStatus { get }
    func requestAuthorization() async -> TrackingAuthorizationStatus
}

@MainActor
final class SystemTrackingTransparencyClient: TrackingTransparencyClient {
    var status: TrackingAuthorizationStatus {
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14.0, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .denied: return .denied
            case .authorized: return .authorized
            @unknown default: return .unavailable
            }
        }
        #endif
        return .unavailable
    }

    func requestAuthorization() async -> TrackingAuthorizationStatus {
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14.0, *) {
            let raw = await ATTrackingManager.requestTrackingAuthorization()
            switch raw {
            case .notDetermined: return .notDetermined
            case .restricted: return .restricted
            case .denied: return .denied
            case .authorized: return .authorized
            @unknown default: return .unavailable
            }
        }
        #endif
        return .unavailable
    }
}

@MainActor
struct MockTrackingTransparencyClient: TrackingTransparencyClient {
    var resolvedStatus: TrackingAuthorizationStatus = .authorized
    var status: TrackingAuthorizationStatus = .notDetermined

    func requestAuthorization() async -> TrackingAuthorizationStatus {
        resolvedStatus
    }
}
