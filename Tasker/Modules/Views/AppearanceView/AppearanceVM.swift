//
//  AppearanceVM.swift
//  Models
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import SwiftUI
import AppearanceManager
import Models

@Observable
public final class AppearanceVM: HashableNavigation {
    var appearanceManager: AppearanceManagerProtocol
    
    var profileData: UIProfileModel
    var defaultTaskColor: TaskColor
    
    public var backButton: (() -> Void)?
    
    var changeStateTrigger = false
    var backgroundSymbolAnimate = false
    var accentSymbolAnimate = false
    
    @ObservationIgnored
    var customBackgroundColor = Color.black {
        didSet {
            Task {
                await changeBackgroundColor(BackgroundColorEnum.custom(customBackgroundColor.toHex()))
            }
        }
    }
    
    @ObservationIgnored
    var customAccentColor = Color.black {
        didSet {
            Task {
                await changeAccentColor(AccentColorEnum.custom(customAccentColor.toHex()))
            }
        }
    }
    
    private init(appearanceManager: AppearanceManagerProtocol, profileData: UIProfileModel, defaultTaskColor: TaskColor) {
        self.appearanceManager = appearanceManager
        self.profileData = profileData
        self.defaultTaskColor = defaultTaskColor
    }
    
    //MARK: - Create VM
    
    public static func createAppearanceVM(appearanceManager: AppearanceManagerProtocol) -> AppearanceVM {
        AppearanceVM(appearanceManager: appearanceManager, profileData: appearanceManager.profileModel, defaultTaskColor: appearanceManager.profileModel.settings.defaultTaskColor)
    }
    
    //MARK: - CreatePreviewVM
    
    public static func createAppearancePreviewVM() -> AppearanceVM {
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        return AppearanceVM(appearanceManager: appearanceManager, profileData: appearanceManager.profileModel, defaultTaskColor: appearanceManager.profileModel.settings.defaultTaskColor)
    }
    
    // MARK: - Change progress Mode
    
    func changeProgressMode(_ progressMode: Bool) async {
        try? await appearanceManager.changeProgressMode(progressMode)
        changeStateTrigger.toggle()
    }
    
    //MARK: - Select default task color
    
    func selectedDefaultTaskColorButtonTapped(_ color: TaskColor) async {
        try? await appearanceManager.changeDefaultTaskColor(color)
        defaultTaskColor = color
    }
    
    //MARK: - Check Color For CheckMark
    
    /// Color on the background
    func checkColorForCheckMark(color: TaskColor) -> Bool {
        defaultTaskColor == color
    }
    
    //MARK: - Change Accent Color
    
    func changeAccentColor(_ accentColor: AccentColorEnum) async {
        try? await appearanceManager.changeAccentColor(accentColor)
        accentSymbolAnimate.toggle()
    }
    
    //MARK: - Check Accent Color
    
    func checkAccentColor(_ accentColor: AccentColorEnum) -> Bool {
        profileData.settings.accentColor == accentColor.setUpColor()
    }
    
    //MARK: - Check Accent Color
    
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
    
    func changeScheme(_ colorScheme: ColorSchemeMode) async {
        try? await appearanceManager.setColorScheme(colorScheme)
        changeStateTrigger.toggle()
    }
    
    //MARK: - Change Background Color
    
    func changeBackgroundColor(_ color: BackgroundColorEnum) async {
        try? await appearanceManager.changeBackgroundColor(color)
        backgroundSymbolAnimate.toggle()
    }
    
    //MARK: - Check current background Color
    
    func checkCurrentBackgroundColor(_ backgroundColor: BackgroundColorEnum) -> Bool {
        profileData.settings.background == backgroundColor.setUpColor()
    }
    
    //MARK: - Check if user use custom color
    
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
    
    //MARK: - Back Button Tapped
    func backButtonTapped() {
        backButton?()
    }
}
