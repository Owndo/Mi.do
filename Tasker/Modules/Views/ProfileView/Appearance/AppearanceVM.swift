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
    
    var profileData: ProfileData = mockProfileData()
    var changeStateTrigger = false
    var backgroundSymbolAnimate = false
    var accentSymbolAnimate = false
    var defaultTaskColor: TaskColor = .baseColor
    
    @ObservationIgnored
    var customBackgroundColor = Color.black {
        didSet {
            changeStateTrigger.toggle()
            profileData.settings.background = BackgroundColorEnum.custom(customBackgroundColor.toHex()).setUpColor()
            casManager.saveProfileData(profileData)
        }
    }
    
    @ObservationIgnored
    var customAccentColor = Color.black {
        didSet {
            changeStateTrigger.toggle()
            profileData.settings.accentColor = AccentColorEnum.custom(customAccentColor.toHex()).setUpColor()
            casManager.saveProfileData(profileData)
        }
    }
    
    init() {
        profileData = casManager.profileModel
        defaultTaskColor = profileData.settings.defaultTaskColor
    }
    
    // MARK: - Change progress Mode
    func changeProgressMode(_ progressMode: Bool) {
        changeStateTrigger.toggle()
        appearanceManager.changeProgressMode(progressMode)
        profileData = casManager.profileModel
        casManager.saveProfileData(profileData)
    }
    
    func selectedDefaultTaskColorButtonTapped(_ color: TaskColor) {
        defaultTaskColor = color
        profileData.settings.defaultTaskColor = defaultTaskColor
        casManager.saveProfileData(profileData)
    }
    
    func checkColorForCheckMark(color: TaskColor) -> Bool {
        defaultTaskColor == color
    }
    
    func changeAccentColor(_ accentColor: AccentColorEnum) {
        changeStateTrigger.toggle()
        appearanceManager.changeAccentColor(accentColor)
        casManager.saveProfileData(profileData)
        accentSymbolAnimate.toggle()
    }
    
    func checkAccentColor(_ accentColor: AccentColorEnum) -> Bool {
        profileData.settings.accentColor == accentColor.setUpColor()
    }
    
    func checkCustomAccent() -> Bool {
        var state = true
        for i in AccentColorEnum.allCases {
            guard i.setUpColor() != profileData.settings.accentColor else {
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
        profileData.settings.background == backgroundColor.setUpColor()
    }
    
    func checkCustomBackground() -> Bool {
        var state = true
        for i in BackgroundColorEnum.allCases {
            guard i.setUpColor() != profileData.settings.background else {
                return false
            }
            
            state = true
        }
        
        return state
    }
}
