import Foundation

struct SaveGameDTO: Codable {
    let version: Int
    let savedAt: Date
    let state: GameState
}
