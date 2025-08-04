//
//  SettingsModel.swift
//  Models
//
//  Created by Rodion Akhmedov on 8/3/25.
//

import Foundation
import SwiftUI

public struct SettingsModel: Codable, Equatable {
    public var firstDayOfWeek: Int = Calendar.current.firstWeekday
    public var colorScheme: ColorSchemeMode
    public var accentColor: AccentBackgroundColor
    public var background: AccentBackgroundColor
    public var minimalProgressMode = true
    public var completedTasksHidden = false
    public var iCloudSyncEnabled = false
    
    public init(
        colorScheme: ColorSchemeMode,
        accentColor: AccentBackgroundColor = AccentBackgroundColor(light: "#0EBC7C", dark: "#18C585"),
        background: AccentBackgroundColor = AccentBackgroundColor(light: "#F2F5EE", dark: "#202020"),
    ) {
        self.colorScheme = colorScheme
        self.accentColor = accentColor
        self.background = background
    }
    
    private func currentSystemColorSchemeIsDark() -> Bool {
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
    
    public func backgroundColor() -> String {
        switch colorScheme {
        case .dark:
            return background.dark
        case .light:
            return background.light
        default:
            return currentSystemColorSchemeIsDark() ? background.dark : background.light
        }
    }
}
public func mockSettingsModel() -> SettingsModel {
    SettingsModel(
     colorScheme: .system,
     accentColor: AccentBackgroundColor(light: "#0EBC7C", dark: "#18C585"),
     background: AccentBackgroundColor(light: "#F2F5EE", dark: "#202020")
 )
}
public struct AccentBackgroundColor: Codable, Equatable {
    public var light: String
    public var dark: String
    
    public init(light: String, dark: String) {
        self.light = light
        self.dark = dark
    }
}
