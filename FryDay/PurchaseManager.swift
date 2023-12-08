//
//  PurchaseManager.swift
//  FryDay
//
//  Created by Theo Goodman on 11/30/23.
//

import Foundation
import StoreKit

@MainActor
class PurchaseManager: NSObject, ObservableObject {

    private let productIds: Set<String> = [
        "filters.diets.glutenFree",
        "filters.diets.vegetarian",
        "filters.diets.vegan",
        "filters.keyIngredients.chicken",
        "filters.keyIngredients.groundBeef",
        "filters.keyIngredients.pasta",
        "filters.keyIngredients.tofuTempeh",
        "filters.keyIngredients.legumes",
        "filters.keyIngredients.fish",
        "filters.keyIngredients.sausage",
        "filters.cuisines.asian",
        "filters.cuisines.french",
        "filters.cuisines.italian",
        "filters.cuisines.mediterranean",
        "filters.cuisines.mexican",
        "filters.cuisines.middleEastern",
        "filters.mealTypes.dinner",
        "filters.mealTypes.breakfast",
        "filters.mealTypes.onePot",
        "filters.mealTypes.underThirtyMin",
        
    ]

    @Published
    private(set) var products: [Product] = []
    @Published
    private(set) var purchasedProductIDs = Set<String>()

    var hasUnlockedPro: Bool {
           return !self.purchasedProductIDs.isEmpty
        }
    
    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil

    override init() {
        super.init()
        self.updates = observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }

    deinit {
        self.updates?.cancel()
    }

    func loadProducts() async throws {
        guard !self.productsLoaded else { return }
        self.products = try await Product.products(for: productIds)
//        self.products.forEach({ print("product display name: \($0.displayName)") })
        self.productsLoaded = true
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            // Successful purchase
            await transaction.finish()
            await self.updatePurchasedProducts()
        case let .success(.unverified(_, error)):
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            break
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            break
        case .userCancelled:
            // ^^^
            break
        @unknown default:
            break
        }
    }

    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await verificationResult in Transaction.updates {
                // Using verificationResult directly would be better
                // but this way works for this tutorial
                await self.updatePurchasedProducts()
            }
        }
    }
}

extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

    }

    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}
