//
//  WelcomeView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/29/25.
//

import SwiftUI
import UIComponents

public struct WelcomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissButton
    
    var vm: WelcomeVMProtocol
    
    public init(vm: WelcomeVMProtocol) {
        self.vm = vm
    }
    
    public var body: some View {
        ZStack {
            vm.appearanceManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Image(uiImage: .onboarding)
                    .resizable()
                    .scaledToFit()
                
                Text("Welcome to Mi.dō", bundle: .module)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 14) {
                    Description(image: vm.systemImage, text: vm.description)
                    
                    Description(image: vm.systemImage1, text: vm.description1)
                    
                    Description(image: vm.systemImage2, text: vm.description2)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                
                CreatedDate()
                
                Spacer()
                
                Button {
                    dismissButton()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text("Continue", bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.labelPrimaryInverted)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(vm.appearanceManager.accentColor)
                        )
                        .liquidIfAvailable(glass: .regular, isInteractive: true)
                        .padding(.horizontal, 17)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 29)
        }
        .onDisappear {
            Task {
                await vm.welcomeToMidoClose()
            }
        }
    }
    
    //MARK: - Description
    @ViewBuilder
    private func Description(image: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Image(systemName: image)
                .font(.system(size: 22))
                .frame(width: 40, height: 40)
                .foregroundStyle(vm.appearanceManager.accentColor)
            
            Text(text, bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelSecondary)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
            
            Spacer()
        }
        .padding(.leading)
    }
    
    //MARK: - Created Date
    @ViewBuilder
    private func CreatedDate() -> some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelTertiary)
            
            Text("Created:", bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelTertiary)
            
            Text(vm.createdDate.formatted(.dateTime.month().day().hour().minute().year()))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelSecondary)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    WelcomeView(vm: FirstLaunchVM.createPreviewVM())
}
