import Foundation

enum DailyChallengeType: String, Codable, CaseIterable {
    case clearRows
    case makeCombos
    case reachScore
}

struct DailyChallengeDefinition: Codable, Identifiable, Equatable {
    let id: String
    let type: DailyChallengeType
    let target: Int
    let rewardCoins: Int
    let title: String
    let subtitle: String
}

struct DailyChallengeProgress: Codable, Identifiable, Equatable {
    let id: String
    let definition: DailyChallengeDefinition
    var progress: Int
    var completedAt: Date?
    var claimedAt: Date?

    var isCompleted: Bool {
        progress >= definition.target
    }

    var isClaimable: Bool {
        isCompleted && claimedAt == nil
    }

    mutating func apply(delta: Int, at date: Date) {
        guard delta > 0, !isCompleted else { return }
        progress = min(definition.target, progress + delta)
        if isCompleted && completedAt == nil {
            completedAt = date
        }
    }
}

struct DailyChallengeRemoteTuning: Codable, Equatable {
    var clearRowsTargets: [Int]
    var comboTargets: [Int]
    var scoreTargets: [Int]
    var rewardMultiplierPercent: Int

    static let `default` = DailyChallengeRemoteTuning(
        clearRowsTargets: [6, 8, 10],
        comboTargets: [2, 3, 4],
        scoreTargets: [900, 1400, 1800],
        rewardMultiplierPercent: 100
    )
}

enum DailyChallengeFactory {
    static func make(
        for dayStart: Date,
        calendar: Calendar = .current,
        tuning: DailyChallengeRemoteTuning = .default
    ) -> [DailyChallengeProgress] {
        let day = calendar.ordinality(of: .day, in: .year, for: dayStart) ?? 1

        let rowsTargets = sanitizedTargets(tuning.clearRowsTargets, fallback: DailyChallengeRemoteTuning.default.clearRowsTargets)
        let comboTargets = sanitizedTargets(tuning.comboTargets, fallback: DailyChallengeRemoteTuning.default.comboTargets)
        let scoreTargets = sanitizedTargets(tuning.scoreTargets, fallback: DailyChallengeRemoteTuning.default.scoreTargets)
        let rewardMultiplier = max(50, min(250, tuning.rewardMultiplierPercent))

        let rowsTarget = rowsTargets[day % rowsTargets.count]
        let combosTarget = comboTargets[(day + 1) % comboTargets.count]
        let scoreTarget = scoreTargets[(day + 2) % scoreTargets.count]

        return [
            DailyChallengeProgress(
                id: "daily_rows",
                definition: DailyChallengeDefinition(
                    id: "daily_rows",
                    type: .clearRows,
                    target: rowsTarget,
                    rewardCoins: applyRewardMultiplier(base: 120, percent: rewardMultiplier),
                    title: "Today: Clear \(rowsTarget) rows",
                    subtitle: "Keep your board open and chain clears."
                ),
                progress: 0,
                completedAt: nil,
                claimedAt: nil
            ),
            DailyChallengeProgress(
                id: "daily_combos",
                definition: DailyChallengeDefinition(
                    id: "daily_combos",
                    type: .makeCombos,
                    target: combosTarget,
                    rewardCoins: applyRewardMultiplier(base: 100, percent: rewardMultiplier),
                    title: "Today: Make \(combosTarget) combos",
                    subtitle: "Consecutive clear turns increase combo count."
                ),
                progress: 0,
                completedAt: nil,
                claimedAt: nil
            ),
            DailyChallengeProgress(
                id: "daily_score",
                definition: DailyChallengeDefinition(
                    id: "daily_score",
                    type: .reachScore,
                    target: scoreTarget,
                    rewardCoins: applyRewardMultiplier(base: 150, percent: rewardMultiplier),
                    title: "Today: Reach \(scoreTarget) score",
                    subtitle: "Play one or more runs today to hit the goal."
                ),
                progress: 0,
                completedAt: nil,
                claimedAt: nil
            )
        ]
    }

    private static func sanitizedTargets(_ values: [Int], fallback: [Int]) -> [Int] {
        let filtered = values.filter { $0 > 0 }
        return filtered.isEmpty ? fallback : filtered
    }

    private static func applyRewardMultiplier(base: Int, percent: Int) -> Int {
        max(1, base * percent / 100)
    }
}
