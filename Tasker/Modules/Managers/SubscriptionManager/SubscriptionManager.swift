//
//  SubscriptionManager.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/23/25.
//

import Foundation
import StoreKit
import SwiftUICore
import Models

@Observable
public final class SubscriptionManager: SubscriptionManagerProtocol {
    //    @ObservationIgnored
    //    @Injected(\.casManager) var casManager
    
    //MARK: States for UI
    //    var profileModel: ProfileData?
    public var showPaywall = false
    public var pending = false
    
    let productIDs = ["yearly_base", "monthly_base"]
    
    public var products: [Product] = []
    
    private(set) var purchaseProductId = Set<String>()
    
    private var updatePurchase: Task<Void, Never>? = nil
    
    public init() {
        Task {
            updatePurchase = backgroundTransactionUpdate()
            await loadProducts()
        }
        
        //        profileModel = casManager.profileModel
    }
    
    deinit {
        updatePurchase?.cancel()
    }
    
    public func closePaywall() {
        showPaywall = false
    }
    
    public func hasSubscription() -> Bool {
        //       if let model = profileModel {
        //           if model.value.createdProfile + 86400 > Date.now.timeIntervalSince1970 {
        //               return true
        //           }
        //        }
        
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
    
    //MARK: - Make a purchase
    public func makePurchase(_ product: Product) async throws {
        pending = true
        
        let result = try await product.purchase()
        
        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            await updatePurchase()
            showPaywall = false
            pending = false
        case let .success(.unverified(_, error)):
            print("Valid purchase, but couldn't verified receipt \(error.localizedDescription)")
            await updatePurchase()
            showPaywall = false
            pending = false
            break
        case .userCancelled:
            pending = false
            break
        case .pending:
            print("pending")
        default:
            pending = false
        }
        
        pending = false
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
        pending = true
        
        do {
            try await AppStore.sync()
            pending = false
        } catch {
            pending = false
            return false
        }
        
        return true
    }
    
    private func backgroundTransactionUpdate() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await updatePurchase()
            }
        }
    }
}

//MARK: - Extension
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
        return "\(formattedPrice)"
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
        return "\(formattedPrice)"
    }
    
    var dividedYearByWeek: String {
        guard subscription?.subscriptionPeriod.unit == .year else { return "" }
        
        let monthlyPrice = price / 52
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = priceFormatStyle.currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        guard let formattedPrice = formatter.string(from: monthlyPrice as NSDecimalNumber) else { return "" }
        return "\(formattedPrice)"
    }
}

public extension Product {
    func intoductoryOffer() -> LocalizedStringKey? {
        if let offer = self.subscription?.introductoryOffer {
            switch offer.period {
            case .weekly:
                return "Free week"
            default:
                return nil
            }
        }
        return nil
    }
}

public extension Product.SubscriptionPeriod.Unit {
    var periodDescription: LocalizedStringKey {
        switch self {
        case .day:
            return "/ day"
        case .week:
            return "/ week"
        case .month:
            return "/ month"
        case .year:
            return "/ year"
        default:
            return ""
        }
    }
    
    var devidedPeriodByWeek: LocalizedStringKey {
        switch self {
        case .day:
            return " / week"
        case .week:
            return " / week"
        case .month:
            return " / week"
        case .year:
            return " / week"
        default:
            return ""
        }
    }
}
