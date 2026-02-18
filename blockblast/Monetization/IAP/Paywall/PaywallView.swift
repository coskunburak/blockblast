import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: UserPreferencesStore
    @ObservedObject var viewModel: PaywallViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.17),
                    Color(red: 0.07, green: 0.11, blue: 0.22),
                    Color(red: 0.13, green: 0.08, blue: 0.17)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text(preferences.localized(viewModel.titleKey))
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)

                Text(preferences.localized(viewModel.subtitleKey))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.featureBulletKeys, id: \.self) { bulletKey in
                        featureRow(preferences.localized(bulletKey))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.removeAdsProduct.displayPrice)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text(viewModel.removeAdsProduct.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                if let info = viewModel.infoMessage {
                    Text(info)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.green.opacity(0.95))
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red.opacity(0.95))
                }

                Button {
                    viewModel.purchaseRemoveAds()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isPurchasingRemoveAds {
                            ProgressView().tint(.white)
                        }
                        Text(
                            viewModel.isPurchasingRemoveAds
                            ? preferences.localized("paywall.action.processing")
                            : preferences.localized(viewModel.removeAdsCTAKey)
                        )
                            .font(.headline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(viewModel.isPurchasingStarterPack || viewModel.isPurchasingRemoveAds)

                if let starter = viewModel.starterPackProduct {
                    Button {
                        viewModel.purchaseStarterPack()
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isPurchasingStarterPack {
                                ProgressView().tint(.white)
                            }
                            Text(
                                viewModel.isPurchasingStarterPack
                                ? preferences.localized("paywall.action.processing")
                                : "\(starter.title) \(starter.displayPrice)"
                            )
                            .font(.subheadline.weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isPurchasingRemoveAds || viewModel.isPurchasingStarterPack)
                    .tint(.blue)
                }

                Button(preferences.localized("paywall.action.not_now")) {
                    dismiss()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
            }
            .padding(22)
        }
        .interactiveDismissDisabled(viewModel.isPurchasingRemoveAds || viewModel.isPurchasingStarterPack)
        .onChange(of: viewModel.didCompletePurchase) { _, completed in
            guard completed else { return }
            dismiss()
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.93))
        }
    }
}
