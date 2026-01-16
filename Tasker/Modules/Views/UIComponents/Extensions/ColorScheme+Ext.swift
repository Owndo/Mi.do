////
////  ColorScheme+Ext.swift
////  Tasker
////
////  Created by Rodion Akhmedov on 5/22/25.
////
//
//import Foundation
//import SwiftUI
//import AppearanceManager
//
//public extension ColorScheme {
//    
//    func mainBackgroundColor(_ appearanceManager: AppearanceManagerProtocol) -> Color {
//        if self == .dark {
//            return appearanceManager.profileModel.settings.background.dark.hexColor()
//        } else {
//            return appearanceManager.profileModel.settings.background.light.hexColor()
//        }
//    }
//    func accentColor() -> Color {
//        //        @Injected(\.appearanceManager) var appearanceManager
//        //
//        //        if self == .dark {
//        //            return appearanceManager.profileData.settings.accentColor.dark.hexColor()
//        //        } else {
//        //            return appearanceManager.profileData.settings.accentColor.light.hexColor()
//        //        }
//        Color.green
//    }
//    
//    func backgroundColor() -> Color {
//        //        @Injected(\.appearanceManager) var appearanceManager
//        //
//        //        if self == .dark {
//        //            return appearanceManager.profileData.settings.background.dark.hexColor()
//        //        } else {
//        //            return appearanceManager.profileData.settings.background.light.hexColor()
//        //        }
//        Color.white
//    }
//}
