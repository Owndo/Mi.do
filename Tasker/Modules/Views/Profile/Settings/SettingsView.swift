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
                        
                    }
                    
                    CustomDivider()
                        .frame(height: 1)
                        .padding(.leading, 38)
                    
                    ButtonRow(icon: "doc", title: "Terms of Use") {
                        
                    }
                    
                    .padding(.bottom, 28)
                    
                    Spacer()
                    
                    Text("App Version \(ConfigurationFile().appVersion)", bundle: .module)
                        .font(.system(.subheadline, design: .default, weight: .regular))
                        .foregroundStyle(.labelTertiary)
                        .padding(.bottom, 37)
                }
                .padding(.top, 43)
                .padding(.horizontal, 16)
            }
            .onChange(of: vm.syncWithIcloud) { oldValue, newValue in
                Task {
                    await vm.turnOnSync()
                }
            }
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismissButton()
                        
                        // telemetry
                        vm.closeButtonTapped()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17))
                            
                            Text("Profile", bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .tint(colorScheme.accentColor())
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Settings", bundle: .module)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.labelPrimary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            
            if vm.showPaywall {
                PaywallView()
            }
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
