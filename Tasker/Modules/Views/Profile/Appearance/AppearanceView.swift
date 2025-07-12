//
//  AppearanceView.swift
//  Models
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import SwiftUI
import UIComponents

struct AppearanceView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var path: NavigationPath
    
    @State private var vm = AppearanceVM()
    
    var body: some View {
        ZStack {
            colorScheme.backgroundColor.hexColor()
                .ignoresSafeArea()
            
            VStack {
                ScrollView {
                    
                    HStack(spacing: 29) {
                        ForEach(AppearanceVM.ColorSchemeMode.allCases, id: \.self) { scheme in
                            SchemeSelector(scheme)
                        }
                    }
                    .padding(.top, 27)
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
            }
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
        }
    }
    
    //MARK: - Scheme selector
    @ViewBuilder
    private func SchemeSelector(_ scheme: AppearanceVM.ColorSchemeMode) -> some View {
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
                vm.changeColorSchemeMode(scheme: scheme)
            } label: {
                if scheme == vm.colorSchemeMode {
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
        .animation(.default, value: vm.colorSchemeMode)
        .sensoryFeedback(.selection, trigger: vm.colorSchemeMode)
    }
}

#Preview {
    AppearanceView(path: .constant(NavigationPath()))
}
