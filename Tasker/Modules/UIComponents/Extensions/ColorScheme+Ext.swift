//
//  ColorScheme+Ext.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/22/25.
//

import Foundation
import SwiftUICore
import Managers

public extension ColorScheme {
    func accentColor() -> Color {
        @Injected(\.appearanceManager) var appearanceManager
        
        if self == .dark {
            return appearanceManager.profileData.value.settings.accentColor.dark.hexColor()
        } else {
            return appearanceManager.profileData.value.settings.accentColor.light.hexColor()
        }
    }
    
    func backgroundColor() -> Color {
        @Injected(\.appearanceManager) var appearanceManager
        
        if self == .dark {
            return appearanceManager.profileData.value.settings.background.dark.hexColor()
        } else {
            return appearanceManager.profileData.value.settings.background.light.hexColor()
        }
    }
}
