import SwiftUI

struct GameView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var preferences: UserPreferencesStore
    @ObservedObject var viewModel: GameViewModel
    @State private var menuGlowActive = false

    var body: some View {
        GeometryReader { proxy in
            let themes = viewModel.equippedThemes
            let visualTheme = GameVisualTheme.from(
                blockTheme: themes.block,
                gridTheme: themes.grid,
                highContrast: preferences.highContrastMode
            )
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom

            ZStack {
                backgroundLayer

                VStack(spacing: 8) {
                    compactTopHUD
                    sceneCard(visualTheme: visualTheme)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(2)

                    if viewModel.state.runtime == .gameOver {
                        controlsPanel
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.top, safeTop + 4)
                .padding(.bottom, max(4, safeBottom + 2))
                .animation(.spring(response: 0.44, dampingFraction: 0.86), value: viewModel.state.runtime)
            }
            .overlay(alignment: .top) {
                if let reward = viewModel.rewardBanner {
                    Text(reward)
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.top, safeTop + 96)
                        .task {
                            try? await Task.sleep(for: .seconds(1.7))
                            await MainActor.run {
                                viewModel.dismissRewardBanner()
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .overlay(alignment: .top) {
                if let objective = viewModel.objectiveBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.bold))
                        Text(objective)
                            .font(.subheadline.weight(.heavy))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.64, blue: 1.0),
                                Color(red: 0.58, green: 0.36, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .padding(.top, safeTop + 132)
                    .shadow(color: Color.blue.opacity(0.32), radius: 12, x: 0, y: 4)
                    .task {
                        try? await Task.sleep(for: .seconds(1.5))
                        await MainActor.run {
                            viewModel.dismissObjectiveBanner()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $viewModel.activePaywall) { paywallViewModel in
            PaywallView(viewModel: paywallViewModel)
        }
        .overlay(alignment: .bottom) {
            if let toast = viewModel.monetizationToast {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .task {
                        try? await Task.sleep(for: .seconds(2.2))
                        await MainActor.run {
                            withAnimation {
                                viewModel.dismissMonetizationToast()
                            }
                        }
                    }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                menuGlowActive = true
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.27, green: 0.43, blue: 0.82),
                    Color(red: 0.22, green: 0.36, blue: 0.74),
                    Color(red: 0.20, green: 0.32, blue: 0.66)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.17))
                .frame(width: 260, height: 260)
                .blur(radius: 52)
                .offset(x: -160, y: -310)

            Circle()
                .fill(Color(red: 0.72, green: 0.78, blue: 1.0).opacity(0.23))
                .frame(width: 280, height: 280)
                .blur(radius: 56)
                .offset(x: 170, y: 350)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func sceneCard(visualTheme: GameVisualTheme) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.18))

            GameSceneView(
                state: viewModel.state,
                recentEvents: viewModel.recentEvents,
                dispatchSerial: viewModel.dispatchSerial,
                theme: visualTheme,
                onPlacePiece: { pieceID, cell in
                    viewModel.placePiece(id: pieceID, at: cell)
                },
                onTapBoard: { cell in
                    viewModel.tapBoard(at: cell)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            LinearGradient(
                colors: [
                    .black.opacity(0.05),
                    .clear,
                    .black.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            if viewModel.showAhaCoachmark {
                onboardingCoachmark
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    Color(red: 0.70, green: 0.79, blue: 1.0).opacity(preferences.highContrastMode ? 0.54 : 0.38),
                    lineWidth: 1.2
                )
        }
        .shadow(color: Color(red: 0.06, green: 0.12, blue: 0.36).opacity(0.42), radius: 28, x: 0, y: 14)
    }

    private var compactTopHUD: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.subheadline.weight(.bold))
                    Text("\(viewModel.coins)")
                        .font(.headline.weight(.heavy))
                }
                .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.30))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.20), in: Capsule())

                Spacer()

                Menu {
                    if viewModel.state.runtime == .running {
                        Button {
                            AudioEngine.shared.play(.uiTap)
                            HapticManager.shared.place()
                            viewModel.pause()
                        } label: {
                            Label(preferences.localized("game.action.pause"), systemImage: "pause.fill")
                        }
                    }

                    if viewModel.state.runtime == .paused {
                        Button {
                            AudioEngine.shared.play(.uiTap)
                            HapticManager.shared.place()
                            viewModel.resume()
                        } label: {
                            Label(preferences.localized("game.action.resume"), systemImage: "play.fill")
                        }
                    }

                    Button {
                        AudioEngine.shared.play(.uiTap)
                        HapticManager.shared.place()
                        viewModel.restart()
                    } label: {
                        Label(preferences.localized("game.action.restart"), systemImage: "arrow.clockwise")
                    }

                    if let summary = viewModel.latestResultSummary {
                        Button {
                            AudioEngine.shared.play(.uiTap)
                            HapticManager.shared.place()
                            coordinator.goToResults(summary: summary)
                        } label: {
                            Label(preferences.localized("game.action.results"), systemImage: "list.star")
                        }
                    }

                    if viewModel.canOpenGameOverOffer {
                        Button {
                            AudioEngine.shared.play(.uiTap)
                            HapticManager.shared.place()
                            viewModel.openGameOverOffer()
                        } label: {
                            Label(preferences.localized("game.action.remove_ads"), systemImage: "sparkles")
                        }
                    }

                    Divider()

                    Button {
                        AudioEngine.shared.play(.uiTap)
                        HapticManager.shared.place()
                        coordinator.backToModeSelection()
                    } label: {
                        Label("Main Menu", systemImage: "house.fill")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.28, green: 0.44, blue: 0.93).opacity(menuGlowActive ? 0.44 : 0.24))
                            .blur(radius: menuGlowActive ? 9 : 4)
                            .scaleEffect(menuGlowActive ? 1.08 : 0.94)

                        Image(systemName: "line.3.horizontal")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.black.opacity(0.24), in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                            }
                    }
                }
                .accessibilityIdentifier("game.menuButton")
            }

            Text("\(viewModel.state.score.total)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 4)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let objective = viewModel.activeObjective {
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.caption2.weight(.bold))
                    Text("\(objective.title)  \(objective.progress)/\(objective.target)")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text("+\(objective.rewardCoins)")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.38))
                }
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.16), in: Capsule())
            }

            HStack(spacing: 8) {
                powerUpButton(type: .hammer, icon: "hammer.fill", tint: .orange)
                powerUpButton(type: .bomb, icon: "burst.fill", tint: .red)
                powerUpButton(type: .rainbow, icon: "sparkles", tint: .purple)

                if viewModel.isPowerUpModeActive {
                    Button {
                        AudioEngine.shared.play(.uiTap)
                        HapticManager.shared.place()
                        viewModel.cancelPowerUpSelection()
                    } label: {
                        Text("Cancel")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.28), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("game.powerup.cancel")
                }
            }
        }
        .padding(.horizontal, 6)
    }

    private func powerUpButton(type: PowerUpType, icon: String, tint: Color) -> some View {
        let count = viewModel.state.powerUpInventory.count(for: type)
        let isSelected = viewModel.selectedPowerUpType == type && viewModel.isPowerUpModeActive
        let isDisabled = viewModel.state.runtime != .running || count == 0

        return Button {
            AudioEngine.shared.play(.uiTap)
            HapticManager.shared.place()
            viewModel.selectPowerUp(type: type)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text("\(count)")
                    .font(.caption.weight(.heavy))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                (isSelected ? tint.opacity(0.95) : tint.opacity(0.60)),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.65 : 0.22), lineWidth: isSelected ? 1.2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .accessibilityIdentifier("game.powerup.\(type.rawValue)")
    }

    private var controlsPanel: some View {
        VStack(spacing: 8) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    controlButton(
                        title: viewModel.continueButtonTitle,
                        icon: "play.fill",
                        tint: .green,
                        isDisabled: !viewModel.canContinueWithRewardedAd,
                        accessibilityID: "game.continueButton"
                    ) {
                        viewModel.continueWithRewardedAd()
                    }
                    controlButton(
                        title: preferences.localized("game.action.restart"),
                        icon: "arrow.clockwise",
                        tint: .red,
                        accessibilityID: "game.restartButton"
                    ) {
                        viewModel.restart()
                    }
                }

                HStack(spacing: 10) {
                    controlButton(
                        title: viewModel.coinRewardButtonTitle,
                        icon: "gift.fill",
                        tint: .blue,
                        isDisabled: !viewModel.canClaimGameOverCoinsWithAd,
                        accessibilityID: "game.coinRewardButton"
                    ) {
                        viewModel.claimGameOverCoinsWithAd()
                    }

                    controlButton(
                        title: preferences.localized("game.action.results"),
                        icon: "list.star",
                        tint: .purple,
                        isDisabled: viewModel.latestResultSummary == nil,
                        accessibilityID: "game.resultsButton"
                    ) {
                        guard let summary = viewModel.latestResultSummary else { return }
                        coordinator.goToResults(summary: summary)
                    }
                }

                HStack(spacing: 10) {
                    controlButton(
                        title: preferences.localized("game.action.remove_ads"),
                        icon: "sparkles",
                        tint: .orange,
                        isDisabled: !viewModel.canOpenGameOverOffer,
                        accessibilityID: "game.removeAdsButton"
                    ) {
                        viewModel.openGameOverOffer()
                    }
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(preferences.highContrastMode ? 0.17 : 0.11), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(preferences.highContrastMode ? 0.24 : 0.18), lineWidth: 1)
        }
    }

    private func controlButton(
        title: String,
        icon: String,
        tint: Color,
        isDisabled: Bool = false,
        accessibilityID: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(RelaxedGameButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.56 : 1)
        .simultaneousGesture(TapGesture().onEnded {
            guard !isDisabled else { return }
            AudioEngine.shared.play(.uiTap, minimumSpacing: 0.05)
            HapticManager.shared.place()
        })
        .applyAccessibilityIdentifier(accessibilityID)
    }

    private var onboardingCoachmark: some View {
        VStack(spacing: 10) {
            Text(preferences.localized("game.coachmark.title"))
                .font(.headline)
                .foregroundStyle(.white)
            Text(preferences.localized("game.coachmark.subtitle"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.9))
            Text(preferences.localized("game.coachmark.goal", RewardScheduler.onboardingAhaCoins))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.yellow)
        }
        .padding(18)
        .background(Color.black.opacity(0.74), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(24)
    }
}

private struct RelaxedGameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1.0)
            .saturation(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? -0.01 : 0)
            .shadow(
                color: Color.black.opacity(configuration.isPressed ? 0.16 : 0.28),
                radius: configuration.isPressed ? 3 : 8,
                x: 0,
                y: configuration.isPressed ? 1 : 4
            )
            .animation(.spring(response: 0.20, dampingFraction: 0.74), value: configuration.isPressed)
    }
}

private extension View {
    @ViewBuilder
    func applyAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}
