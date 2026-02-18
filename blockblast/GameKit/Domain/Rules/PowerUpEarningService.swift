import Foundation

enum PowerUpEarningService {
    static func earnedPowerUps(linesClearedInMove: Int, comboState: ComboTracker) -> [PowerUpType] {
        var earned: [PowerUpType] = []

        if comboState.hitHammerThreshold {
            earned.append(.hammer)
        }

        if comboState.hitBombThreshold {
            earned.append(.bomb)
        }

        if linesClearedInMove >= 2 {
            earned.append(.rainbow)
        }

        return earned
    }
}
