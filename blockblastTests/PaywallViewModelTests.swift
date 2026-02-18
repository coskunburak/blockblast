import Foundation
import Testing
@testable import blockblast

@MainActor
struct PaywallViewModelTests {
    @Test func removeAdsPurchaseUnlocksBundleThemeWhenVariantIsValueBundle() async {
        let manager = PurchaseManager(storeKitClient: StubStoreKitClient(successProductIDs: [ProductID.removeAdsLifetime]))
        var unlockedThemeID: String?

        let viewModel = PaywallViewModel(
            placement: .gameOver,
            variant: .valueBundle,
            bundleBonusThemeID: "theme.grid.ember",
            purchaseManager: manager
        ) { themeID in
            unlockedThemeID = themeID
        }

        viewModel.purchaseRemoveAds()
        await waitUntil { viewModel.didCompletePurchase }

        #expect(viewModel.didCompletePurchase == true)
        #expect(unlockedThemeID == "theme.grid.ember")
    }

    @Test func starterPackPurchaseFailureEmitsError() async {
        let manager = PurchaseManager(storeKitClient: StubStoreKitClient(successProductIDs: []))
        var delivered = false

        let viewModel = PaywallViewModel(
            placement: .store,
            variant: .control,
            bundleBonusThemeID: nil,
            purchaseManager: manager,
            onUnlockRemoveAds: { _ in },
            onStarterPackUnlocked: { _ in delivered = true }
        )

        viewModel.purchaseStarterPack()
        await waitUntil { viewModel.errorMessage != nil }

        #expect(delivered == false)
        #expect(viewModel.errorMessage != nil)
    }
}

private struct StubStoreKitClient: StoreKitClientProtocol {
    let successProductIDs: Set<String>

    init(successProductIDs: Set<String>) {
        self.successProductIDs = successProductIDs
    }

    func purchase(productID: String) async throws -> Bool {
        successProductIDs.contains(productID)
    }
}

@MainActor
private func waitUntil(
    timeoutNanoseconds: UInt64 = 1_500_000_000,
    condition: @escaping () -> Bool
) async {
    let start = DispatchTime.now().uptimeNanoseconds
    while !condition() {
        if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds {
            break
        }
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}
