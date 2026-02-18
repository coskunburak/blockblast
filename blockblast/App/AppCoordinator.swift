import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []

    let container: AppContainer

    init(container: AppContainer, launchArguments: [String] = ProcessInfo.processInfo.arguments) {
        self.container = container
        self.path = Self.initialPath(from: launchArguments)
    }

    func goToGame(mode: GameMode) {
        path.append(.game(mode: mode))
    }

    func goToModeSelection() {
        path.append(.modeSelection)
    }

    func goToResults(summary: GameResultSummary) {
        if case .results = path.last {
            _ = path.popLast()
        }
        path.append(.results(summary: summary))
    }

    func goToStore() {
        path.append(.store)
    }

    func goToSettings() {
        path.append(.settings)
    }

    func backToHome() {
        path.removeAll()
    }

    func backToModeSelection() {
        path = [.modeSelection]
    }

    func restartGame(mode: GameMode) {
        path = [.modeSelection, .game(mode: mode)]
    }

    private static func initialPath(from arguments: [String]) -> [AppRoute] {
        if arguments.contains("--open-game-classic") {
            return [.modeSelection, .game(mode: .classic)]
        }
        if arguments.contains("--open-game-daily") {
            return [.modeSelection, .game(mode: .dailyChallenge)]
        }
        if arguments.contains("--open-store") {
            return [.store]
        }
        return []
    }
}

struct AppCoordinatorView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView(
                viewModel: HomeViewModel(
                    meta: coordinator.container.metaProgression,
                    rewardedAds: coordinator.container.rewardedAdManager,
                    analytics: coordinator.container.analyticsClient
                )
            )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .modeSelection:
                        ModeSelectionView()
                    case let .game(mode):
                        GameView(
                            viewModel: GameViewModel(
                                engine: coordinator.container.makeGameEngine(mode: mode),
                                meta: coordinator.container.metaProgression,
                                interstitialAds: coordinator.container.interstitialAdManager,
                                rewardedAds: coordinator.container.rewardedAdManager,
                                purchaseManager: coordinator.container.purchaseManager,
                                remoteConfig: coordinator.container.remoteConfigClient,
                                analytics: coordinator.container.analyticsClient,
                                crashReporter: coordinator.container.crashReporter
                            )
                        )
                    case let .results(summary):
                        ResultsView(summary: summary)
                    case .store:
                        StoreView(
                            viewModel: StoreViewModel(
                                meta: coordinator.container.metaProgression,
                                purchaseManager: coordinator.container.purchaseManager,
                                analytics: coordinator.container.analyticsClient
                            )
                        )
                    case .settings:
                        SettingsView(
                            preferences: coordinator.container.userPreferences,
                            consentManager: coordinator.container.consentManager
                        )
                    case .home:
                        HomeView(
                            viewModel: HomeViewModel(
                                meta: coordinator.container.metaProgression,
                                rewardedAds: coordinator.container.rewardedAdManager,
                                analytics: coordinator.container.analyticsClient
                            )
                        )
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.05, green: 0.07, blue: 0.11).ignoresSafeArea())
        .task {
            await coordinator.container.bootstrapMonetizationIfNeeded()
        }
    }
}
