import Foundation

protocol StoreKitClientProtocol {
    func purchase(productID: String) async throws -> Bool
}

struct DefaultStoreKitClient: StoreKitClientProtocol {
    private let fallback: StoreKitClientProtocol

    init(fallback: StoreKitClientProtocol = MockStoreKitClient()) {
        self.fallback = fallback
    }

    func purchase(productID: String) async throws -> Bool {
        #if canImport(StoreKit)
        if #available(iOS 15.0, *) {
            do {
                return try await StoreKit2Client.purchase(productID: productID)
            } catch {
                return try await fallback.purchase(productID: productID)
            }
        }
        #endif
        return try await fallback.purchase(productID: productID)
    }
}

struct MockStoreKitClient: StoreKitClientProtocol {
    func purchase(productID: String) async throws -> Bool {
        true
    }
}

#if canImport(StoreKit)
import StoreKit

@available(iOS 15.0, *)
private enum StoreKit2Client {
    static func purchase(productID: String) async throws -> Bool {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else { return false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified:
                return true
            case .unverified:
                return false
            }
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }
}
#endif
