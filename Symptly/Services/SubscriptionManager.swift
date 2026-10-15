import SwiftUI
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productIds = [
        "com.symptly.monthly",
        "com.symptly.yearly"
    ]

    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }

    init() {
        Task {
            await loadProducts()
            await restorePurchases()
        }
        Task { await listenForTransactions() }
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            purchasedProductIDs.insert(product.id)
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        // Start fresh: only keep currently valid entitlements
        var activeIDs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                activeIDs.insert(transaction.productID)
            }
        }
        purchasedProductIDs = activeIDs
    }

    /// Re-check entitlements (call on app foreground to catch expirations)
    func refreshSubscriptionStatus() async {
        var activeIDs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                activeIDs.insert(transaction.productID)
            }
        }
        purchasedProductIDs = activeIDs
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate != nil {
                    purchasedProductIDs.remove(transaction.productID)
                } else {
                    purchasedProductIDs.insert(transaction.productID)
                }
                await transaction.finish()
            }
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
