//
//  PaywallVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/23/25.
//

import Foundation
import StoreKit
import SwiftUI
import SubscriptionManager
import Models

@Observable
public final class PaywallVM: HashableNavigation {
    private let subscriptionManager: SubscriptionManagerProtocol
    
    //MARK: - Texts
    var textForPaywall: LocalizedStringKey = "Plan with ease\nLive with joy\nLess tasks, more life!"
    var benefits = ["Voice tasks & voice notifications", "Create group, customize space", "History, sync, and stay on top"]
    
    var textForButton: LocalizedStringKey = "Continue"
    
    //MARK: - UI States
    
    var pending = false
    var showAlert = false
    var alert: PaywallAlerts?
    
    public var closePaywall: (() -> Void)?
    
    //MARK: StoreKit
    
    var products: [Product] = []
    var selecetedProduct: Product?
    
    //MARK: - Private init
    
    private init(subscriptionManager: SubscriptionManagerProtocol) {
        self.subscriptionManager = subscriptionManager
    }
    
    //MARK: - VM Creator
    
    public static func createPaywallVM(subscriptionManager: SubscriptionManagerProtocol) async -> PaywallVM {
        let vm = PaywallVM(subscriptionManager: subscriptionManager)
        await vm.updateProducts()
        
        return vm
    }
    
    //MARK: - VM Preview Creator
    
    public static func createPreviewVM() -> PaywallVM {
        let subscriptionManager = SubscriptionManager.createMockSubscriptionManager()
        return PaywallVM(subscriptionManager: subscriptionManager)
    }
    
    //MARK: - Update products
    
    private func updateProducts() async {
        do {
            products = try await subscriptionManager.loadProducts()
            selecetedProduct = products.first
            await isEligibleForFreeTrial(selecetedProduct)
        } catch {
            alert = .cannotLoadProductsAlert
            showAlert = true
        }
    }
    //MARK: - Select Product Button Tapped
    
    @MainActor
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
    
    //MARK: - Check trial eligible
    
    private func isEligibleForFreeTrial(_ product: Product?) async {
        guard let product else {
            return
        }
        
        guard await product.isEligibleForFreeTrial() else {
            return
        }
        
        if product.intoductoryOffer() != nil {
            textForButton = "Try for free"
        } else {
            textForButton = "Continue"
        }
    }
    
    //MARK: - Make purchase
    
    @MainActor
    func makePurchase() async {
        pending = true
        
        guard let selecetedProduct else {
            return
        }
        
        do {
            try await subscriptionManager.makePurchase(selecetedProduct)
            pending = false
            closePaywall?()
        } catch {
            alert = .purchaseFailed
            showAlert = true
        }
        
        pending = false
    }
    
    //MARK: - Restore Button
    
    @MainActor
    func restoreButtonTapped() async {
        pending = true
        
        guard await subscriptionManager.restorePurchases() else {
            alert = PaywallAlerts.restoreAlert
            showAlert = true
            pending = false
            return
        }
        
        pending = false
    }
    
    //MARK: - Close Paywall Button
    
    public func closePaywallButtonTapped() {
        closePaywall?()
    }
}
