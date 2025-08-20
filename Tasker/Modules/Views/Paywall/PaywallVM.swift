//
//  PaywallVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/23/25.
//

import Foundation
import Managers
import StoreKit
import SwiftUICore

@Observable
final class PaywallVM {
    @ObservationIgnored
    @Injected(\.subscriptionManager) var subscriptionManager
    
    //MARK: - UI States
    var textForPaywall: LocalizedStringKey = "Plan with ease\nLive with joy\nLess tasks, more life!"
    var benefits = ["Voice tasks & voice notifications", "Create group, customize space", "History, sync, and stay on top"]
    var showingAlert = false
    
    //MARK: StoreKit
    var products: [Product] = []
    var selecetedProduct: Product?
    
    var pending: Bool {
        subscriptionManager.pending
    }
    
    var textForButton: LocalizedStringKey = "Continue"
    
    init() {
        products = subscriptionManager.products
        selecetedProduct = products.first
        
        if let product = selecetedProduct {
            Task {
                await selectProductButtonTapped(product)
            }
        }
    }
    
    func selectProductButtonTapped(_ product: Product) async {
        selecetedProduct = product
        
        guard let selecetedProduct = self.selecetedProduct else {
            return
        }
        
        guard await selecetedProduct.isEligibleForFreeTrial() else {
            return
        }
        
        if selecetedProduct.intoductoryOffer() != nil {
            textForButton = "Try for free"
        } else {
            textForButton = "Continue"
        }
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
    
    func restoreButtonTapped() async {
        showingAlert = await !subscriptionManager.restorePurchases()
    }
    
    func closePaywallButtonTapped() {
        subscriptionManager.closePaywall()
    }
}
