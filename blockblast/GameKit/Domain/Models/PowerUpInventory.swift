import Foundation

struct PowerUpInventory: Codable, Equatable {
    static let hammerCap = 3
    static let bombCap = 3
    static let rainbowCap = 2

    private(set) var hammerCount: Int = 0
    private(set) var bombCount: Int = 0
    private(set) var rainbowCount: Int = 0

    func count(for type: PowerUpType) -> Int {
        switch type {
        case .hammer:
            return hammerCount
        case .bomb:
            return bombCount
        case .rainbow:
            return rainbowCount
        }
    }

    func cap(for type: PowerUpType) -> Int {
        switch type {
        case .hammer:
            return Self.hammerCap
        case .bomb:
            return Self.bombCap
        case .rainbow:
            return Self.rainbowCap
        }
    }

    func canAdd(type: PowerUpType) -> Bool {
        count(for: type) < cap(for: type)
    }

    @discardableResult
    mutating func add(type: PowerUpType) -> Bool {
        guard canAdd(type: type) else { return false }
        switch type {
        case .hammer:
            hammerCount += 1
        case .bomb:
            bombCount += 1
        case .rainbow:
            rainbowCount += 1
        }
        return true
    }

    @discardableResult
    mutating func use(type: PowerUpType) -> Bool {
        guard count(for: type) > 0 else { return false }
        switch type {
        case .hammer:
            hammerCount -= 1
        case .bomb:
            bombCount -= 1
        case .rainbow:
            rainbowCount -= 1
        }
        return true
    }
}
