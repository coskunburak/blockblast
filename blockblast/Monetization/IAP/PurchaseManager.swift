import Foundation

final class PurchaseManager {
    private let storeKitClient: StoreKitClientProtocol

    init(storeKitClient: StoreKitClientProtocol = DefaultStoreKitClient()) {
        self.storeKitClient = storeKitClient
    }

    func purchaseRemoveAds() async -> Bool {
        await purchase(productID: ProductID.removeAdsLifetime)
    }

    func purchaseStarterPack() async -> Bool {
        await purchase(productID: ProductID.starterPack)
    }

    private func purchase(productID: String) async -> Bool {
        (try? await storeKitClient.purchase(productID: productID)) ?? false
    }
}
