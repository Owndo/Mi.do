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
    
    @State private var zeroImageEffect: Bool = false
    @State private var firstImageEffect: Bool = false
    @State private var secondImageEffect: Bool = false
    
    var vm: WelcomeVMProtocol
    
    let isIPhoneSE = UIScreen.main.bounds.size.height <= 667
    
    public init(vm: WelcomeVMProtocol) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            Image(uiImage: .onboarding)
                .resizable()
                .scaledToFit()
            
            Text(vm.title, bundle: .module)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.labelPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            
            VStack(alignment: .leading, spacing: 14) {
                //                    if #available(iOS 26, *) {
                //                        Description(image: vm.imageDescription, title: vm.descriptionTitle, text: vm.description)
                //                            .symbolEffect(.drawOn.individually, isActive: !zeroImageEffect)
                //
                //                        Description(image: vm.imageDescription1, title: vm.descriptionTitle1, text: vm.description1)
                //                            .symbolEffect(.drawOn.individually, isActive: !firstImageEffect)
                //
                //                        Description(image: vm.imageDescription2, title: vm.descriptionTitle2, text: vm.description2)
                //                            .symbolEffect(.drawOn.individually, isActive: !secondImageEffect)
                //                    } else {
                Description(image: vm.imageDescription, title: vm.descriptionTitle, text: vm.description)
                    .symbolEffect(.bounce, value: zeroImageEffect)
                
                Description(image: vm.imageDescription1, title: vm.descriptionTitle1, text: vm.description1)
                    .symbolEffect(.bounce, value: firstImageEffect)
                
                Description(image: vm.imageDescription2, title: vm.descriptionTitle2, text: vm.description2)
                    .symbolEffect(.bounce, value: secondImageEffect)
                //                    }
            }
            .frame(maxWidth: .infinity)
            .padding(.top)
            .padding(.horizontal)
            
            CreatedDate()
                .padding(.top, !isIPhoneSE ? 28 : 18)
                .padding(.bottom, 50)
            
            Spacer()
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .customSafeAreaInset(edge: .bottom) {
            ContinueButton()
                .padding([.horizontal, .bottom])
        }
        .task {
            try? await Task.sleep(for: .seconds(0.7))
            secondImageEffect = true
            try? await Task.sleep(for: .seconds(0.2))
            firstImageEffect = true
            try? await Task.sleep(for: .seconds(0.2))
            zeroImageEffect = true
        }
        .onDisappear {
            Task {
                await vm.welcomeToMidoClose()
            }
        }
    }
    
    //MARK: - Description
    
    private func Description(image: String, title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Image(systemName: image)
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundStyle(vm.appearanceManager.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title, bundle: .module)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                    .minimumScaleFactor(0.5)
                
                Text(text, bundle: .module)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.labelSecondary)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.5)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    //MARK: - Created Date
    
    private func CreatedDate() -> some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelTertiary)
            
            Text(vm.createdText, bundle: .module)
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
                .liquidIfAvailable(glass: .clear, isInteractive: true)
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
