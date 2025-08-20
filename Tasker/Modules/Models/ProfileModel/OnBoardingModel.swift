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
    public var firstTimeOpen = true
    /// Request review
    public var requestedReview: Bool?
    /// Greetengs for user when app will launch first time
    public var sayHello = true
    
    /// States for showing onboarding
    public var dayTip = false
    public var calendarTip = false
    public var profileTip = false
    public var noteTip = false
    public var deleteTip = false
    public var searchTasksTip = false
    public var openSubtasksTip = false
    public var checkMarkTip = false
    public var listSwipeTip = false
    public var createButtonTip = false
    
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
            return ("Open subtasks...", "Double - tap to see the details")
        case .checkMarkTip:
            return ("Tap to complete", "Mark it done when you’re ready")
        case .listSwipeTip:
            return ("Switch days below...", "Swipe under tasks to change, double tap to return")
        case .createButtonTip:
            return ("Create tasks with your voice", "Hold the plus to speak, or just tap to create")
        }
    }
}
