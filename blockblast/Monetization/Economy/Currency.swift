import Foundation

enum CurrencyType: String, Codable {
    case coins
}

struct CurrencyBalance: Codable, Equatable {
    private(set) var coins: Int

    init(coins: Int = 0) {
        self.coins = max(0, coins)
    }

    mutating func credit(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
    }

    @discardableResult
    mutating func spend(_ amount: Int) -> Bool {
        guard amount > 0, amount <= coins else { return false }
        coins -= amount
        return true
    }
}
