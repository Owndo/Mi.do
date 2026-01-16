//
//  AppearanceView.swift
//  Models
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import SwiftUI
import Models
import UIComponents
import AppearanceManager

public struct AppearanceView: View {
    @Environment(\.appearanceManager) private var appearanceManager
    @Environment(\.colorScheme) private var colorScheme
    
    @Bindable var vm: AppearanceVM
    
    @State private var animateSymbol = false
    
    public init(vm: AppearanceVM) {
        self.vm = vm
    }
    
    public var body: some View {
        ZStack {
            appearanceManager.backgroundColor
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
                    .padding(.horizontal, 16)
                    
                    ProgressMode()
                        .padding(.bottom, 28)
                        .padding(.horizontal, 16)
                    
                    DefaultTaskColorSelector()
                        .padding(.bottom, 28)
                        .padding(.horizontal, 16)
                    
                    AccentColorSelector()
                        .padding(.bottom, 28)
                        .padding(.horizontal, 16)
                    
                    BackgroundColorSelector()
                        .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    vm.backButtonTapped()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17))
                            .foregroundStyle(appearanceManager.accentColor)
                        
                        Text("Settings", bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(appearanceManager.accentColor)
                    }
                }
            }
        }
        .toolbarBackground(osVersion.majorVersion >= 26 ? .clear : appearanceManager.backgroundColor, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .navigationTitle(Text("Appearance", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: appearanceManager.colorScheme)
        .animation(.default, value: vm.changeStateTrigger)
        .animation(.default, value: vm.accentSymbolAnimate)
        .animation(.default, value: vm.backgroundSymbolAnimate)
        .sensoryFeedback(.selection, trigger: vm.changeStateTrigger)
        .sensoryFeedback(.selection, trigger: vm.accentSymbolAnimate)
        .sensoryFeedback(.selection, trigger: vm.backgroundSymbolAnimate)
    }
    
    //MARK: - Scheme selector
    @ViewBuilder
    private func SchemeSelector(_ scheme: ColorSchemeMode) -> some View {
        Button {
            Task {
                await vm.changeScheme(scheme)
            }
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
                    .minimumScaleFactor(0.5)
                
                
                Image(systemName: scheme == vm.profileData.settings.colorScheme ? "checkmark.circle.fill" : "circle")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.labelPrimary)
                    .liquidIfAvailable(glass: .regular, isInteractive: true)
            }
        }
        //        .animation(.default, value: vm.appearanceManager.selectedColorScheme)
        //        .sensoryFeedback(.selection, trigger: vm.appearanceManager.selectedColorScheme)
    }
    
    //MARK: - Progress mode
    @ViewBuilder
    private func ProgressMode() -> some View {
        VStack(alignment: .leading) {
            
            Text("Progress task design", bundle: .module)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
            
            HStack(spacing: 16) {
                ProgressRowButton(
                    colorScheme == .dark ? Image(uiImage: .minimalDark) :
                        colorScheme == .light ? Image(uiImage: .minimal) :
                        Image(uiImage: .minimalDark),
                    text: "Minimal",
                    value: true
                ) {
                    await vm.changeProgressMode(true)
                }
                
                ProgressRowButton(
                    colorScheme == .dark ? Image(uiImage: .colorfulDark) :
                        colorScheme == .light ? Image(uiImage: .colorful) :
                        Image(uiImage: .colorfulDark),
                    text: "Colorful",
                    value: false
                ) {
                    await vm.changeProgressMode(false)
                }
            }
        }
    }
    
    //MARK: - Progress row Button
    @ViewBuilder
    private func ProgressRowButton(_ image: Image, text: LocalizedStringKey, value: Bool, action: @escaping () async -> Void) -> some View {
        @State var isSelected: Bool = value == vm.profileData.settings.minimalProgressMode
        
        Button {
            Task {
                await action()
            }
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
                    .minimumScaleFactor(0.5)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .symbolEffect(.bounce, value: isSelected)
                    .foregroundStyle(isSelected ? .labelPrimary : .labelQuaternary)
            }
        }
    }
    
    //MARK: - Default task Color
    @ViewBuilder
    private func DefaultTaskColorSelector() -> some View {
        VStack(alignment: .leading) {
            Text("Default task color", bundle: .module)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(TaskColor.allCases, id: \.id) { color in
                        
                        Spacer()
                        
                        Button {
                            Task {
                                await vm.selectedDefaultTaskColorButtonTapped(color)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color.color(for: colorScheme))
                                    .frame(width: 28, height: 28)
                                    .padding(.vertical, 20)
                                    .overlay(
                                        Circle()
                                            .stroke(.separatorPrimary, lineWidth: vm.checkColorForCheckMark(color: color) ? 1.5 : 0.3)
                                            .shadow(radius: 8, y: 4)
                                            .liquidIfAvailable(glass: .clear, isInteractive: true)
                                    )
                                
                                Image(systemName: "checkmark")
                                    .foregroundStyle(vm.checkColorForCheckMark(color: color) ? .labelPrimary : .clear)
                                    .symbolEffect(.bounce, value: vm.defaultTaskColor)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 26)
            )
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(
                        .backgroundTertiary
                    )
            )
            .sensoryFeedback(.selection, trigger: vm.defaultTaskColor)
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
                            Task {
                                await vm.changeAccentColor(color)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color.showColor(colorScheme))
                                    .overlay(
                                        Circle()
                                            .stroke(.separatorPrimary, lineWidth: 1)
                                            .liquidIfAvailable(glass: .clear, isInteractive: true)
                                    )
                                
                                Image(systemName: "checkmark")
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                    .foregroundStyle(vm.checkAccentColor(color) ? .labelPrimary : .clear)
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
                    RoundedRectangle(cornerRadius: 26)
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
                        Task {
                            await vm.changeBackgroundColor(color)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.showColors(colorScheme))
                                .overlay(
                                    Circle()
                                        .stroke(.separatorPrimary, lineWidth: 1)
                                        .liquidIfAvailable(glass: .clear, isInteractive: true)
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
                RoundedRectangle(cornerRadius: 26)
                    .fill(
                        .backgroundTertiary
                    )
            )
        }
    }
}

#Preview {
    AppearanceView(vm: AppearanceVM.createAppearancePreviewVM())
}
