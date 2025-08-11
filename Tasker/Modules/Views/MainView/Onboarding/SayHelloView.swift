//
//  SayHelloView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/29/25.
//

import SwiftUI
import UIComponents

struct SayHelloView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissButton
    
    @State private var vm = OnboardingVM()
    
    var body: some View {
        ZStack {
            colorScheme.backgroundColor()
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Image(uiImage: .onboarding)
                    .resizable()
                    .scaledToFit()
                
                Text("Welcome to Mi.dō", bundle: .module)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 14) {
                    Description(image: "road.lanes.curved.right", text: vm.description1)
                    
                    Description(image: "checkmark.square", text: vm.description2)
                    
                    Description(image: "hand.point.up.left.and.text", text: vm.description3)
                }
                .padding(.horizontal, 16)
                
                CreatedDate()
                
                Spacer()
                
                Button {
                    dismissButton()
                } label: {
                    Text("Continue", bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.labelPrimaryInverted)
                        .padding(.vertical, 13)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme.accentColor())
                        )
                        .padding(.horizontal, 16)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 29)
        }
        .onDisappear {
            vm.continueButtontapped()
        }
        .sensoryFeedback(.start, trigger: vm.closeTriger)
    }
    
    //MARK: - Description
    @ViewBuilder
    private func Description(image: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Image(systemName: image)
                .font(.system(size: 22))
                .frame(width: 40, height: 40)
                .foregroundStyle(colorScheme.accentColor())
            
            Text(text, bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelSecondary)
                .multilineTextAlignment(.leading)
        }
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
    SayHelloView()
}
