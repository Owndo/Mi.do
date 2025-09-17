//
//  SettingsView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/28/25.
//

import SwiftUI
import UIComponents
import Models
import Paywall

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissButton
    @Environment(\.openURL) var openURL
    
    @State private var vm = SettingsVM()
    
    @Binding var path: NavigationPath
    
    var body: some View {
        ZStack {
            colorScheme.backgroundColor()
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    ButtonRow(icon: "swirl.circle.righthalf.filled", title: "Appearance") {
                        vm.goTo(path: &path, destination: .appearance)
                    }
                    
                    CustomDivider()
                        .frame(height: 1)
                        .padding(.leading, 38)
                    
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundStyle(colorScheme.accentColor())
                        .frame(width: 32, height: 32)
                    
                    Text("Week start day", bundle: .module)
                        .font(.system(.callout, design: .rounded, weight: .regular))
                        .foregroundStyle(.labelPrimary)
                        .minimumScaleFactor(0.5)
                    
                    Spacer()
                    
                    
                    Picker(selection: $vm.firstDayOfWeek) {
                        ForEach(SettingsVM.FirstWeekDay.allCases, id: \.self) { day in
                            
                        }
                    } label: {
                        
                    }
                    
                    ButtonRow(icon: "calendar.badge.checkmark", title: "Week start day", actionIcon: "chevron.up.chevron.down", action: {}, button1: {
                        vm.changeFirstDayOfWeek(1)
                    }, button2: {
                        vm.changeFirstDayOfWeek(2)
                    }, firstDayOfWeek: vm.firstWeekday)
                    
                    CustomDivider()
                        .frame(height: 1)
                        .padding(.leading, 38)
                    
                    Toggle(isOn: $vm.syncWithIcloud) {
                        HStack {
                            Image(systemName: "arrow.clockwise.icloud")
                                .foregroundStyle(colorScheme.accentColor())
                                .frame(width: 32, height: 32)
                            
                            Text("Sync with iCloud", bundle: .module)
                                .font(.system(.callout, design: .rounded, weight: .regular))
                                .foregroundStyle(.labelPrimary)
                        }
                    }
                    
                    CustomDivider()
                        .frame(height: 1)
                        .padding(.leading, 38)
                    
                    ButtonRow(icon: "lock.shield", title: "Privacy Policy") {
                        openURL(ConfigurationFile.privacy)
                    }
                    
                    CustomDivider()
                        .frame(height: 1)
                        .padding(.leading, 38)
                    
                    ButtonRow(icon: "doc", title: "Terms of Use") {
                        openURL(ConfigurationFile.terms)
                    }
                    .padding(.bottom, 28)
                    
                    Spacer()
                    
                    Text("App Version \(vm.actuallAppVersion())", bundle: .module)
                        .font(.system(.subheadline, design: .default, weight: .regular))
                        .foregroundStyle(.labelTertiary)
                        .padding(.bottom, 37)
                }
                .padding(.top, 27)
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            vm.closeButtonTapped(&path)
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 17))
                                    .foregroundStyle(colorScheme.accentColor())
                                
                                Text("Profile", bundle: .module)
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundStyle(colorScheme.accentColor())
                            }
                        }
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            vm.closeButtonTapped(&path)
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 17))
                                    .foregroundStyle(colorScheme.accentColor())
                                
                                Text("Profile", bundle: .module)
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundStyle(colorScheme.accentColor())
                            }
                        }
                    }
                }
            }
            .toolbarBackground(osVersion.majorVersion >= 26 ? .clear : colorScheme.backgroundColor(), for: .navigationBar)
            .navigationTitle(Text("Settings", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            
        }
    }
    
    
    //MARK: - Custom divider
    @ViewBuilder
    private func CustomDivider() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.separatorSecondary)
    }
}

#Preview {
    SettingsView(path: .constant(NavigationPath()))
}
