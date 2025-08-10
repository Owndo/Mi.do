//
//  SubscriptionManagerProtocol.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/23/25.
//

import Foundation
import StoreKit

public protocol SubscriptionManagerProtocol {
    var products: [Product] { get set }
    var showPaywall: Bool { get set }
    var pending: Bool { get set }
    var subscribed: Bool { get set }
    
    func hasSubscription() -> Bool
    func makePurchase(_ product: Product) async throws
    func updatePurchase() async
    func restorePurchases() async -> Bool
    func loadProducts() async
    func closePaywall()
}
