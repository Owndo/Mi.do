//
//  PaywallVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/23/25.
//

import Foundation
import Managers
import StoreKit

@Observable
final class PaywallVM {
    @ObservationIgnored
    @Injected(\.subscriptionManager) var subscriptionManager
    
    //MARK: - UI States
    var textForPaywall = "Achieve your goals many\ntimes faster!"
    var benefits = ["Voice tasks & voice notifications", "Create group, customize space", "History, sync, and stay on top"]
    
    //MARK: StoreKit
    var products: [Product] = []
    var selecetedProduct: Product?
    
    init() {
        products = subscriptionManager.products
        selecetedProduct = products.last
    }
    
    func hasSubscription() -> Bool {
        subscriptionManager.hasSubscription()
    }
    
    func makePurchase() async {
        guard let selecetedProduct else {
            
            return
        }
        
        do {
            try await subscriptionManager.makePurchase(selecetedProduct)
        } catch {
            print("error")
        }
    }
}
