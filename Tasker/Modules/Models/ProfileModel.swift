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
    public var id: String = UUID().uuidString
    public var customTitle: String
    public var notes: String
    public var name: String
    public var photo: String
    public var photoPosition: CGSize
    public var createdProfile: Double = Date.now.timeIntervalSince1970
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
    public var firstDayOfWeek: Int?
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
    /// Create models, init app
    public var firstTimeOpen: Bool = true
    /// Greetengs for user when app will launch first time
    public var sayHello: Bool = true
    
    /// States for showing onboarding
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
    
    /// At this time onboarding has been created
    public var onboardingCreatedDate: Double = 1753717500.0
    public var onboardingCompleted = false
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
            return ("Your journey, day by day", "Swipe left or right to switch weeks")
        case .calendarTip:
            return ("Calendar", "Check the past or look at the future")
        case .profileTip:
            return ("Profile", "Your space")
        case .noteTip:
            return ("Notes", "Pull screen down")
        case .deleteTip:
            return ("Quick action", "Swipe left to delete with ease")
        case .searchTasksTip:
            return ("Find what matters...", "Tap the search icon to begin")
        case .openSubtasksTip:
            return ("Open subtasks...", "Double-tap to see the details")
        case .checkMarkTip:
            return ("Tap to complete", "Mark it done when you’re ready")
        case .listSwipeTip:
            return ("Navigate your days...", "Swipe to change, double tap to return")
        case .createButtonTip:
            return ("Plus button", "Hold for record or tap to create")
        }
    }
}
