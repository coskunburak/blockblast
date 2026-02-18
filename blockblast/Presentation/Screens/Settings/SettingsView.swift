import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @ObservedObject var preferences: UserPreferencesStore
    @ObservedObject var consentManager: ConsentManager

    @State private var isSubmittingConsent = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        header
                        playSection
                        accessibilitySection
                        languageSection
                        trackingSection
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
                .frame(width: 300, height: 300)
                .blur(radius: 54)
                .offset(x: -150, y: -310)

            Circle()
                .fill(Color(red: 0.72, green: 0.78, blue: 1.0).opacity(0.24))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 180, y: 340)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(spacing: 12) {
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
                Text(preferences.localized("settings.title"))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(preferences.localized("settings.subtitle"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.80))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .gamePanel(cornerRadius: 20, highContrast: preferences.highContrastMode)
    }

    private var playSection: some View {
        sectionCard(title: preferences.localized("settings.play.title"), icon: "gamecontroller.fill") {
            settingToggle(
                title: preferences.localized("settings.play.sound"),
                subtitle: preferences.localized("settings.play.sound.subtitle"),
                isOn: $preferences.soundEnabled,
                tint: Color(red: 0.28, green: 0.86, blue: 0.62),
                accessibilityID: "settings.soundToggle"
            )

            settingToggle(
                title: preferences.localized("settings.play.haptics"),
                subtitle: preferences.localized("settings.play.haptics.subtitle"),
                isOn: $preferences.hapticsEnabled,
                tint: Color(red: 0.23, green: 0.72, blue: 1.0),
                accessibilityID: "settings.hapticsToggle"
            )
        }
    }

    private var accessibilitySection: some View {
        sectionCard(title: preferences.localized("settings.accessibility.title"), icon: "figure.wave") {
            settingToggle(
                title: preferences.localized("settings.accessibility.large_text"),
                subtitle: preferences.localized("settings.accessibility.large_text.subtitle"),
                isOn: $preferences.prefersLargeText,
                tint: Color(red: 1.0, green: 0.69, blue: 0.28),
                accessibilityID: "settings.largeTextToggle"
            )

            settingToggle(
                title: preferences.localized("settings.accessibility.high_contrast"),
                subtitle: preferences.localized("settings.accessibility.high_contrast.subtitle"),
                isOn: $preferences.highContrastMode,
                tint: Color(red: 0.98, green: 0.45, blue: 0.60),
                accessibilityID: "settings.highContrastToggle"
            )
        }
    }

    private var languageSection: some View {
        sectionCard(title: preferences.localized("settings.language.title"), icon: "globe") {
            Picker(selection: $preferences.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(languageTitle(language))
                        .tag(language)
                }
            } label: {
                Text(preferences.localized("settings.language.current"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .pickerStyle(.segmented)

            Text(preferences.localized("settings.language.subtitle"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var trackingSection: some View {
        sectionCard(title: preferences.localized("settings.tracking.title"), icon: "eye.fill") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preferences.localized("settings.tracking.status"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(trackingStatusText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.76))
                }

                Spacer()

                Button {
                    requestTracking()
                } label: {
                    if isSubmittingConsent {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 74)
                    } else {
                        Text(preferences.localized("settings.tracking.request"))
                            .font(.caption.weight(.bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.25, green: 0.73, blue: 1.0), Color(red: 0.18, green: 0.50, blue: 1.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
                .buttonStyle(.plain)
                .disabled(isSubmittingConsent)
                .opacity(isSubmittingConsent ? 0.75 : 1)
            }

            HStack(spacing: 10) {
                consentButton(title: preferences.localized("settings.tracking.allow"), granted: true)
                consentButton(title: preferences.localized("settings.tracking.deny"), granted: false)
            }
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.86, green: 0.92, blue: 1.0))
                    .frame(width: 22, height: 22)
                    .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            content()
        }
        .padding(14)
        .gamePanel(cornerRadius: 18, highContrast: preferences.highContrastMode)
    }

    private func settingToggle(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        tint: Color,
        accessibilityID: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: isOn) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .tint(tint)
            .accessibilityIdentifier(accessibilityID)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(10)
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func consentButton(title: String, granted: Bool) -> some View {
        Button(title) {
            submitConsent(granted: granted)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: granted ? [Color(red: 0.30, green: 0.86, blue: 0.63), Color(red: 0.22, green: 0.67, blue: 0.92)] :
                    [Color(red: 1.0, green: 0.66, blue: 0.24), Color(red: 0.95, green: 0.45, blue: 0.30)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .buttonStyle(.plain)
        .disabled(isSubmittingConsent)
        .opacity(isSubmittingConsent ? 0.55 : 1)
    }

    private func requestTracking() {
        Task {
            await MainActor.run {
                isSubmittingConsent = true
            }
            _ = await consentManager.requestTrackingIfNeeded()
            await MainActor.run {
                isSubmittingConsent = false
            }
        }
    }

    private func submitConsent(granted: Bool) {
        Task {
            await MainActor.run {
                isSubmittingConsent = true
            }
            await consentManager.submitUserConsent(granted: granted)
            await MainActor.run {
                isSubmittingConsent = false
            }
        }
    }

    private var trackingStatusText: String {
        switch consentManager.trackingStatus {
        case .authorized:
            return preferences.localized("settings.tracking.status.authorized")
        case .denied:
            return preferences.localized("settings.tracking.status.denied")
        case .restricted:
            return preferences.localized("settings.tracking.status.restricted")
        case .notDetermined:
            return preferences.localized("settings.tracking.status.not_determined")
        case .unavailable:
            return preferences.localized("settings.tracking.status.unavailable")
        }
    }

    private func languageTitle(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return preferences.localized("settings.language.system")
        case .english:
            return preferences.localized("settings.language.english")
        case .turkish:
            return preferences.localized("settings.language.turkish")
        }
    }
}
