//
//  ProfileModel.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import BlockSet
import SwiftUICore
import UIKit

public typealias ProfileData = Model<ProfileModel>

public struct ProfileModel: Codable {
    public var customTitle: String
    public var notes: String
    public var name: String
    public var photo: String
    public var photoPosition: CGSize
    public var settings: SettingsModel
    
    public init(
        customTitle: String,
        notes: String,
        name: String,
        photo: String,
        photoPosition: CGSize,
        settings: SettingsModel
    ) {
        self.customTitle = customTitle
        self.notes = notes
        self.name = name
        self.photo = photo
        self.photoPosition = photoPosition
        self.settings = settings
    }
}

public struct SettingsModel: Codable, Equatable {
    public var firstDayOfWeek: Int
    public var colorScheme: ColorSchemeMode
    public var accentColor: AccentBackgroundColor
    public var background: AccentBackgroundColor
    public var minimalProgressMode: Bool
    public var completedTasksHidden: Bool
    
    public init(
        firstDayOfWeek: Int,
        colorScheme: ColorSchemeMode,
        accentColor: AccentBackgroundColor = AccentBackgroundColor(light: "#0EBC7C", dark: "#18C585"),
        background: AccentBackgroundColor = AccentBackgroundColor(light: "#F2F5EE", dark: "#202020"),
        minimalProgressMode: Bool = true,
        completedTasksHidden: Bool = false
    ) {
        self.firstDayOfWeek = firstDayOfWeek
        self.colorScheme = colorScheme
        self.accentColor = accentColor
        self.background = background
        self.minimalProgressMode = minimalProgressMode
        self.completedTasksHidden = completedTasksHidden
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

public struct AccentBackgroundColor: Codable, Equatable {
    public var light: String
    public var dark: String
    
    public init(light: String, dark: String) {
        self.light = light
        self.dark = dark
    }
}

public func mockProfileData() -> ProfileData {
    ProfileData.initial(
        ProfileModel(
            customTitle: "",
            notes: "",
            name: "",
            photo: "",
            photoPosition: .zero,
            settings: SettingsModel(
                firstDayOfWeek: 1,
                colorScheme: .system,
                accentColor: AccentBackgroundColor(light: "#0EBC7C", dark: "#18C585"),
                background: AccentBackgroundColor(light: "#F2F5EE", dark: "#202020")
            )
        )
    )
}

public enum ColorSchemeMode: CaseIterable, Codable, Sendable {
    case light
    case dark
    case system
    
    public var description: String {
        switch self {
        case .light:
            return "light"
        case .dark:
            return "dark"
        case .system:
            return "system"
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return ColorScheme.light
        case .dark:
            return ColorScheme.dark
        case .system:
            return ColorScheme(.unspecified)
        }
    }
}
