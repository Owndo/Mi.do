//
//  OnBoardingModel.swift
//  Models
//
//  Created by Rodion Akhmedov on 8/3/25.
//

import Foundation
import SwiftUI

public struct OnboardingModel: Codable, Equatable {
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
