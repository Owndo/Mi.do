//
//  SubscriptionManager.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/23/25.
//

import Foundation
import StoreKit

@Observable
public final class SubscriptionManager: SubscriptionManagerProtocol {
    let productIDs = ["yearly_base", "monthly_base"]
    
    public var products: [Product] = []
    
    private(set) var purchaseProductId = Set<String>()
    
    private var updatePurchase: Task<Void, Never>? = nil
    
    public init() {
        Task {
            updatePurchase = backgroundTransactionUpdate()
            await loadProducts()
        }
    }
    
    deinit {
        updatePurchase?.cancel()
    }
    
    public func hasSubscription() -> Bool {
        !purchaseProductId.isEmpty
    }
    
    public func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price < $1.price })
            print(products)
        } catch {
            print("Couldn't find products: \(error.localizedDescription)")
        }
    }
    
    public func makePurchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            await updatePurchase()
            print("Already has purchase")
            print(hasSubscription)
        case let .success(.unverified(_, error)):
            print("Valid purchase, but couldn't verified receipt \(error.localizedDescription)")
            break
        case .userCancelled:
            print("canceled")
            break
        case .pending:
            print("pending")
        default:
            print("error")
        }
    }
    
    func updatePurchase() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                purchaseProductId.insert(transaction.productID)
            } else {
                purchaseProductId.remove(transaction.productID)
            }
        }
        
    }
    
    public func restorePurchases() async {
        do {
            try await AppStore.sync()
            print("Restored")
        } catch {
            print("Nothing to restore")
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
