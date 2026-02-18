import Testing
@testable import blockblast

@MainActor
struct AppCoordinatorFlowTests {
    @Test func homeModeGameResultsFlowAppendsExpectedRoutes() {
        let keyValue = InMemoryKeyValueStore()
        let container = AppContainer(
            saveStore: SaveGameStore(keyValueStore: keyValue),
            keyValueStore: keyValue
        )
        let coordinator = AppCoordinator(container: container, launchArguments: [])

        #expect(coordinator.path.isEmpty)

        coordinator.goToModeSelection()
        coordinator.goToGame(mode: .classic)
        coordinator.goToResults(
            summary: GameResultSummary(
                mode: .classic,
                score: 1200,
                turn: 24,
                clears: 8,
                comboMax: 3,
                durationSeconds: 95,
                rewardedContinues: 1
            )
        )

        #expect(coordinator.path.count == 3)
        #expect(coordinator.path[0] == .modeSelection)
        #expect(coordinator.path[1] == .game(mode: .classic))

        if case let .results(summary) = coordinator.path[2] {
            #expect(summary.score == 1200)
            #expect(summary.mode == .classic)
        } else {
            Issue.record("Expected results route at index 2")
        }
    }

    @Test func restartGameResetsStackToModeAndGame() {
        let keyValue = InMemoryKeyValueStore()
        let container = AppContainer(
            saveStore: SaveGameStore(keyValueStore: keyValue),
            keyValueStore: keyValue
        )
        let coordinator = AppCoordinator(container: container, launchArguments: [])

        coordinator.goToStore()
        coordinator.restartGame(mode: .dailyChallenge)

        #expect(coordinator.path == [.modeSelection, .game(mode: .dailyChallenge)])
    }
}
