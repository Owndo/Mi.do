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
    
    func hasSubscription() -> Bool
    func makePurchase(_ product: Product) async throws
    func restorePurchases() async
    func loadProducts() async
}
