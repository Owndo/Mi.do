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
    /// Base tasks for example have been created
    public var baseTasksCreated: Bool?
    
//    /// States for showing onboarding
//    public var dayTip = false
//    public var calendarTip = false
//    public var profileTip = false
//    public var noteTip = false
//    public var deleteTip = false
//    public var searchTasksTip = false
//    public var openSubtasksTip = false
//    public var checkMarkTip = false
//    public var listSwipeTip = false
//    public var createButtonTip = false
//    
    /// At this time onboarding has been created
    public var onboardingCreatedDate: Double = 1753717500.0
}
