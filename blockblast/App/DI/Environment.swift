import Foundation

enum AppEnvironment: String {
    case development
    case staging
    case production

    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    var defaultGridSize: Int {
        // Phase 0 decision: Block Blast feel is strongest at 8x8.
        8
    }
}
