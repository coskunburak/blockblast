import Foundation

struct FeatureFlags {
    var enableDailyChallenge: Bool = true
    var enableSubscriptionPaywall: Bool = true
    var enableTimeAttack: Bool = false
    var enablePuzzleLevels: Bool = false

    static let `default` = FeatureFlags()
}
