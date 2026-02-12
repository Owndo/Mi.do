//
//  SubscriptionManager.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/23/25.
//

import Foundation
import StoreKit
import SwiftUI

public final actor SubscriptionManager: SubscriptionManagerProtocol {
    
    //MARK: - States for UI
    
    private let productIDs = ["yearly_basegroup", "monthly_basegroup"]
    
    private var products: [Product] = []
    
    private(set) var purchaseProductId = Set<String>()
    
    nonisolated(unsafe) private var updatePurchase: Task<Void, Never>? = nil
    
    //MARK: Manager creator
    
    public static func createSubscriptionManager() async -> SubscriptionManagerProtocol {
        let subscriptionManager = SubscriptionManager()
        subscriptionManager.updatePurchase = await subscriptionManager.backgroundTransactionUpdate()
        await subscriptionManager.updatePurchase()
        
        return subscriptionManager
    }
    
    //MARK: - Create mock manager
    
    public static func createMockSubscriptionManager() -> SubscriptionManagerProtocol {
        SubscriptionManager()
    }
    
    deinit {
        updatePurchase?.cancel()
    }
    
    public func hasSubscription() -> Bool {
        !purchaseProductId.isEmpty
    }
    
    public func loadProducts() async throws -> [Product] {
        guard products.isEmpty else {
            return products
        }
        
        do {
            products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price < $1.price })
            return products
        } catch {
            print("Couldn't find products: \(error.localizedDescription)")
            throw SubscriptionManagerError.cannotLoadPurchases
        }
    }
    
    //MARK: - Make a purchase
    
    public func makePurchase(_ product: Product) async throws {
        
        let result = try await product.purchase()
        
        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            await updatePurchase()
        case .success(.unverified(_, _)):
            await updatePurchase()
        default:
            break
        }
    }
    
    //MARK: - Update a purchase
    
    public func updatePurchase() async {
        var activeProducts = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil,
               transaction.expirationDate == nil || transaction.expirationDate! > Date() {
                activeProducts.insert(transaction.productID)
            }
        }
        
        purchaseProductId = activeProducts
    }
    
    //MARK: - Restore
    
    public func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            return true
        } catch {
            return false
        }
    }
    
    private func backgroundTransactionUpdate() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await updatePurchase()
            }
        }
    }
}

enum SubscriptionManagerError: Error {
    case cannotLoadPurchases
}
