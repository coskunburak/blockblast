import Foundation

struct GameInteractionState: Codable, Equatable {
    var selectedPowerUp: PowerUpMode = .none
    var isPowerUpActive: Bool = false
}
