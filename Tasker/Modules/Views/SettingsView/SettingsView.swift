//
//  SettingsView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/28/25.
//

import SwiftUI
import UIComponents
import Models
import ConfigurationFile

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissButton
    @Environment(\.openURL) var openURL
    
    var vm: SettingsVM
    
    @Binding var path: NavigationPath
    
    var body: some View {
        ZStack {
            colorScheme.backgroundColor()
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    SettingsButtonRow(icon: "swirl.circle.righthalf.filled", title: "Appearance") {
                        //                        vm.goTo(path: &path, destination: .appearance)
                    }
                    
                    CustomDivider()
                        .frame(height: 1)
                        .padding(.leading, 38)
                    
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundStyle(colorScheme.accentColor())
                            .frame(width: 32, height: 32)
                        
                        Text("Week start day", bundle: .module)
                            .font(.system(.callout, design: .rounded, weight: .regular))
                            .foregroundStyle(.labelPrimary)
                            .minimumScaleFactor(0.5)
                        
                        Spacer()
                        
                        FirstDayOfWeekMenu()
                    }
                    
                    CustomDivider()
                        .frame(height: 1)
                        .padding(.leading, 38)
                    
                    //                    Toggle(isOn: $vm.syncWithIcloud) {
                    //                        HStack {
                    //                            Image(systemName: "arrow.clockwise.icloud")
                    //                                .foregroundStyle(colorScheme.accentColor())
                    //                                .frame(width: 32, height: 32)
                    //
                    //                            Text("Sync with iCloud", bundle: .module)
                    //                                .font(.system(.callout, design: .rounded, weight: .regular))
                    //                                .foregroundStyle(.labelPrimary)
                    //                        }
                    //                    }
                    
                    //                    CustomDivider()
                    //                        .frame(height: 1)
                    //                        .padding(.leading, 38)
                    
                    SettingsButtonRow(icon: "lock.shield", title: "Privacy Policy") {
                        openURL(ConfigurationFile.privacy)
                    }
                    
                    CustomDivider()
                        .frame(height: 1)
                        .padding(.leading, 38)
                    
                    SettingsButtonRow(icon: "doc", title: "Terms of Use") {
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
            .toolbarBackground(osVersion.majorVersion >= 26 ? .clear : colorScheme.backgroundColor(), for: .navigationBar)
            .navigationTitle(Text("Settings", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            
        }
    }
    
    //MARK: - First Day of week menu
    
    @ViewBuilder
    private func FirstDayOfWeekMenu() -> some View {
        Menu {
            Button {
                Task {
                    await vm.changeFirstDayOfWeek(.sunday)
                }
            } label: {
                if vm.firstDayOfWeek.description == "Sunday" {
                    Image(systemName: "checkmark")
                }
                
                Text("Sunday", bundle: .module)
            }
            
            Button {
                Task {
                    await vm.changeFirstDayOfWeek(.monday)
                }
            } label: {
                if vm.firstDayOfWeek.description == "Monday" {
                    Image(systemName: "checkmark")
                }
                
                Text("Monday", bundle: .module)
            }
        } label: {
            HStack {
                Text(vm.firstDayOfWeek.description, bundle: .module)
                    .font(.system(.callout, design: .rounded, weight: .regular))
                
                Image(systemName: "chevron.up.chevron.down")
                    .padding(.vertical, 12)
            }
        }
        .tint(.labelQuaternary)
    }
    
    //MARK: - Custom divider
    @ViewBuilder
    private func CustomDivider() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.separatorSecondary)
    }
}

#Preview {
    SettingsView(vm: SettingsVM.createMOCKSettingsVM(), path: .constant(NavigationPath()))
}
