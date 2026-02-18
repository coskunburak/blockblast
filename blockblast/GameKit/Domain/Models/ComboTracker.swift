import Foundation

struct ComboTracker: Codable, Equatable {
    private(set) var currentCombo: Int = 0
    private(set) var pendingMisses: Int = 0

    static let comboCarryWindowMoves = 6

    private enum CodingKeys: String, CodingKey {
        case currentCombo
        case pendingMisses
    }

    init(currentCombo: Int = 0) {
        self.currentCombo = max(0, currentCombo)
        self.pendingMisses = 0
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentCombo = max(0, try container.decodeIfPresent(Int.self, forKey: .currentCombo) ?? 0)
        pendingMisses = max(0, try container.decodeIfPresent(Int.self, forKey: .pendingMisses) ?? 0)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentCombo, forKey: .currentCombo)
        try container.encode(pendingMisses, forKey: .pendingMisses)
    }

    mutating func reset() {
        currentCombo = 0
        pendingMisses = 0
    }

    mutating func increment() {
        currentCombo += 1
    }

    mutating func update(linesClearedInMove: Int) {
        if linesClearedInMove > 0 {
            pendingMisses = 0
            increment()
        } else {
            if currentCombo > 0 {
                pendingMisses += 1
                if pendingMisses > Self.comboCarryWindowMoves {
                    reset()
                }
            } else {
                pendingMisses = 0
            }
        }
    }

    var hitHammerThreshold: Bool {
        currentCombo == 3
    }

    var hitBombThreshold: Bool {
        currentCombo == 5
    }
}
