//
//  PaywallView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/23/25.
//

import SwiftUI
import Managers
import UIComponents
import StoreKit
import Models

public struct PaywallView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openUrl
    
    @State private var vm = PaywallVM()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.backgroundDimDark.ignoresSafeArea()
                .onTapGesture {
                    vm.closePaywallButtonTapped()
                }
            
            MainView()
                .fixedSize(horizontal: false, vertical: true)
            
            if vm.pending {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .onAppear {
            Task {
                await vm.subscriptionManager.loadProducts()
            }
        }
        .alert("Nothing to restore 🤷‍♂️", isPresented: $vm.showingAlert) {
            Button {
                
            } label: {
                Text("No luck")
            }
        } message: {
            Text("I’d love to bring something back… but there’s nothing yet.")
        }
        .animation(.default, value: vm.textForButton)
    }
    
    //MARK: - Main View
    @ViewBuilder
    private func MainView() -> some View {
        VStack(spacing: 0) {
            Image(uiImage: .paywall)
                .resizable()
                .scaledToFit()
                .frame(width: 98)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
                .padding(.bottom, 12)
            
            Benefits()
            
            Subscription()
            
            ContinueButton()
            
            LegalNote()
        }
        .padding(.top, 24)
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    colorScheme.backgroundColor()
                )
        )
        .padding(.horizontal, 16)
    }
    
    //MARK: - Info
    @ViewBuilder
    private func Benefits() -> some View {
        VStack(spacing: 12) {
            Text(vm.textForPaywall, bundle: .module)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.labelPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(vm.benefits, id: \.self) { benefit in
                    HStack {
                        
                        Image(systemName: "checkmark")
                            .foregroundStyle(colorScheme.accentColor())
                        
                        Text(LocalizedStringKey(benefit), bundle: .module)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.labelSecondary)
                    }
                }
            }
        }
        .padding(.bottom, 17)
    }
    
    //MARK: - Subscription
    @ViewBuilder
    private func Subscription() -> some View {
        VStack {
            if vm.products.isEmpty {
                ProgressView()
            } else {
                HStack {
                    ForEach(vm.products, id: \.self) { product in
                        SubscriptionRow(product: product)
                    }
                }
            }
        }
        .padding(.bottom, 12)
        .animation(.spring, value: vm.selecetedProduct)
        .sensoryFeedback(.selection, trigger: vm.selecetedProduct)
    }
    
    //MARK: - Subscription row
    @ViewBuilder
    private func SubscriptionRow(product: Product) -> some View {
        Button {
            vm.selecetedProduct = product
        } label: {
            VStack {
                Text(LocalizedStringKey(product.displayName), bundle: .module)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelSecondary)
                
                Text(LocalizedStringKey(product.displayPrice), bundle: .module)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                
                HStack(spacing: 0) {
                    Text(product.subscription?.subscriptionPeriod.unit == .month ? product.dividedByWeek : product.dividedYearByWeek)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.labelTertiary)
                    
                    Text(product.subscription?.subscriptionPeriod.unit.devidedPeriodByWeek ?? "", bundle: .module)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.labelTertiary)
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(product == vm.selecetedProduct ? colorScheme.accentColor() : .clear, lineWidth: 1.5)
                    )
            )
            .padding(.top, 9)
            .overlay(alignment: .top) {
                if product == vm.products.last {
                    HStack {
                        Text("Popular", bundle: .module)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.labelPrimaryInverted)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        colorScheme.accentColor()
                                    )
                            )
                    }
                }
            }
            .overlay(alignment: .top) {
                if let offer = product.intoductoryOffer() {
                    HStack {
                        Text(offer, bundle: .module)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.labelPrimaryInverted)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        colorScheme.accentColor()
                                    )
                            )
                    }
                }
            }
        }
    }
    
    //MARK: - Continue Button
    @ViewBuilder
    private func ContinueButton() -> some View {
        Button {
            Task {
                await vm.makePurchase()
            }
        } label: {
            Text(vm.textForButton, bundle: .module)
                .font(.system(.body, design: .rounded, weight: .medium))
                .font(.system(size: 17))
                .foregroundStyle(.labelPrimaryInverted)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            colorScheme.accentColor()
                        )
                )
                .padding(.bottom, 20)
        }
    }
    
    //MARK: - Legal note
    @ViewBuilder
    private func LegalNote() -> some View {
        HStack {
            Button {
                openUrl(ConfigurationFile.privacy)
            } label: {
                Text("Privacy Policy", bundle: .module)
                    .font(.system(.caption2, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelQuaternary)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            Button {
                Task {
                    await vm.restoreButtonTapped()
                }
            } label: {
                Text("Restore", bundle: .module)
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelTertiary)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            Button {
                openUrl(ConfigurationFile.terms)
            } label: {
                Text("Terms of use", bundle: .module)
                    .font(.system(.caption2, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelQuaternary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    PaywallView()
}
