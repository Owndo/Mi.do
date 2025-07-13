//
//  AppearanceVM.swift
//  Models
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import SwiftUI
import Managers
import Models

@Observable
final class AppearanceVM {
    @ObservationIgnored
    @Injected(\.appearanceManager) var appearanceManager
    @ObservationIgnored
    @Injected(\.casManager) var casManager
    
    var profileData: ProfileData = mockProfileData()
    var progressModeTrigger = false
    
    init() {
        profileData = casManager.profileModel ?? mockProfileData()
    }
    
    func colorScheme() -> String {
        appearanceManager.colorScheme()
    }
    
    func backgroundColor() -> Color {
        appearanceManager.backgroundColor()
    }
    
    func accentColor() -> Color {
        appearanceManager.accentColor()
    }
    
    func changeScheme(_ colorScheme: ColorSchemeMode) {
        appearanceManager.changeColorSchemeMode(scheme: colorScheme)
    }
    
    func changeProgressMode(_ progressMode: Bool) {
        progressModeTrigger.toggle()
        appearanceManager.changeProgressMode(progressMode)
        profileData = casManager.profileModel ?? mockProfileData()
    }
}
