import Foundation

struct ScoreState: Codable, Equatable {
    private(set) var total: Int = 0
    private(set) var comboChain: Int = 0
    private(set) var streakChain: Int = 0
    private(set) var comboMisses: Int = 0

    static let comboCarryWindowMoves = 3

    private enum CodingKeys: String, CodingKey {
        case total
        case comboChain
        case streakChain
        case comboMisses
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        comboChain = try container.decodeIfPresent(Int.self, forKey: .comboChain) ?? 0
        streakChain = try container.decodeIfPresent(Int.self, forKey: .streakChain) ?? 0
        comboMisses = try container.decodeIfPresent(Int.self, forKey: .comboMisses) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(total, forKey: .total)
        try container.encode(comboChain, forKey: .comboChain)
        try container.encode(streakChain, forKey: .streakChain)
        try container.encode(comboMisses, forKey: .comboMisses)
    }

    static func comboMultiplier(for chain: Int) -> Int {
        switch chain {
        case 6...:
            return 4
        case 4...5:
            return 3
        case 2...3:
            return 2
        default:
            return 1
        }
    }

    mutating func apply(clearedCells: Int, clearedLines: Int, tuning: DifficultyTuning) -> Int {
        guard clearedLines > 0 else {
            if comboChain > 0 {
                comboMisses += 1
                if comboMisses > Self.comboCarryWindowMoves {
                    comboChain = 0
                    comboMisses = 0
                }
            } else {
                comboMisses = 0
            }
            streakChain = 0
            return 0
        }

        comboMisses = 0
        comboChain += 1
        streakChain += 1

        let base = (clearedCells * tuning.baseCellPoint) + (clearedLines * tuning.baseLinePoint)
        let multiLineBonus = max(0, clearedLines - 1) * tuning.multiLineBonusStep
        let comboBonus = max(0, comboChain - 1) * tuning.comboBonusStep
        let streakBonus: Int

        if streakChain >= tuning.streakStartsAt {
            streakBonus = (streakChain - tuning.streakStartsAt + 1) * tuning.streakBonusStep
        } else {
            streakBonus = 0
        }

        let rawGain = base + multiLineBonus + comboBonus + streakBonus
        let multiplier = Self.comboMultiplier(for: comboChain)
        let gained = rawGain * multiplier
        total += gained
        return gained
    }
}
