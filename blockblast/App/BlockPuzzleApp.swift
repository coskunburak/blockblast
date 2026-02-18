import SwiftUI

@MainActor
struct BlockPuzzleRootView: View {
    @StateObject private var coordinator: AppCoordinator

    init(container: AppContainer) {
        _coordinator = StateObject(wrappedValue: AppCoordinator(container: container))
    }

    init() {
        self.init(container: AppContainer())
    }

    var body: some View {
        AppCoordinatorView()
            .environmentObject(coordinator)
            .environmentObject(coordinator.container.userPreferences)
            .environment(\.locale, coordinator.container.userPreferences.locale)
            .dynamicTypeSize(coordinator.container.userPreferences.dynamicTypeSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.05, green: 0.07, blue: 0.11).ignoresSafeArea())
    }
}
