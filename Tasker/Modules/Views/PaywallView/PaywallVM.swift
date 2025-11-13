//
//  PaywallVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/23/25.
//

import Foundation
import Managers
import StoreKit
import SwiftUI

@Observable
public final class PaywallVM {
    private let subscriptionManager: SubscriptionManagerProtocol
    
    //MARK: - UI States
    
    var textForPaywall: LocalizedStringKey = "Plan with ease\nLive with joy\nLess tasks, more life!"
    var benefits = ["Voice tasks & voice notifications", "Create group, customize space", "History, sync, and stay on top"]
    
    var textForButton: LocalizedStringKey = "Continue"
    
    var showingAlert = false
    
    //MARK: StoreKit
    var products: [Product] = []
    var selecetedProduct: Product?
    
    var pending: Bool {
        subscriptionManager.pending
    }
    
    //MARK: - Private init
    
    private init(subscriptionManager: SubscriptionManagerProtocol) {
        self.subscriptionManager = subscriptionManager
    }
    
    
    //MARK: - VM Creator
    
    public static func createPaywallVM(_ subscriptionManager: SubscriptionManagerProtocol) async -> PaywallVM {
        let vm = PaywallVM(subscriptionManager: subscriptionManager)
        await vm.updateProdicts()
        
        return vm
    }
    
    //MARK: - Preview VM
    
    static func createPreviewVM() -> PaywallVM {
        PaywallVM(subscriptionManager: SubscriptionManager.createMockSubscriptionManager())
    }
    
    private func updateProdicts() async {
        products = subscriptionManager.products
        selecetedProduct = products.first
        
        if let product = selecetedProduct {
            await selectProductButtonTapped(product)
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
