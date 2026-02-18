import Foundation

enum ProductID {
    static let removeAdsLifetime = "remove_ads_lifetime"
    static let starterPack = "starter_pack"
    static let premiumMonthly = "premium_monthly"
}

struct StoreProduct: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let displayPrice: String
    let coinGrant: Int
    let bonusThemeID: String?
}

enum Products {
    static let removeAds = StoreProduct(
        id: ProductID.removeAdsLifetime,
        title: "Remove Ads",
        subtitle: "Permanently disable interstitial ads.",
        displayPrice: "$4.99",
        coinGrant: 0,
        bonusThemeID: nil
    )

    static let starterPack = StoreProduct(
        id: ProductID.starterPack,
        title: "Starter Pack",
        subtitle: "500 coins + an exclusive premium theme.",
        displayPrice: "$2.99",
        coinGrant: 500,
        bonusThemeID: "theme.block.ice"
    )

    static let all: [StoreProduct] = [removeAds, starterPack]
}
