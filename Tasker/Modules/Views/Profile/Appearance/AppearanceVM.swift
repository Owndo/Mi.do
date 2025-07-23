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
    var changeStateTrigger = false
    var backgroundSymbolAnimate = false
    var accentSymbolAnimate = false
    
    @ObservationIgnored
    var customBackgroundColor = Color.black {
        didSet {
            changeStateTrigger.toggle()
            profileData.value.settings.background = BackgroundColorEnum.custom(customBackgroundColor.toHex()).setUpColor()
            casManager.saveProfileData(profileData)
        }
    }
    
    @ObservationIgnored
    var customAccentColor = Color.black {
        didSet {
            changeStateTrigger.toggle()
            profileData.value.settings.accentColor = AccentColorEnum.custom(customAccentColor.toHex()).setUpColor()
            casManager.saveProfileData(profileData)
        }
    }
    
    init() {
        profileData = casManager.profileModel ?? mockProfileData()
    }
    
    // MARK: - Change progress Mode
    func changeProgressMode(_ progressMode: Bool) {
        changeStateTrigger.toggle()
        appearanceManager.changeProgressMode(progressMode)
        profileData = casManager.profileModel ?? mockProfileData()
    }
    
    func changeAccentColor(_ accentColor: AccentColorEnum) {
        changeStateTrigger.toggle()
        profileData.value.settings.accentColor = accentColor.setUpColor()
        appearanceManager.changeAccentColor(accentColor)
        accentSymbolAnimate.toggle()
    }
    
    func checkAccentColor(_ accentColor: AccentColorEnum) -> Bool {
        profileData.value.settings.accentColor == accentColor.setUpColor()
    }
    
    func checkCustomAccent() -> Bool {
        var state = true
        for i in AccentColorEnum.allCases {
            guard i.setUpColor() != profileData.value.settings.accentColor else {
                return false
            }
            
            state = true
        }
        
        return state
    }
    
    // MARK: - Change scheme
    func changeScheme(_ colorScheme: ColorSchemeMode) {
        appearanceManager.setColorScheme(colorScheme)
    }
    
    func changeBackgroundColor(_ color: BackgroundColorEnum) {
        changeStateTrigger.toggle()
        appearanceManager.changeBackgroundColor(color)
        backgroundSymbolAnimate.toggle()
    }
    
    func checkCurrentBackgroundColor(_ backgroundColor: BackgroundColorEnum) -> Bool {
        profileData.value.settings.background == backgroundColor.setUpColor()
    }
    
    func checkCustomBackground() -> Bool {
        var state = true
        for i in BackgroundColorEnum.allCases {
            guard i.setUpColor() != profileData.value.settings.background else {
                return false
            }
            
            state = true
        }
        
        return state
    }
}
