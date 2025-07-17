//
//  AppearanceView.swift
//  Models
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import SwiftUI
import Managers
import UIComponents

struct AppearanceView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var path: NavigationPath
    
    @State private var vm = AppearanceVM()
    
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            colorScheme.backgroundColor.hexColor()
                .ignoresSafeArea()
            
            VStack {
                ScrollView {
                    
                    HStack(spacing: 29) {
                        ForEach(ColorSchemeMode.allCases, id: \.self) { scheme in
                            SchemeSelector(scheme)
                        }
                    }
                    .padding(.top, 27)
                    .padding(.bottom, 28)
                    
                    ProgressMode()
                }
                .scrollIndicators(.hidden)
            }
            .alert("Easy there", isPresented: $showAlert) {
                Button {
                    
                } label: {
                    Text("Piss me off 🤬")
                }
            } message: {
                Text("Comming soon...")
            }
            .padding(.horizontal, 16)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        path.removeLast()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17))
                            
                            Text("Profile")
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .tint(colorScheme.elementColor.hexColor())
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    //MARK: - Scheme selector
    @ViewBuilder
    private func SchemeSelector(_ scheme: ColorSchemeMode) -> some View {
        VStack(spacing: 12) {
            switch scheme {
            case .light:
                Image(uiImage: .light)
                    .resizable()
                    .scaledToFit()
            case .dark:
                Image(uiImage: .dark)
                    .resizable()
                    .scaledToFit()
            case .system:
                Image(uiImage: .system)
                    .resizable()
                    .scaledToFit()
            }
            
            Text(scheme.description)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.labelPrimary)
            
            Button {
                showAlert.toggle()
            } label: {
                if scheme.description == vm.profileData.value.settings.colorScheme {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.labelPrimary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.labelQuaternary)
                }
            }
        }
        .animation(.default, value: vm.profileData)
        .sensoryFeedback(.selection, trigger: vm.profileData)
    }
    
    //MARK: - Progress mode
    @ViewBuilder
    private func ProgressMode() -> some View {
        VStack(alignment: .leading) {
            
            Text("Progress task design")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
            
            HStack(spacing: 16) {
                ProgressRowButton(colorScheme == .dark ? .minimalDark : .minimal, text: "Minimal", value: true) {
                    vm.changeProgressMode(true)
                }
                
                ProgressRowButton(colorScheme == .dark ? .colorfulDark : .colorful, text: "Colorful", value: false) {
                    vm.changeProgressMode(false)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: vm.progressModeTrigger)
    }
    
    //MARK: - Progress row Button
    @ViewBuilder
    private func ProgressRowButton(_ image: UIImage, text: String, value: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(.bottom, 4)
                
                Text(text)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.labelPrimary)
                    .padding(.bottom, 4)
                
                if value == vm.profileData.value.settings.minimalProgressMode {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.labelPrimary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.labelQuaternary)
                }
            }
        }
    }
}

#Preview {
    AppearanceView(path: .constant(NavigationPath()))
}
