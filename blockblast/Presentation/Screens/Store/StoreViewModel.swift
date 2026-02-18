import Combine
import Foundation

@MainActor
final class StoreViewModel: ObservableObject {
    @Published private(set) var coins: Int = 0
    @Published private(set) var removeAdsEnabled: Bool = false
    @Published private(set) var starterPackPurchased: Bool = false
    @Published private(set) var blockThemes: [ThemeDefinition] = []
    @Published private(set) var gridThemes: [ThemeDefinition] = []
    @Published private(set) var equippedBlockThemeID: String = ""
    @Published private(set) var equippedGridThemeID: String = ""
    @Published var toast: String?

    private let meta: MetaProgressionStore
    private let purchaseManager: PurchaseManager
    private let analytics: AnalyticsTracking?
    private var cancellables: Set<AnyCancellable> = []

    init(
        meta: MetaProgressionStore,
        purchaseManager: PurchaseManager,
        analytics: AnalyticsTracking? = nil
    ) {
        self.meta = meta
        self.purchaseManager = purchaseManager
        self.analytics = analytics
        bindMeta()
        refresh()
    }

    func isOwned(_ theme: ThemeDefinition) -> Bool {
        meta.isOwned(themeID: theme.id)
    }

    func isEquipped(_ theme: ThemeDefinition) -> Bool {
        meta.isEquipped(themeID: theme.id)
    }

    func buyOrEquip(theme: ThemeDefinition) {
        if isOwned(theme) {
            meta.equipTheme(themeID: theme.id)
            toast = "Equipped \(theme.title)"
            refresh()
            return
        }

        switch meta.purchaseTheme(themeID: theme.id) {
        case let .purchased(cost):
            toast = "Unlocked \(theme.title) for \(cost) coins"
        case .alreadyOwned:
            toast = "Already owned"
        case let .insufficientFunds(required):
            toast = "Need \(required) coins"
        case .notFound:
            toast = "Item unavailable"
        }

        refresh()
    }

    func buyRemoveAds() {
        guard !removeAdsEnabled else {
            toast = "Remove Ads already active"
            return
        }

        Task {
            let success = await purchaseManager.purchaseRemoveAds()
            guard success else {
                await MainActor.run {
                    toast = "Purchase failed"
                    analytics?.track(
                        AnalyticsFunnels.purchaseFail(
                            productID: Products.removeAds.id,
                            placement: .store,
                            reason: "storekit_failed"
                        )
                    )
                }
                return
            }

            await MainActor.run {
                meta.unlockRemoveAds()
                toast = "Remove Ads unlocked"
                analytics?.track(
                    AnalyticsFunnels.purchaseSuccess(
                        productID: Products.removeAds.id,
                        placement: .store
                    )
                )
                refresh()
            }
        }
    }

    func buyStarterPack() {
        guard !starterPackPurchased else {
            toast = "Starter Pack already claimed"
            return
        }

        Task {
            let success = await purchaseManager.purchaseStarterPack()
            guard success else {
                await MainActor.run {
                    toast = "Starter Pack purchase failed"
                    analytics?.track(
                        AnalyticsFunnels.purchaseFail(
                            productID: Products.starterPack.id,
                            placement: .store,
                            reason: "storekit_failed"
                        )
                    )
                }
                return
            }

            await MainActor.run {
                let applied = meta.applyStarterPack(product: Products.starterPack)
                toast = applied ? "Starter Pack delivered" : "Starter Pack already claimed"
                if applied {
                    analytics?.track(
                        AnalyticsFunnels.purchaseSuccess(
                            productID: Products.starterPack.id,
                            placement: .store
                        )
                    )
                }
                refresh()
            }
        }
    }

    func makePaywallViewModel() -> PaywallViewModel {
        PaywallViewModel(
            placement: .store,
            variant: .valueBundle,
            bundleBonusThemeID: MonetizationRemoteConfig.fallback.removeAdsBundleBonusThemeID,
            purchaseManager: purchaseManager,
            analytics: analytics
        ) { [weak self] bonusThemeID in
            guard let self else { return }
            meta.unlockRemoveAds()
            if let bonusThemeID {
                meta.grantTheme(themeID: bonusThemeID, autoEquip: true)
            }
            toast = "Remove Ads unlocked"
            refresh()
        } onStarterPackUnlocked: { [weak self] product in
            guard let self else { return }
            _ = meta.applyStarterPack(product: product)
            toast = "Starter Pack delivered"
            refresh()
        }
    }

    private func bindMeta() {
        meta.objectWillChange
            .sink { [weak self] in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        coins = meta.coins
        removeAdsEnabled = meta.removeAdsEnabled
        starterPackPurchased = meta.starterPackPurchased
        blockThemes = meta.catalog.blockThemes
        gridThemes = meta.catalog.gridThemes
        equippedBlockThemeID = meta.equippedBlockThemeID
        equippedGridThemeID = meta.equippedGridThemeID
    }
}
