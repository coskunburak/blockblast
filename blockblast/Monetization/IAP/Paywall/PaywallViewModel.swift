import Foundation

enum PaywallPlacement {
    case store
    case gameOver
}

@MainActor
final class PaywallViewModel: ObservableObject, Identifiable {
    let id = UUID()

    @Published private(set) var removeAdsProduct: StoreProduct
    @Published private(set) var starterPackProduct: StoreProduct?
    @Published private(set) var isPurchasingRemoveAds = false
    @Published private(set) var isPurchasingStarterPack = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var didCompletePurchase = false

    let placement: PaywallPlacement
    let variant: PaywallExperimentVariant
    let bundleBonusThemeID: String?

    private let purchaseManager: PurchaseManager
    private let analytics: AnalyticsTracking?
    private let onUnlockRemoveAds: (_ bundleBonusThemeID: String?) -> Void
    private let onStarterPackUnlocked: (_ product: StoreProduct) -> Void

    init(
        placement: PaywallPlacement,
        variant: PaywallExperimentVariant,
        removeAdsProduct: StoreProduct = Products.removeAds,
        starterPackProduct: StoreProduct? = Products.starterPack,
        bundleBonusThemeID: String?,
        purchaseManager: PurchaseManager,
        analytics: AnalyticsTracking? = nil,
        onUnlockRemoveAds: @escaping (_ bundleBonusThemeID: String?) -> Void,
        onStarterPackUnlocked: @escaping (_ product: StoreProduct) -> Void = { _ in }
    ) {
        self.placement = placement
        self.variant = variant
        self.removeAdsProduct = removeAdsProduct
        self.starterPackProduct = starterPackProduct
        self.bundleBonusThemeID = bundleBonusThemeID
        self.purchaseManager = purchaseManager
        self.analytics = analytics
        self.onUnlockRemoveAds = onUnlockRemoveAds
        self.onStarterPackUnlocked = onStarterPackUnlocked

        analytics?.track(AnalyticsFunnels.paywallView(placement: placement, variant: variant))
    }

    var title: String {
        titleKey
    }

    var titleKey: String {
        switch (placement, variant) {
        case (.gameOver, .valueBundle):
            return "paywall.title.game_over.bundle"
        case (.gameOver, .control):
            return "paywall.title.game_over.control"
        case (.store, .valueBundle):
            return "paywall.title.store.bundle"
        case (.store, .control):
            return "paywall.title.store.control"
        }
    }

    var subtitle: String {
        subtitleKey
    }

    var subtitleKey: String {
        switch (placement, variant) {
        case (.gameOver, .valueBundle):
            return "paywall.subtitle.game_over.bundle"
        case (.gameOver, .control):
            return "paywall.subtitle.game_over.control"
        case (.store, .valueBundle):
            return "paywall.subtitle.store.bundle"
        case (.store, .control):
            return "paywall.subtitle.store.control"
        }
    }

    var featureBullets: [String] {
        featureBulletKeys
    }

    var featureBulletKeys: [String] {
        var bullets = [
            "paywall.feature.no_interstitials",
            "paywall.feature.rewarded_optional",
            "paywall.feature.supports_updates"
        ]

        if variant == .valueBundle, bundleBonusThemeID != nil {
            bullets.insert("paywall.feature.bonus_theme", at: 1)
        }

        return bullets
    }

    var removeAdsCTA: String {
        removeAdsCTAKey
    }

    var removeAdsCTAKey: String {
        variant == .valueBundle ? "paywall.action.unlock_bundle" : "paywall.action.unlock_remove_ads"
    }

    func purchaseRemoveAds() {
        guard !isPurchasingAny else { return }
        isPurchasingRemoveAds = true
        errorMessage = nil
        infoMessage = nil

        Task {
            let purchased = await purchaseManager.purchaseRemoveAds()
            await MainActor.run {
                isPurchasingRemoveAds = false
                guard purchased else {
                    errorMessage = "Purchase could not be completed. Please try again."
                    analytics?.track(
                        AnalyticsFunnels.purchaseFail(
                            productID: removeAdsProduct.id,
                            placement: placement,
                            reason: "storekit_failed"
                        )
                    )
                    return
                }

                onUnlockRemoveAds(bundleBonusThemeID)
                infoMessage = variant == .valueBundle ? "Bundle unlocked successfully." : "Remove Ads unlocked."
                didCompletePurchase = true
                analytics?.track(
                    AnalyticsFunnels.purchaseSuccess(
                        productID: removeAdsProduct.id,
                        placement: placement
                    )
                )
            }
        }
    }

    func purchaseStarterPack() {
        guard !isPurchasingAny else { return }
        guard let starterPackProduct else { return }

        isPurchasingStarterPack = true
        errorMessage = nil
        infoMessage = nil

        Task {
            let purchased = await purchaseManager.purchaseStarterPack()
            await MainActor.run {
                isPurchasingStarterPack = false
                guard purchased else {
                    errorMessage = "Starter Pack purchase failed. Please try again."
                    analytics?.track(
                        AnalyticsFunnels.purchaseFail(
                            productID: starterPackProduct.id,
                            placement: placement,
                            reason: "storekit_failed"
                        )
                    )
                    return
                }

                onStarterPackUnlocked(starterPackProduct)
                infoMessage = "Starter Pack delivered."
                didCompletePurchase = true
                analytics?.track(
                    AnalyticsFunnels.purchaseSuccess(
                        productID: starterPackProduct.id,
                        placement: placement
                    )
                )
            }
        }
    }

    private var isPurchasingAny: Bool {
        isPurchasingRemoveAds || isPurchasingStarterPack
    }
}
