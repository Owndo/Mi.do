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

public struct PaywallView: View {
    @Environment(\.colorScheme) var colorScheme
    
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
        
    }
    
    //MARK: - Main View
    @ViewBuilder
    private func MainView() -> some View {
        VStack(spacing: 0) {
            Benefits()
            
            Subscription()
            
            ContinueButton()
            
            LegalNote()
        }
        .padding(.top)
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
            Text(vm.textForPaywall)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.labelPrimary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(vm.benefits, id: \.self) { benefit in
                    HStack {
                        
                        Image(systemName: "checkmark")
                            .foregroundStyle(colorScheme.accentColor())
                        
                        Text(benefit)
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
                Text(verbatim: product.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelSecondary)
                
                Text(product.displayPrice)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                
                Text(product.subscription?.subscriptionPeriod.unit == .month ? product.dividedByWeek : product.dividedByMonth)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.labelTertiary)
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
                        Text("Popular")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.labelPrimaryInverted)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 22)
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
            Text("Continue")
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
                
            } label: {
                Text("Privacy Policy")
                    .font(.system(.caption2, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelQuaternary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await vm.restoreButtonTapped()
                }
            } label: {
                Text("Restore")
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelTertiary)
            }
            
            Spacer()
            
            Button {
                
            } label: {
                Text("Terms of use")
                    .font(.system(.caption2, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelQuaternary)
            }
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 20)
    }
}

#Preview {
    PaywallView()
}
