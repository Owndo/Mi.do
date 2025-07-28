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
    public var onboarding: OnboardingModel
    
    public init(
        customTitle: String,
        notes: String,
        name: String,
        photo: String,
        photoPosition: CGSize,
        settings: SettingsModel,
        onboarding: OnboardingModel
    ) {
        self.customTitle = customTitle
        self.notes = notes
        self.name = name
        self.photo = photo
        self.photoPosition = photoPosition
        self.settings = settings
        self.onboarding = onboarding
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
            ),
            onboarding: OnboardingModel()
        )
    )
}

public enum ColorSchemeMode: CaseIterable, Codable, Sendable {
    case light
    case dark
    case system
    
    public var description: LocalizedStringKey {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
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

public struct OnboardingModel: Codable {
    public var firstTimeOpen: Bool = true
    public var dayTip: Bool = false
    public var calendarTip: Bool = false
    public var profileTip: Bool = false
    public var noteTip: Bool = false
    public var deleteTip: Bool = false
    public var searchTasksTip: Bool = false
    public var openSubtasksTip: Bool = false
    public var checkMarkTip: Bool = false
    public var listSwipeTip: Bool = false
    public var createButtonTip: Bool = false
}

public enum OnboardingModelEnum {
    case dayTip
    case calendarTip
    case profileTip
    case noteTip
    // Delete
    case deleteTip
    
    // Search
    case searchTasksTip
    // Subtasks
    case openSubtasksTip
    case listSwipeTip
    
    // Task view
    case checkMarkTip
    
    // Main button
    case createButtonTip
    
    public var typeOfTips: (LocalizedStringKey, LocalizedStringKey) {
        switch self {
        case .dayTip:
            return ("Your task by day", "Switch between dates and\nsee the challenges")
        case .calendarTip:
            return ("Calendar", "Quick access to your tasks")
        case .profileTip:
            return ("Profile", "Your data, news and app\ncustomization")
        case .noteTip:
            return ("Add notes..", "Pull down to start")
        case .deleteTip:
            return ("Swipe to delete", "Swipe to the left to delete a task")
        case .searchTasksTip:
            return ("Find your tasks..", "Tap the search button to get started")
        case .openSubtasksTip:
            return ("Open subtasks..", "A double tap will expand\nthe subtasks")
        case .checkMarkTip:
            return ("Tap to complete", "When you've completed\nthis task")
        case .listSwipeTip:
            return ("Controll here..", "Swipe for change date\ndouble tap to back")
        case .createButtonTip:
            return ("Just say our task", "Tap or hold the plus button\nto get started")
        }
    }
}
