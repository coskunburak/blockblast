import Foundation

enum PowerUpMode: String, Codable, Equatable {
    case none
    case hammer
    case bomb
    case rainbow

    init(powerUpType: PowerUpType) {
        switch powerUpType {
        case .hammer:
            self = .hammer
        case .bomb:
            self = .bomb
        case .rainbow:
            self = .rainbow
        }
    }

    var asPowerUpType: PowerUpType? {
        switch self {
        case .none:
            return nil
        case .hammer:
            return .hammer
        case .bomb:
            return .bomb
        case .rainbow:
            return .rainbow
        }
    }
}
