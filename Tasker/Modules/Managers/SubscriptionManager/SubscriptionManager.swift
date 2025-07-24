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
    
    public var showPaywall = false
    public var pending = false
    
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
    
    public func closePaywall() {
        showPaywall = false
    }
    
    public func hasSubscription() -> Bool {
        guard purchaseProductId.isEmpty else {
            return true
        }
        
        showPaywall = true
        return false
    }
    
    public func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price < $1.price })
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
            showPaywall = false
            print("Already has purchase")
            print(hasSubscription)
        case let .success(.unverified(_, error)):
            print("Valid purchase, but couldn't verified receipt \(error.localizedDescription)")
            showPaywall = false
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
        pending = true
        do {
            try await AppStore.sync()
            pending = false
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

public extension Product {
    var dividedByWeek: String {
        guard let unit = subscription?.subscriptionPeriod.unit else { return "" }
        
        let divisor: Decimal = unit == .month ? 4 : unit == .year ? 48 : 0
        guard divisor > 0 else { return "" }
        
        let weeklyPrice = price / divisor
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = priceFormatStyle.currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        guard let formattedPrice = formatter.string(from: weeklyPrice as NSDecimalNumber) else { return "" }
        return "\(formattedPrice) / week"
    }
    
    var dividedByMonth: String {
        guard subscription?.subscriptionPeriod.unit == .year else { return "" }
        
        let monthlyPrice = price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = priceFormatStyle.currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        guard let formattedPrice = formatter.string(from: monthlyPrice as NSDecimalNumber) else { return "" }
        return "\(formattedPrice) / month"
    }
}
