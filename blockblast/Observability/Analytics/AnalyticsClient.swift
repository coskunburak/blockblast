import Foundation

protocol AnalyticsSink {
    func submit(event: AnalyticsEvent)
}

struct ConsoleAnalyticsSink: AnalyticsSink {
    func submit(event: AnalyticsEvent) {
        #if DEBUG
        let payload = event.params.map { "\($0.key)=\($0.value.logValue)" }
            .sorted()
            .joined(separator: " ")
        print("[Analytics] \(event.name.rawValue) \(payload)")
        #endif
    }
}

@MainActor
final class AnalyticsClient: ObservableObject, AnalyticsTracking {
    @Published private(set) var recentEvents: [AnalyticsEvent] = []

    private let sink: AnalyticsSink
    private let maxBufferedEvents: Int

    init(
        sink: AnalyticsSink = ConsoleAnalyticsSink(),
        maxBufferedEvents: Int = 500
    ) {
        self.sink = sink
        self.maxBufferedEvents = max(50, maxBufferedEvents)
    }

    func track(_ event: AnalyticsEvent) {
        recentEvents.append(event)
        if recentEvents.count > maxBufferedEvents {
            recentEvents.removeFirst(recentEvents.count - maxBufferedEvents)
        }
        sink.submit(event: event)
    }

    func track(name: AnalyticsEventName, params: [String: AnalyticsValue] = [:]) {
        track(AnalyticsEvent(name: name, params: params))
    }
}

@MainActor
final class TestAnalyticsClient: AnalyticsTracking {
    private(set) var events: [AnalyticsEvent] = []

    func track(_ event: AnalyticsEvent) {
        events.append(event)
    }

    func track(name: AnalyticsEventName, params: [String: AnalyticsValue]) {
        events.append(AnalyticsEvent(name: name, params: params))
    }
}

private extension AnalyticsValue {
    var logValue: String {
        switch self {
        case let .string(value):
            return value
        case let .int(value):
            return "\(value)"
        case let .double(value):
            return String(format: "%.3f", value)
        case let .bool(value):
            return value ? "true" : "false"
        }
    }
}
