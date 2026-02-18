import Foundation

enum RewardSource: String, Codable {
    case dailyChallenge
    case dailyStreak
    case rewardedAd
    case comboMilestone
    case onboardingAha
}

struct RewardGrant: Equatable {
    let source: RewardSource
    let coins: Int
    let reason: String
}

enum RewardScheduler {
    static let rewardedAdCoins = 70
    static let onboardingAhaCoins = 90

    static func streakCoins(streak: Int) -> Int {
        let bounded = min(max(streak, 1), 14)
        return 50 + (bounded - 1) * 15
    }

    static func comboMilestoneCoins(for combo: Int) -> Int {
        switch combo {
        case 3:
            return 35
        case 5:
            return 65
        case 8:
            return 120
        default:
            return 0
        }
    }

    static var comboMilestones: [Int] {
        [3, 5, 8]
    }
}
