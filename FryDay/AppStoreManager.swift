//
//  AppStoreManager.swift
//  FryDay
//
//  Created by Theo Goodman on 11/30/23.
//

import Foundation
import StoreKit
import OSLog

@MainActor
class AppStoreManager: NSObject, ObservableObject {
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil
    
//    var hasUnlockedPro: Bool { !self.purchasedProductIDs.isEmpty }

    override init() {
        super.init()
        self.updates = observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }

    deinit {
        self.updates?.cancel()
    }

    func loadAppStoreProducts(for categories: [Category]) async throws {
        guard !categories.isEmpty else { return }
            
        // Fetch App Store products
        if !self.productsLoaded{
            let categoryIds = categories.map({ $0.appStoreProductId })
            self.products = try await Product.products(for: categoryIds)
            if !products.isEmpty{ self.productsLoaded = true }
        }
        
        // Connect Filters w/ App Store Produts
        for category in categories {
            let appStoreProduct = products.first(where: { $0.id == category.appStoreProductId })
            category.appStoreProduct = appStoreProduct
//            print("### Category: \(category.title) assigned product: \(category.appStoreProduct)")
        }
    }

    func purchase(_ product: Product) async throws -> Product.PurchaseResult {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            // Successful purchase
            await transaction.finish()
            await self.updatePurchasedProducts()
            Logger.store.info("Purchase succeeded.")
        case let .success(.unverified(_, error)):
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            Logger.store.info("Purchase succeeded: but not verified.")
            break
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            Logger.store.warning("Purchase failed: it's pending")
            break
        case .userCancelled:
            // ^^^
            Logger.store.warning("Purchase failed: user cancelled.")
            break
        @unknown default:
            Logger.store.warning("Purchase failed: unknown reason.")
            break
        }
        
        return result
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

extension AppStoreManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) { }

    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}


//    private let productIds: Set<String> = [
//        "filters.diets.glutenFree",
//        "filters.diets.vegetarian",
//        "filters.diets.vegan",
//        "filters.keyIngredients.chicken",
//        "filters.keyIngredients.groundBeef",
//        "filters.keyIngredients.pasta",
//        "filters.keyIngredients.tofuTempeh",
//        "filters.keyIngredients.legumes",
//        "filters.keyIngredients.fish",
//        "filters.keyIngredients.sausage",
//        "filters.cuisines.asian",
//        "filters.cuisines.french",
//        "filters.cuisines.italian",
//        "filters.cuisines.mediterranean",
//        "filters.cuisines.mexican",
//        "filters.cuisines.middleEastern",
//        "filters.mealTypes.dinner",
//        "filters.mealTypes.breakfast",
//        "filters.mealTypes.onePot",
//        "filters.mealTypes.underThirtyMin",
//    ]
