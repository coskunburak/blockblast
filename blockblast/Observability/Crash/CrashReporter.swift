import Foundation

struct NonFatalCrashEvent: Equatable, Identifiable {
    let id: UUID
    let message: String
    let attributes: [String: String]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        message: String,
        attributes: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.message = message
        self.attributes = attributes
        self.timestamp = timestamp
    }
}

@MainActor
protocol CrashReporting: AnyObject {
    func start()
    func recordNonFatal(message: String, attributes: [String: String])
    func record(error: Error, context: String, attributes: [String: String])
}

@MainActor
final class CrashReporter: ObservableObject, CrashReporting {
    @Published private(set) var recentNonFatals: [NonFatalCrashEvent] = []

    private let maxBufferedEvents: Int
    private var isStarted = false

    init(
        maxBufferedEvents: Int = 100
    ) {
        self.maxBufferedEvents = max(20, maxBufferedEvents)
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
    }

    func recordNonFatal(message: String, attributes: [String: String] = [:]) {
        let event = NonFatalCrashEvent(message: message, attributes: attributes)
        recentNonFatals.append(event)
        if recentNonFatals.count > maxBufferedEvents {
            recentNonFatals.removeFirst(recentNonFatals.count - maxBufferedEvents)
        }
    }

    func record(error: Error, context: String, attributes: [String: String] = [:]) {
        var merged = attributes
        merged["context"] = context
        merged["error"] = String(describing: error)
        recordNonFatal(message: "non_fatal_error", attributes: merged)
    }
}
