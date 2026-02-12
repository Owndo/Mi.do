//
//  MockSubscriptionManager.swift
//  SubscriptionManager
//
//  Created by Rodion Akhmedov on 12/12/25.
//

import Foundation
import StoreKit

public actor MockSubscriptionManager: SubscriptionManagerProtocol {
    private let productIDs = ["yearly_basegroup", "monthly_basegroup"]
    private var products: [Product] = []
    
    nonisolated(unsafe) var subscribed = false
    
    private(set) var purchaseProductId = Set<String>()
    nonisolated(unsafe) private var updatePurchase: Task<Void, Never>? = nil
    
    deinit {
        updatePurchase?.cancel()
    }
    
    //MARK: - Subscribed manager
    
    public static func createSubscribedManager() -> SubscriptionManagerProtocol {
        let manager = MockSubscriptionManager()
        manager.subscribed = true
        
        return manager
    }
    
    //MARK: - NonSubscribed manager
    
    public static func createNotSubscribedManager() -> SubscriptionManagerProtocol {
        MockSubscriptionManager()
    }
    
    public func hasSubscription() -> Bool {
        subscribed
    }
    
    public func makePurchase(_ product: Product) async throws {
        
    }
    
    public func updatePurchase() async {
        
    }
    
    public func restorePurchases() async -> Bool {
        true
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
}
