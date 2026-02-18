import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var preferences: UserPreferencesStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer

                VStack(spacing: 14) {
                    header

                    modeCard(
                        title: preferences.localized("mode.classic.title"),
                        subtitle: preferences.localized("mode.classic.subtitle"),
                        detail: preferences.localized("mode.classic.detail"),
                        badge: preferences.localized("mode.classic.badge"),
                        colors: [Color(red: 0.18, green: 0.84, blue: 0.66), Color(red: 0.24, green: 0.56, blue: 1.0)],
                        icon: "infinity",
                        buttonID: "mode.classic.start"
                    ) {
                        coordinator.goToGame(mode: .classic)
                    }

                    modeCard(
                        title: preferences.localized("mode.daily.title"),
                        subtitle: preferences.localized("mode.daily.subtitle"),
                        detail: preferences.localized("mode.daily.detail"),
                        badge: preferences.localized("mode.daily.badge"),
                        colors: [Color(red: 1.0, green: 0.64, blue: 0.22), Color(red: 0.96, green: 0.35, blue: 0.42)],
                        icon: "calendar",
                        buttonID: "mode.daily.start"
                    ) {
                        coordinator.goToGame(mode: .dailyChallenge)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.top, proxy.safeAreaInsets.top + 8)
                .padding(.bottom, max(14, proxy.safeAreaInsets.bottom + 6))
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
                .offset(x: -140, y: -310)

            Circle()
                .fill(Color(red: 0.72, green: 0.78, blue: 1.0).opacity(0.22))
                .frame(width: 290, height: 290)
                .blur(radius: 58)
                .offset(x: 170, y: 340)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                coordinator.backToHome()
            } label: {
                Image(systemName: "chevron.left")
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
                Text(preferences.localized("mode.header.title"))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(preferences.localized("mode.header.subtitle"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(14)
        .gamePanel(cornerRadius: 20, highContrast: preferences.highContrastMode)
    }

    private func modeCard(
        title: String,
        subtitle: String,
        detail: String,
        badge: String,
        colors: [Color],
        icon: String,
        buttonID: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(colors[0].opacity(0.42))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                Text(badge)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.28), in: Capsule())
            }

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.76))

            Button {
                action()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.bold))
                    Text(preferences.localized("mode.cta.play"))
                        .font(.headline.weight(.heavy))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(buttonID)
        }
        .padding(16)
        .gamePanel(cornerRadius: 24, highContrast: preferences.highContrastMode)
    }
}
