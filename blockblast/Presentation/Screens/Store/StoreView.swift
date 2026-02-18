import SwiftUI

struct StoreView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var preferences: UserPreferencesStore
    @ObservedObject var viewModel: StoreViewModel
    @State private var showPaywall = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        header
                        walletCard
                        offerCard(
                            title: preferences.localized("store.remove_ads"),
                            subtitle: preferences.localized("store.remove_ads.subtitle"),
                            price: Products.removeAds.displayPrice,
                            actionTitle: viewModel.removeAdsEnabled ? preferences.localized("store.state.purchased") : preferences.localized("store.action.buy"),
                            colors: [Color(red: 1.0, green: 0.66, blue: 0.22), Color(red: 0.96, green: 0.43, blue: 0.30)],
                            isDisabled: viewModel.removeAdsEnabled
                        ) {
                            if !viewModel.removeAdsEnabled {
                                showPaywall = true
                            }
                        }
                        .accessibilityIdentifier("store.removeAdsButton")

                        offerCard(
                            title: preferences.localized("store.starter_pack"),
                            subtitle: preferences.localized("store.starter_pack.subtitle"),
                            price: Products.starterPack.displayPrice,
                            actionTitle: viewModel.starterPackPurchased ? preferences.localized("store.state.claimed") : preferences.localized("store.action.buy"),
                            colors: [Color(red: 0.24, green: 0.72, blue: 1.0), Color(red: 0.18, green: 0.48, blue: 1.0)],
                            isDisabled: viewModel.starterPackPurchased
                        ) {
                            viewModel.buyStarterPack()
                        }
                        .accessibilityIdentifier("store.starterPackButton")

                        themeSection(title: preferences.localized("store.section.block_themes"), themes: viewModel.blockThemes)
                        themeSection(title: preferences.localized("store.section.grid_themes"), themes: viewModel.gridThemes)
                    }
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                    .padding(.horizontal, 12)
                    .padding(.top, proxy.safeAreaInsets.top + 8)
                    .padding(.bottom, max(18, proxy.safeAreaInsets.bottom + 12))
                }
                .defaultScrollAnchor(.top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView(viewModel: viewModel.makePaywallViewModel())
        }
        .overlay(alignment: .bottom) {
            if let toast = viewModel.toast {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.26), in: Capsule())
                    .overlay {
                        Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
                    }
                    .padding(.bottom, 18)
                    .task {
                        try? await Task.sleep(for: .seconds(2))
                        await MainActor.run {
                            withAnimation {
                                viewModel.toast = nil
                            }
                        }
                    }
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
                .fill(Color.white.opacity(0.16))
                .frame(width: 290, height: 290)
                .blur(radius: 52)
                .offset(x: -150, y: -300)

            Circle()
                .fill(Color(red: 0.72, green: 0.78, blue: 1.0).opacity(0.24))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 170, y: 350)
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
                Text(preferences.localized("store.title"))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(preferences.localized("store.subtitle"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.80))
            }

            Spacer()
        }
        .padding(14)
        .gamePanel(cornerRadius: 20, highContrast: preferences.highContrastMode)
    }

    private var walletCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.32).opacity(0.28))
                    .frame(width: 40, height: 40)
                Image(systemName: "crown.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.38))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(preferences.localized("store.wallet"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                Text(preferences.localized("store.wallet.coins", viewModel.coins))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
            }

            Spacer()

            Text(preferences.localized("store.cosmetic_only"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.20), in: Capsule())
        }
        .padding(14)
        .gamePanel(cornerRadius: 18, highContrast: preferences.highContrastMode)
    }

    private func offerCard(
        title: String,
        subtitle: String,
        price: String,
        actionTitle: String,
        colors: [Color],
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.74))

            HStack {
                Text(price)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)
                Spacer()
                neonButton(
                    title: actionTitle,
                    colors: colors,
                    isDisabled: isDisabled,
                    action: action
                )
            }
        }
        .padding(14)
        .gamePanel(cornerRadius: 18, highContrast: preferences.highContrastMode)
    }

    private func themeSection(title: String, themes: [ThemeDefinition]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)

            ForEach(themes) { theme in
                HStack(spacing: 12) {
                    preview(theme)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(theme.title)
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(.white)
                            rarityBadge(theme.rarity)
                        }
                        Text(theme.subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.70))
                        detailChips(theme)
                    }

                    Spacer()

                    themeActionButton(theme)
                }
                .padding(10)
                .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
            }
        }
        .padding(14)
        .gamePanel(cornerRadius: 18, highContrast: preferences.highContrastMode)
    }

    @ViewBuilder
    private func themeActionButton(_ theme: ThemeDefinition) -> some View {
        let action = actionTitle(for: theme)
        let equipped = viewModel.isEquipped(theme)
        let owned = viewModel.isOwned(theme)
        let free = theme.isFree

        Button(action) {
            viewModel.buyOrEquip(theme: theme)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            LinearGradient(
                colors: equipped ? [Color(red: 0.28, green: 0.85, blue: 0.64), Color(red: 0.21, green: 0.66, blue: 0.94)] :
                    (owned || free ? [Color(red: 0.26, green: 0.73, blue: 1.0), Color(red: 0.17, green: 0.50, blue: 1.0)] :
                        purchaseGradient(for: theme.rarity)),
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .buttonStyle(.plain)
    }

    private func neonButton(
        title: String,
        colors: [Color],
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(title) {
            action()
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }

    private func preview(_ theme: ThemeDefinition) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 5).fill(theme.accentA)
            RoundedRectangle(cornerRadius: 5).fill(theme.accentB)
            RoundedRectangle(cornerRadius: 5).fill(theme.accentC)
        }
        .frame(width: 62, height: 28)
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
    }

    private func actionTitle(for theme: ThemeDefinition) -> String {
        if viewModel.isEquipped(theme) {
            return preferences.localized("store.state.equipped")
        }

        if viewModel.isOwned(theme) {
            return preferences.localized("store.action.equip")
        }

        if theme.isFree {
            return preferences.localized("store.state.free")
        }

        return "\(theme.priceCoins.formatted()) pts"
    }

    private func rarityBadge(_ rarity: ThemeRarity) -> some View {
        Text(rarity.displayName.uppercased())
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                LinearGradient(
                    colors: purchaseGradient(for: rarity).map { $0.opacity(0.86) },
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .overlay {
                Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
    }

    private func detailChips(_ theme: ThemeDefinition) -> some View {
        HStack(spacing: 4) {
            ForEach(theme.detailTags.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.10), in: Capsule())
                    .overlay {
                        Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
            }
        }
    }

    private func purchaseGradient(for rarity: ThemeRarity) -> [Color] {
        switch rarity {
        case .starter, .premium:
            return [Color(red: 1.0, green: 0.68, blue: 0.20), Color(red: 0.96, green: 0.45, blue: 0.26)]
        case .rare:
            return [Color(red: 0.25, green: 0.82, blue: 0.62), Color(red: 0.16, green: 0.56, blue: 0.88)]
        case .epic:
            return [Color(red: 0.41, green: 0.52, blue: 1.00), Color(red: 0.67, green: 0.36, blue: 0.98)]
        case .legendary:
            return [Color(red: 0.99, green: 0.74, blue: 0.26), Color(red: 0.95, green: 0.43, blue: 0.18)]
        case .mythic:
            return [Color(red: 0.93, green: 0.79, blue: 0.98), Color(red: 0.56, green: 0.44, blue: 0.98)]
        }
    }
}
