import Foundation

enum AppRoute: Hashable {
    case home
    case modeSelection
    case game(mode: GameMode)
    case results(summary: GameResultSummary)
    case store
    case settings
}
