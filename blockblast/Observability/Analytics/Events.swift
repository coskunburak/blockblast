import Foundation

enum AnalyticsEventName: String, Codable {
    case sessionStart = "session_start"
    case gameStart = "game_start"
    case gameOver = "game_over"
    case adImpression = "ad_impression"
    case adRewardGranted = "ad_reward_granted"
    case paywallView = "paywall_view"
    case purchaseSuccess = "purchase_success"
    case purchaseFail = "purchase_fail"
    case dailyComplete = "daily_complete"
    case tutorialStep = "tutorial_step"
}

enum AnalyticsValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    private enum CodingKeys: String, CodingKey {
        case type
        case string
        case int
        case double
        case bool
    }

    private enum ValueType: String, Codable {
        case string
        case int
        case double
        case bool
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        switch type {
        case .string:
            self = .string(try container.decode(String.self, forKey: .string))
        case .int:
            self = .int(try container.decode(Int.self, forKey: .int))
        case .double:
            self = .double(try container.decode(Double.self, forKey: .double))
        case .bool:
            self = .bool(try container.decode(Bool.self, forKey: .bool))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .string(value):
            try container.encode(ValueType.string, forKey: .type)
            try container.encode(value, forKey: .string)
        case let .int(value):
            try container.encode(ValueType.int, forKey: .type)
            try container.encode(value, forKey: .int)
        case let .double(value):
            try container.encode(ValueType.double, forKey: .type)
            try container.encode(value, forKey: .double)
        case let .bool(value):
            try container.encode(ValueType.bool, forKey: .type)
            try container.encode(value, forKey: .bool)
        }
    }
}

struct AnalyticsEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let name: AnalyticsEventName
    let timestamp: Date
    let params: [String: AnalyticsValue]

    init(
        id: UUID = UUID(),
        name: AnalyticsEventName,
        timestamp: Date = Date(),
        params: [String: AnalyticsValue] = [:]
    ) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.params = params
    }
}

@MainActor
protocol AnalyticsTracking: AnyObject {
    func track(_ event: AnalyticsEvent)
    func track(name: AnalyticsEventName, params: [String: AnalyticsValue])
}
