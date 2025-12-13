//
//  ColorScheme+Ext.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/22/25.
//

import Foundation
import SwiftUI

public extension ColorScheme {
    func accentColor() -> Color {
        //        @Injected(\.appearanceManager) var appearanceManager
        //
        //        if self == .dark {
        //            return appearanceManager.profileData.settings.accentColor.dark.hexColor()
        //        } else {
        //            return appearanceManager.profileData.settings.accentColor.light.hexColor()
        //        }
        Color.green
    }
    
    func backgroundColor() -> Color {
        //        @Injected(\.appearanceManager) var appearanceManager
        //
        //        if self == .dark {
        //            return appearanceManager.profileData.settings.background.dark.hexColor()
        //        } else {
        //            return appearanceManager.profileData.settings.background.light.hexColor()
        //        }
        Color.white
    }
}
