import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var preferences: UserPreferencesStore
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        topBar
                        titleBanner
                        gemPedestal
                        actionStack
                        menuDock
                        dailyCard
                    }
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.top, proxy.safeAreaInsets.top + 4)
                    .padding(.bottom, max(20, proxy.safeAreaInsets.bottom + 12))
                }
            }
            .overlay(alignment: .bottom) {
                if let rewardToast = viewModel.rewardToast {
                    Text(rewardToast)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.26), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        }
                        .padding(.bottom, max(18, proxy.safeAreaInsets.bottom + 8))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task {
                            try? await Task.sleep(for: .seconds(2))
                            await MainActor.run {
                                withAnimation {
                                    viewModel.rewardToast = nil
                                }
                            }
                        }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.38, green: 0.58, blue: 0.97),
                    Color(red: 0.24, green: 0.48, blue: 0.92),
                    Color(red: 0.15, green: 0.39, blue: 0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HexPatternOverlay()
                .opacity(0.28)

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -130, y: -280)

            Circle()
                .fill(Color(red: 0.67, green: 0.82, blue: 1.0).opacity(0.24))
                .frame(width: 360, height: 360)
                .blur(radius: 74)
                .offset(x: 180, y: 320)

            CloudPuff(width: 220, height: 86)
                .opacity(0.34)
                .offset(x: -125, y: -170)

            CloudPuff(width: 180, height: 70)
                .opacity(0.26)
                .offset(x: 150, y: -50)

            CloudPuff(width: 240, height: 92)
                .opacity(0.30)
                .offset(x: 120, y: 320)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                statCapsule(
                    icon: "crown.fill",
                    title: preferences.localized("home.stat.coins"),
                    value: "\(viewModel.coins)"
                )

                statCapsule(
                    icon: "flame.fill",
                    title: preferences.localized("home.stat.streak"),
                    value: "\(viewModel.streak)"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                coordinator.goToSettings()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.32, green: 0.50, blue: 0.93), Color(red: 0.22, green: 0.38, blue: 0.80)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "line.3.horizontal")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                }
                .frame(width: 54, height: 54)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1.5)
                }
                .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(preferences.localized("home.action.settings"))
            .accessibilityIdentifier("home.settingsButton")
        }
    }

    private var titleBanner: some View {
        VStack(spacing: 8) {
            let titleWords = preferences.localized("home.title").uppercased().replacingOccurrences(of: " ", with: "\n")

            Text(titleWords)
                .font(.system(size: 60, weight: .black, design: .rounded))
                .minimumScaleFactor(0.58)
                .multilineTextAlignment(.center)
                .lineSpacing(-6)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.94, blue: 0.42), Color(red: 1.0, green: 0.58, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.46, green: 0.24, blue: 0.95).opacity(0.72), radius: 0, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.24), radius: 12, x: 0, y: 8)
                .padding(.horizontal, 10)

            Text(preferences.localized("home.subtitle"))
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.20), in: Capsule())
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1)
                }
        }
    }

    private var gemPedestal: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.40))
                .frame(width: 134, height: 134)
                .blur(radius: 24)

            Image(systemName: "diamond.fill")
                .font(.system(size: 100, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.66, green: 1.0, blue: 0.88), Color(red: 0.16, green: 0.83, blue: 0.70)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.08, green: 0.60, blue: 0.49).opacity(0.52), radius: 12, x: 0, y: 10)
        }
        .padding(.top, 2)
        .padding(.bottom, 4)
    }

    private var actionStack: some View {
        VStack(spacing: 12) {
            Button {
                coordinator.goToModeSelection()
            } label: {
                gameActionButton(
                    title: preferences.localized("home.action.play"),
                    subtitle: preferences.localized("home.menu.mode"),
                    gradient: [Color(red: 1.0, green: 0.78, blue: 0.23), Color(red: 1.0, green: 0.51, blue: 0.16)],
                    textColor: Color(red: 0.42, green: 0.21, blue: 0.08),
                    glow: Color(red: 1.0, green: 0.68, blue: 0.16).opacity(0.50)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.playButton")

            Button {
                coordinator.goToModeSelection()
            } label: {
                gameActionButton(
                    title: preferences.localized("home.daily.title"),
                    subtitle: preferences.localized("home.menu.mode.subtitle"),
                    gradient: [Color(red: 0.56, green: 0.94, blue: 0.56), Color(red: 0.24, green: 0.74, blue: 0.44)],
                    textColor: Color(red: 0.05, green: 0.33, blue: 0.18),
                    glow: Color(red: 0.31, green: 0.92, blue: 0.56).opacity(0.42)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.modeSelectionButton")
        }
    }

    private var menuDock: some View {
        HStack(spacing: 12) {
            Button {
                coordinator.goToStore()
            } label: {
                menuButton(
                    icon: "bag.fill",
                    title: preferences.localized("home.menu.shop"),
                    accent: [Color(red: 0.88, green: 0.45, blue: 1.0), Color(red: 0.58, green: 0.37, blue: 0.98)]
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.storeButton")

            Button {
                coordinator.goToSettings()
            } label: {
                menuButton(
                    icon: "gearshape.fill",
                    title: preferences.localized("home.menu.settings"),
                    accent: [Color(red: 0.40, green: 0.68, blue: 1.0), Color(red: 0.20, green: 0.48, blue: 0.96)]
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.settingsMenuButton")

            menuButton(
                icon: "trophy.fill",
                title: "VIP",
                accent: [Color(red: 1.0, green: 0.76, blue: 0.38), Color(red: 1.0, green: 0.53, blue: 0.16)]
            )
            .opacity(0.92)
        }
    }

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                Text(preferences.localized("home.daily.title"))
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                Spacer(minLength: 8)

                Text(preferences.localized("home.daily.reset", viewModel.dailyResetRemainingText))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.22), in: Capsule())
            }

            HStack(spacing: 8) {
                Label(preferences.localized("home.daily.streak_reward"), systemImage: "bolt.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                glowingActionPill(
                    title: viewModel.canClaimStreakReward ? preferences.localized("home.daily.claim_streak") : preferences.localized("home.daily.streak_claimed"),
                    colors: [Color(red: 1.0, green: 0.73, blue: 0.24), Color(red: 1.0, green: 0.54, blue: 0.16)],
                    isDisabled: !viewModel.canClaimStreakReward
                ) {
                    viewModel.claimStreakReward()
                }
            }

            ForEach(viewModel.challenges) { challenge in
                challengeRow(challenge: challenge)
            }

            HStack {
                Text(preferences.localized("home.daily.rewarded_ad"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(viewModel.rewardedAdRemainingText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.74))

                glowingActionPill(
                    title: preferences.localized("home.daily.rewarded_claim", viewModel.rewardedAdCoinAmount),
                    colors: [Color(red: 0.25, green: 0.73, blue: 1.0), Color(red: 0.16, green: 0.49, blue: 1.0)],
                    isDisabled: !viewModel.canClaimRewardedAd
                ) {
                    viewModel.claimRewardedAd()
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.25), Color.black.opacity(0.11)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(preferences.highContrastMode ? 0.34 : 0.18), lineWidth: 1.1)
        }
        .shadow(color: Color.black.opacity(0.28), radius: 14, x: 0, y: 9)
    }

    private func challengeRow(challenge: DailyChallengeProgress) -> some View {
        let progress = max(0, min(1, CGFloat(challenge.progress) / CGFloat(max(challenge.definition.target, 1))))

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(challenge.definition.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("\(challenge.progress)/\(challenge.definition.target)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()

                glowingActionPill(
                    title: challengeButtonTitle(for: challenge),
                    colors: [Color(red: 0.32, green: 0.90, blue: 0.64), Color(red: 0.18, green: 0.74, blue: 1.0)],
                    isDisabled: !challenge.isClaimable
                ) {
                    viewModel.claimDailyReward(challengeID: challenge.id)
                }
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.28))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.32, green: 0.90, blue: 0.64), Color(red: 0.20, green: 0.66, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, 260 * progress))
            }
            .frame(height: 7)
        }
        .padding(10)
        .background(Color.black.opacity(0.17), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func statCapsule(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 1.0, green: 0.90, blue: 0.42))

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.74))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.20), in: Capsule())
        .overlay {
            Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
    }

    private func gameActionButton(
        title: String,
        subtitle: String,
        gradient: [Color],
        textColor: Color,
        glow: Color
    ) -> some View {
        VStack(spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 30, weight: .black, design: .rounded))
                .minimumScaleFactor(0.7)
                .foregroundStyle(textColor)
                .lineLimit(1)

            Text(subtitle)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(textColor.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.33), lineWidth: 1.5)
        }
        .overlay(alignment: .top) {
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(height: 12)
                .blur(radius: 7)
                .padding(.horizontal, 34)
                .offset(y: 6)
        }
        .shadow(color: glow, radius: 18, x: 0, y: 9)
        .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 5)
    }

    private func menuButton(icon: String, title: String, accent: [Color]) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(colors: accent, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Image(systemName: icon)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
            }
            .frame(width: 62, height: 62)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.32), lineWidth: 1.2)
            }
            .shadow(color: Color.black.opacity(0.30), radius: 9, x: 0, y: 5)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity)
    }

    private func glowingActionPill(
        title: String,
        colors: [Color],
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }

    private func challengeButtonTitle(for challenge: DailyChallengeProgress) -> String {
        if challenge.isClaimable {
            return preferences.localized("home.daily.claim_reward", challenge.definition.rewardCoins)
        }
        if challenge.claimedAt == nil {
            return preferences.localized("home.daily.in_progress")
        }
        return preferences.localized("home.daily.claimed")
    }
}

private struct CloudPuff: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white)
                .frame(width: width, height: height * 0.62)

            Circle()
                .fill(Color.white)
                .frame(width: height * 0.92, height: height * 0.92)
                .offset(x: -width * 0.22, y: -height * 0.16)

            Circle()
                .fill(Color.white)
                .frame(width: height, height: height)
                .offset(x: 0, y: -height * 0.22)

            Circle()
                .fill(Color.white)
                .frame(width: height * 0.84, height: height * 0.84)
                .offset(x: width * 0.24, y: -height * 0.14)
        }
        .blur(radius: 0.4)
    }
}

private struct HexPatternOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let cell: CGFloat = 92
            let columns = Int(proxy.size.width / (cell * 0.74)) + 3
            let rows = Int(proxy.size.height / (cell * 0.86)) + 3

            ZStack {
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        HexShape()
                            .stroke(Color.white.opacity(0.16), lineWidth: 1.6)
                            .frame(width: cell, height: cell)
                            .position(
                                x: CGFloat(column) * cell * 0.74 + (row.isMultiple(of: 2) ? 0 : cell * 0.37),
                                y: CGFloat(row) * cell * 0.86
                            )
                    }
                }
            }
            .blur(radius: 0.4)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

private struct HexShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5

        for index in 0..<6 {
            let angle = (CGFloat(index) * 60 - 30) * .pi / 180
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

extension View {
    func gamePanel(cornerRadius: CGFloat, highContrast: Bool) -> some View {
        background(
            LinearGradient(
                colors: [
                    Color.white.opacity(highContrast ? 0.24 : 0.16),
                    Color.white.opacity(highContrast ? 0.15 : 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(highContrast ? 0.30 : 0.18), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.22), radius: 16, x: 0, y: 8)
    }
}
