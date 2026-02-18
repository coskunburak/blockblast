import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var preferences: UserPreferencesStore

    let summary: GameResultSummary

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        header
                        heroScore
                        statsCard
                        actionPanel
                    }
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.top, proxy.safeAreaInsets.top + 8)
                    .padding(.bottom, max(16, proxy.safeAreaInsets.bottom + 8))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
                .fill(Color.white.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 52)
                .offset(x: -150, y: -300)

            Circle()
                .fill(Color(red: 0.72, green: 0.78, blue: 1.0).opacity(0.24))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 170, y: 340)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                coordinator.backToHome()
            } label: {
                Image(systemName: "house.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.24), in: Circle())
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.20), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(preferences.localized("results.header.title"))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(modeText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.80))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .gamePanel(cornerRadius: 20, highContrast: preferences.highContrastMode)
    }

    private var heroScore: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.38))
                Text(preferences.localized("results.best_attempt"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.84))
            }

            Text("\(summary.score)")
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.70)
                .lineLimit(1)
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 4)

            Text(preferences.localized("results.points"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .gamePanel(cornerRadius: 24, highContrast: preferences.highContrastMode)
    }

    private var statsCard: some View {
        VStack(spacing: 9) {
            statRow(title: preferences.localized("results.stat.turns"), value: "\(summary.turn)", icon: "number.circle.fill")
            statRow(title: preferences.localized("results.stat.clears"), value: "\(summary.clears)", icon: "rectangle.3.group.fill")
            statRow(title: preferences.localized("results.stat.combo_max"), value: "x\(max(1, summary.comboMax))", icon: "bolt.fill")
            statRow(title: preferences.localized("results.stat.duration"), value: durationText, icon: "clock.fill")
            statRow(title: preferences.localized("results.stat.continues"), value: "\(summary.rewardedContinues)", icon: "play.circle.fill")
        }
        .padding(14)
        .gamePanel(cornerRadius: 20, highContrast: preferences.highContrastMode)
    }

    private var actionPanel: some View {
        VStack(spacing: 10) {
            actionButton(
                title: preferences.localized("results.action.play_again"),
                colors: [Color(red: 0.28, green: 0.86, blue: 0.64), Color(red: 0.19, green: 0.63, blue: 0.96)]
            ) {
                coordinator.restartGame(mode: summary.mode)
            }

            actionButton(
                title: preferences.localized("results.action.change_mode"),
                colors: [Color(red: 1.0, green: 0.66, blue: 0.24), Color(red: 0.96, green: 0.42, blue: 0.32)]
            ) {
                coordinator.backToModeSelection()
            }

            actionButton(
                title: preferences.localized("results.action.home"),
                colors: [Color(red: 0.37, green: 0.56, blue: 0.95), Color(red: 0.27, green: 0.38, blue: 0.82)]
            ) {
                coordinator.backToHome()
            }
        }
        .padding(12)
        .gamePanel(cornerRadius: 18, highContrast: preferences.highContrastMode)
    }

    private func actionButton(title: String, colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func statRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 0.86, green: 0.92, blue: 1.0))
                .frame(width: 20, height: 20)
                .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.80))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var durationText: String {
        let mins = summary.durationSeconds / 60
        let secs = summary.durationSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var modeText: String {
        switch summary.mode {
        case .classic:
            return preferences.localized("mode.classic.title")
        case .dailyChallenge:
            return preferences.localized("mode.daily.title")
        }
    }
}
