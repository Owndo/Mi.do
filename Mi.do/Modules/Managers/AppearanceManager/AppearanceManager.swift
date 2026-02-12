//
//  AppearanceManager.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import SwiftUI
import Models
import ProfileManager

@Observable
final public class AppearanceManager: AppearanceManagerProtocol {
    
    private var profileManager: ProfileManagerProtocol
    
    public var profileModel: UIProfileModel
    public var colorScheme: ColorScheme?
    public var minimalProgressMode: Bool
    
    public var accentColor: Color = .green
    public var backgroundColor: Color = .white
    
    private init(profileManager: ProfileManagerProtocol) {
        self.profileManager = profileManager
        self.profileModel = profileManager.profileModel
        self.colorScheme = profileManager.profileModel.settings.colorScheme.colorScheme
        self.minimalProgressMode = profileManager.profileModel.settings.minimalProgressMode
    }
    
    //MARK: - Create Manager
    
    public static func createAppearanceManager(profileManager: ProfileManagerProtocol) -> AppearanceManagerProtocol {
        let manager = AppearanceManager(profileManager: profileManager)
        manager.accentColor = manager.returnAccentColor()
        manager.backgroundColor = manager.returnBackgroundColor()
        
        return manager
    }
    
    //MARK: - Create Mock Manager
    
    public static func createMockAppearanceManager() -> AppearanceManagerProtocol {
        AppearanceManager(profileManager: ProfileManager.createMockManager())
    }
    
    //MARK: - Create Environment Manager
    
    public static func createEnvironmentManager() -> AppearanceManagerProtocol {
        AppearanceManager(profileManager: ProfileManager.createEnvironmentManager())
    }
    
    //MARK: - Current color scheme
    
    public func updateColorScheme() {
        switch profileModel.settings.colorScheme {
        case .dark:
            colorScheme = .dark
        case .light:
            colorScheme = .light
        default:
            colorScheme =  nil
        }
    }
    
    //MARK: - Set color Scheme
    
    public func setColorScheme(_ mode: ColorSchemeMode) async throws {
        
        profileModel.settings.colorScheme = mode
        
        try await profileManager.updateProfileModel()
        
        updateColorScheme()
        updateColors()
    }
    
    public func changeProgressMode(_ value: Bool) async throws {
        profileModel.settings.minimalProgressMode = value
        try await profileManager.updateProfileModel()
        minimalProgressMode = value
    }
    
    //MARK: - Default Task Color
    
    public func changeDefaultTaskColor(_ color: TaskColor) async throws {
        profileModel.settings.defaultTaskColor = color
        try await profileManager.updateProfileModel()
    }
    
    public func changeAccentColor(_ color: AccentColorEnum) async throws {
        profileModel.settings.accentColor = color.setUpColor()
        try await profileManager.updateProfileModel()
        accentColor = returnAccentColor()
    }
    
    public func changeBackgroundColor(_ color: BackgroundColorEnum) async throws {
        profileModel.settings.background = color.setUpColor()
        try await profileManager.updateProfileModel()
        backgroundColor = returnBackgroundColor()
    }
    
    //MARK: - UpdateColors
    
    public func updateColors() {
        accentColor = returnAccentColor()
        backgroundColor = returnBackgroundColor()
    }
    
    //MARK: - Accent Color
    
    private func returnAccentColor() -> Color {
        if colorScheme == .dark {
            return profileModel.settings.accentColor.dark.hexColor()
        } else {
            return profileModel.settings.accentColor.light.hexColor()
        }
    }
    
    //MARK: - Background Color
    
    private func returnBackgroundColor() -> Color {
        switch colorScheme {
        case .dark:
            return profileModel.settings.background.dark.hexColor()
        case .light:
            return profileModel.settings.background.light.hexColor()
        default:
            return currentSystemColorSchemeIsDark() ? profileModel.settings.background.dark.hexColor() : profileModel.settings.background.light.hexColor()
        }
    }
    
    //MARK: - Track current color scheme
    
    private func currentSystemColorSchemeIsDark() -> Bool {
        return UITraitCollection.current.userInterfaceStyle == .dark
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
    
    public func showColor(_ colorScheme: ColorScheme) -> Color {
        switch self {
        case .blackGray:
            return "#3F3F3F".hexColor()
        case .hotPink:
            return "#F63378".hexColor()
        case .magenta:
            return "#F633DE".hexColor()
        case .purple:
            return "#A333F6".hexColor()
        case .skyBlue:
            return colorScheme == .light ? "#5A7BFF".hexColor() : "#708DFF".hexColor()
        case .blue:
            return "#33AFF6".hexColor()
        case .cyan:
            return colorScheme == .light ? "#0FB9DB".hexColor() : "#33F6F2".hexColor()
        case .green:
            return colorScheme == .light ? "#0EBC7C".hexColor() : "#18C585".hexColor()
        case .lime:
            return colorScheme == .light ? "#6BCA1E".hexColor() : "#60F633".hexColor()
        case .amber:
            return colorScheme == .light ? "#DDA20C".hexColor() : "#D7F633".hexColor()
        case .yellow:
            return colorScheme == .light ? "#E9CA1C".hexColor() : "#F6DC33".hexColor()
        case .orange:
            return "#F68333".hexColor()
        case .red:
            return "#F63333".hexColor()
        case .deepBlue:
            return colorScheme == .light ? "#3350F6".hexColor() : "#5069FB".hexColor()
        case .custom(let color):
            return color.hexColor()
        }
    }
    
    public func setUpColor() -> AccentBackgroundColor {
        switch self {
        case .blackGray:
            return AccentBackgroundColor(light: "#3F3F3F", dark: "#3F3F3F")
        case .hotPink:
            return AccentBackgroundColor(light: "#F63378", dark: "#F63378")
        case .magenta:
            return AccentBackgroundColor(light: "#F633DE", dark: "#F633DE")
        case .purple:
            return AccentBackgroundColor(light: "#A333F6", dark: "#A333F6")
        case .skyBlue:
            return AccentBackgroundColor(light: "#5A7BFF", dark: "#708DFF")
        case .blue:
            return AccentBackgroundColor(light: "#33AFF6", dark: "#33AFF6")
        case .cyan:
            return AccentBackgroundColor(light: "#0FB9DB", dark: "#33F6F2")
        case .green:
            return AccentBackgroundColor(light: "#0EBC7C", dark: "#18C585")
        case .lime:
            return AccentBackgroundColor(light: "#6BCA1E", dark: "#60F633")
        case .amber:
            return AccentBackgroundColor(light: "#DDA20C", dark: "#D7F633")
        case .yellow:
            return AccentBackgroundColor(light: "#F6DC33", dark: "#F6DC33")
        case .orange:
            return AccentBackgroundColor(light: "#F68333", dark: "#F68333")
        case .red:
            return AccentBackgroundColor(light: "#F63333", dark: "#F63333")
        case .deepBlue:
            return AccentBackgroundColor(light: "#3350F6", dark: "#5069FB")
        case .custom(let color):
            return AccentBackgroundColor(light: "#\(color)", dark: "#\(color)")
        }
    }
    
    public static var allCases: [AccentColorEnum] {
        return [.blackGray, .hotPink, .magenta, .purple, .skyBlue,
                .blue, .cyan, .green, .lime, .amber,
                .yellow, .orange, .red, .deepBlue]
    }
}

//MARK: Background Color
public enum BackgroundColorEnum: Codable, CaseIterable, Equatable, Hashable {
    case first
    case second
    case third
    case fourth
    case custom(String)
    
    public static var allCases: [BackgroundColorEnum] {
        return [.first, .second, .third, .fourth]
    }
    
    public func showColors(_ colorScheme: ColorScheme) -> Color {
        switch self {
        case .first:
            return colorScheme == .light ? "#F2F5EE".hexColor() : "#323232".hexColor()
        case .second:
            return colorScheme == .light ? "#FFFFFF".hexColor() : "#000000".hexColor()
        case .third:
            return colorScheme == .light ? "#F4F6F6".hexColor() : "#09161A".hexColor()
        case .fourth:
            return colorScheme == .light ? "#F5F4F6".hexColor() : "#150B21".hexColor()
        case .custom(let color):
            return color.hexColor()
        }
    }
    
    public func setUpColor() -> AccentBackgroundColor {
        switch self {
        case .first:
            return AccentBackgroundColor(light: "#F2F5EE", dark: "#202020")
        case .second:
            return AccentBackgroundColor(light: "#FFFFFF", dark: "#000000")
        case .third:
            return AccentBackgroundColor(light: "#F4F6F6", dark: "#09161A")
        case .fourth:
            return AccentBackgroundColor(light: "#F5F4F6", dark: "#150B21")
        case .custom(let color):
            return AccentBackgroundColor(light: "#\(color)", dark: "#\(color)")
        }
    }
}

// MARK: - ColorSchemeHelper

struct ColorSchemeHelper {
    static func isSystemLight() -> Bool {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.traitCollection.userInterfaceStyle == .light
        }
        
        return true
    }
}
