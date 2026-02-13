//
//  OnBoardingModel.swift
//  Models
//
//  Created by Rodion Akhmedov on 8/3/25.
//

import Foundation
import SwiftUI

public struct OnboardingModel: Codable, Equatable {
    /// Check last user version fro showing what's new
    public var latestVersion: String?
    /// Request review
    public var requestedReview: Bool?
    
    /// At this time onboarding has been created
    public var onboardingCreatedDate: Double?
}

@Observable
public final class UIOnboardingModel {
    public var model: OnboardingModel {
        didSet {
            guard model != oldValue else { return }
            onChange(model)
        }
    }
    
    private let onChange: (OnboardingModel) -> Void
    
    init(_ model: OnboardingModel, onChange: @escaping (OnboardingModel) -> Void) {
        self.model = model
        self.onChange = onChange
    }
    
    public var latestVersion: String? {
        get { model.latestVersion }
        set { model.latestVersion = newValue }
    }
    
    public var requestedReview: Bool {
        get { model.requestedReview ?? false }
        set { model.requestedReview = newValue ? true : nil }
    }
    
    public var onboardingCreatedDate: Double? { model.onboardingCreatedDate }
}

func defaultOnboardingModel() -> OnboardingModel {
    OnboardingModel()
}
