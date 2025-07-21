//
//  AppearanceManager.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import SwiftUI
import Models

final public class AppearanceManager: AppearanceManagerProtocol {
   
    
    @Injected(\.casManager) var casManager
    
    var profileData: ProfileData = mockProfileData()
    
    init() {
        profileData = casManager.profileModel ?? mockProfileData()
    }
    
    public func colorScheme() -> String {
        profileData.value.settings.colorScheme
    }
    
    public func backgroundColor() -> Color {
        profileData.value.settings.background.hexColor()
    }
    
    public func changeColorSchemeMode(scheme: ColorSchemeMode) {
        profileData.value.settings.colorScheme = scheme.description
        saveProfileData()
    }
    
    public func changeProgressMode(_ value: Bool) {
        profileData.value.settings.minimalProgressMode = value
        saveProfileData()
    }
    
    public func changeAccentColor(_ color: AccentColorEnum) {
        profileData.value.settings.accentColor = color.id
        saveProfileData()
    }
    
    public func changeBackgroundColor(_ color: BackgroundColorEnum) {
        profileData.value.settings.background = color.id
        saveProfileData()
    }
    
    public func accentColor() -> Color {
        profileData.value.settings.accentColor.hexColor()
    }
    
    func saveProfileData() {
        casManager.saveProfileData(profileData)
    }
}

//MARK: Color scheme enum
public enum ColorSchemeMode: CaseIterable {
    case light
    case dark
    case system
    
    public var description: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
}

//MARK: - Accent color
public enum AccentColorEnum: Codable, CaseIterable, Equatable, Identifiable {
    case blackGray
    case hotPink
    case magenta
    case purple
    case skyBlue
    case blue
    case cyan
    case green
    case lime
    case amber
    case yellow
    case orange
    case red
    case deepBlue
    case custom(String)
    
    public var id: String {
        switch self {
        case .blackGray: return "blackGray"
        case .hotPink: return "hotPink"
        case .magenta: return "magenta"
        case .purple: return "purple"
        case .skyBlue: return "skyBlue"
        case .blue: return "blue"
        case .cyan: return "cyan"
        case .green: return "green"
        case .lime: return "lime"
        case .amber: return "amber"
        case .yellow: return "yellow"
        case .orange: return "orange"
        case .red: return "red"
        case .deepBlue: return "deepBlue"
        case .custom: return "colorWheel"
        }
    }
    
    public func color() -> String {
        switch self {
        case .blackGray:
            return "#3F3F3F"
        case .hotPink:
            return "#F63378"
        case .magenta:
            return "#F633DE"
        case .purple:
            return "#A333F6"
        case .skyBlue:
            return "#5A7BFF"
        case .blue:
            return "#33AFF6"
        case .cyan:
            return "#0FB9DB"
        case .green:
            return "#0EBC7C"
        case .lime:
            return "#6BCA1E"
        case .amber:
            return "#DDA20C"
        case .yellow:
            return "#E9CA1C"
        case .orange:
            return "#F68333"
        case .red:
            return "#F63333"
        case .deepBlue:
            return "#3350F6"
        case .custom(let color):
            return color
        }
    }
    
    public static var allCases: [AccentColorEnum] {
        return [.blackGray, .hotPink, .magenta, .purple, .skyBlue,
                .blue, .cyan, .green, .lime, .amber,
                .yellow, .orange, .red, .deepBlue]
    }
}

//MARK: Background Color
public enum BackgroundColorEnum: Codable, CaseIterable, Equatable, Identifiable {
    case first
    case second
    case third
    case fourth
    
    public var id: String {
        switch self {
        case .first:
            return "first"
        case .second:
            return "second"
        case .third:
            return "third"
        case .fourth:
            return "fourth"
        }
    }
}

