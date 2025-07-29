//
//  AppearanceView.swift
//  Models
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import SwiftUI
import Managers
import Models
import UIComponents

struct AppearanceView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var path: NavigationPath
    
    @State private var vm = AppearanceVM()
    
    @State private var animateSymbol = false
    
    var body: some View {
        ZStack {
            colorScheme.backgroundColor()
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
                        .padding(.bottom, 28)
                    
                    AccentColorSelector()
                        .padding(.bottom, 28)
                    
                    BackgroundColorSelector()
                }
                .scrollIndicators(.hidden)
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
                            
                            Text("Settings", bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .tint(colorScheme.accentColor())
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .navigationTitle(Text("Appearance", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .background(colorScheme.backgroundColor())
        }
    }
    
    //MARK: - Scheme selector
    @ViewBuilder
    private func SchemeSelector(_ scheme: ColorSchemeMode) -> some View {
        Button {
            vm.changeScheme(scheme)
        } label: {
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
                
                Text(scheme.description, bundle: .module)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelPrimary)
                
                
                if scheme == vm.profileData.value.settings.colorScheme {
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
        .animation(.default, value: vm.appearanceManager.selectedColorScheme)
        .sensoryFeedback(.selection, trigger: vm.appearanceManager.selectedColorScheme)
    }
    
    //MARK: - Progress mode
    @ViewBuilder
    private func ProgressMode() -> some View {
        VStack(alignment: .leading) {
            
            Text("Progress task design", bundle: .module)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
            
            HStack(spacing: 16) {
                ProgressRowButton(colorScheme == .dark ? Image(uiImage: .minimalDark) : Image(uiImage: .minimal), text: "Minimal", value: true) {
                    vm.changeProgressMode(true)
                }
                
                ProgressRowButton(colorScheme == .dark ? Image(uiImage: .colorfulDark) : Image(uiImage: .colorful), text: "Colorful", value: false) {
                    vm.changeProgressMode(false)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: vm.changeStateTrigger)
        .animation(.default, value: vm.changeStateTrigger)
    }
    
    //MARK: - Progress row Button
    @ViewBuilder
    private func ProgressRowButton(_ image: Image, text: LocalizedStringKey, value: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            VStack {
                image
                    .resizable()
                    .scaledToFit()
                    .padding(.bottom, 4)
                
                Text(text, bundle: .module)
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
    
    //MARK: - Accent color selector
    @ViewBuilder
    private func AccentColorSelector() -> some View {
        VStack(alignment: .leading) {
            Text("Interface color", bundle: .module)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 42), spacing: 27),
                GridItem(.flexible(minimum: 42), spacing: 27),
                GridItem(.flexible(minimum: 42), spacing: 27),
                GridItem(.flexible(minimum: 42), spacing: 27),
                GridItem(.flexible(minimum: 42), spacing: 27)], spacing: 27) {
                    ForEach(AccentColorEnum.allCases) { color in
                        Button {
                            vm.changeAccentColor(color)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color.showColor(colorScheme))
                                    .overlay(
                                        Circle()
                                            .stroke(.separatorPrimary, lineWidth: 1)
                                    )
                                
                                Image(systemName: "checkmark")
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                    .foregroundStyle(vm.checkAccentColor(color) ? .labelPrimaryInverted : .clear)
                                    .symbolEffect(.bounce, value: vm.accentSymbolAnimate)
                            }
                        }
                    }
                    ZStack {
                        ColorPicker(selection: $vm.customAccentColor) {}
                            .fixedSize()
                        
                        Image(uiImage: .colorPicker)
                            .resizable()
                            .scaledToFit()
                            .allowsHitTesting(false)
                        
                        if vm.checkCustomAccent() {
                            Image(systemName: "checkmark")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(.labelPrimaryInverted)
                                .symbolEffect(.bounce, value: vm.accentSymbolAnimate)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            .backgroundTertiary
                        )
                )
        }
    }
    
    //MARK: Background color selector
    @ViewBuilder
    private func BackgroundColorSelector() -> some View {
        VStack(alignment: .leading) {
            
            Text("Background color", bundle: .module)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
            
            HStack(spacing: 27) {
                ForEach(BackgroundColorEnum.allCases, id: \.self) { color in
                    Button {
                        vm.changeBackgroundColor(color)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.showColors(colorScheme))
                                .overlay(
                                    Circle()
                                        .stroke(.separatorPrimary, lineWidth: 1)
                                )
                            
                            Image(systemName: "checkmark")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(vm.checkCurrentBackgroundColor(color) ? .labelPrimary : .clear)
                                .symbolEffect(.bounce, value: vm.backgroundSymbolAnimate)
                        }
                    }
                }
                
                ZStack {
                    ColorPicker(selection: $vm.customBackgroundColor) {}
                        .fixedSize()
                    
                    Image(uiImage: .colorPicker)
                        .resizable()
                        .scaledToFit()
                        .allowsHitTesting(false)
                    
                    if vm.checkCustomBackground() {
                        Image(systemName: "checkmark")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.labelPrimary)
                            .symbolEffect(.bounce, value: vm.backgroundSymbolAnimate)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        .backgroundTertiary
                    )
            )
        }
    }
}

#Preview {
    AppearanceView(path: .constant(NavigationPath()))
}
