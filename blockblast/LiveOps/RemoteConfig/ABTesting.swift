import Foundation

enum PieceWeightProfile: String, Codable, CaseIterable {
    case balanced
    case comboFriendly
    case precision
}

enum DailyDifficultyTier: String, Codable, CaseIterable {
    case relaxed
    case standard
    case hard
}

enum ABTesting {
    static func paywallVariant(for installationID: String) -> PaywallExperimentVariant {
        // 50/50 split between control and value bundle.
        let bucket = stablePercentile(seed: "paywall.value_bundle.v1", installationID: installationID)
        return bucket < 50 ? .control : .valueBundle
    }

    static func interstitialGameOverInterval(for installationID: String) -> Int {
        // Keeps cadence between 2 and 3 game overs.
        let bucket = stablePercentile(seed: "ads.interstitial.interval.v1", installationID: installationID)
        return bucket < 50 ? 2 : 3
    }

    static func rewardedCoinAmount(for installationID: String) -> Int {
        let bucket = stablePercentile(seed: "economy.rewarded_coin.v1", installationID: installationID)
        switch bucket {
        case ..<34:
            return 60
        case ..<67:
            return 70
        default:
            return 80
        }
    }

    static func pieceWeightProfile(for installationID: String) -> PieceWeightProfile {
        let bucket = stablePercentile(seed: "gameplay.piece_weight_profile.v1", installationID: installationID)
        switch bucket {
        case ..<34:
            return .balanced
        case ..<67:
            return .comboFriendly
        default:
            return .precision
        }
    }

    static func dailyDifficultyTier(for installationID: String) -> DailyDifficultyTier {
        let bucket = stablePercentile(seed: "daily.difficulty_tier.v1", installationID: installationID)
        switch bucket {
        case ..<34:
            return .relaxed
        case ..<67:
            return .standard
        default:
            return .hard
        }
    }

    private static func stablePercentile(seed: String, installationID: String) -> Int {
        let value = stableHash64("\(seed):\(installationID)")
        return Int(value % 100)
    }

    private static func stableHash64(_ string: String) -> UInt64 {
        // FNV-1a 64-bit deterministic hash.
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }
}
