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
    
    let isIPhoneSE = UIScreen.main.bounds.size.height <= 667
    
    public init(vm: WelcomeVMProtocol) {
        self.vm = vm
    }
    
    public var body: some View {
        ZStack {
            vm.appearanceManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: !isIPhoneSE ? 28 : 14) {
                Image(uiImage: .onboarding)
                    .resizable()
                    .scaledToFit()
                
                Text(vm.title, bundle: .module)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 14) {
                    Description(title: vm.descriptionTitle, text: vm.description)
                    
                    Description(title: vm.descriptionTitle1, text: vm.description1)
                    
                    Description(title: vm.descriptionTitle2, text: vm.description2)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                
                CreatedDate()
                
                Spacer()
            }
            
            VStack {
                Spacer()
                
                ContinueButton()
            }
            
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .onDisappear {
            Task {
                await vm.welcomeToMidoClose()
            }
        }
    }
    
    //MARK: - Description
    
    private func Description(title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading) {
                Text(title, bundle: .module)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                    .minimumScaleFactor(0.9)
                
                Text(text, bundle: .module)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.labelSecondary)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.9)
            }
            
            Spacer()
        }
        .padding(.leading)
    }
    
    //MARK: - Created Date
    
    private func CreatedDate() -> some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelTertiary)
            
            Text("Created:", bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelTertiary)
                .minimumScaleFactor(0.7)
            
            Text(vm.createdDate.formatted(.dateTime.month().day().hour().minute().year()))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelSecondary)
                .minimumScaleFactor(0.7)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    //MARK: - Continue Button
    
    private func ContinueButton() -> some View {
        Button {
            dismissButton()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text("Continue", bundle: .module)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.labelPrimaryInverted)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(vm.appearanceManager.accentColor)
                )
                .liquidIfAvailable(glass: .regular, isInteractive: true)
                .padding(.horizontal, 17)
        }
    }
}

#Preview {
    WelcomeView(vm: FirstLaunchVM.createPreviewVM())
}

#Preview("What's new?") {
    WelcomeView(vm: WhatsNewVM.createPreviewVM())
}
