//
//  OnboardingManager.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/25/25.
//

import Foundation
import Models

@Observable
public final class OnboardingManager: OnboardingManagerProtocol {
    @ObservationIgnored
    @Injected(\.casManager) var casManager
    @ObservationIgnored
    @Injected(\.subscriptionManager) var subscriptionManager
    
    var profileModel = mockProfileData()
    
    public var showingCalendar: ((Bool) -> Void)?
    public var showingProfile: ((Bool) -> Void)?
    public var showingNotes: ((Bool) -> Void)?
    public var scrollWeek: ((Bool) -> Void)?
    
    //MARK: - Onboarding flow
    public var sayHello = false
    
    public var onboardingComplete = false
    public var dayTip = false
    public var calendarTip = false
    public var profileTip = false
    public var notesTip = false
    public var deleteTip = false
    public var listSwipeTip = false
    public var createButtonTip = false
    
    init() {
        profileModel = casManager.profileModel
        firstTimeOpen()
    }
    
    func firstTimeOpen() {
        if profileModel.onboarding.sayHello {
            sayHello = true
        }
    }
    
    //MARK: - Onboarding flow
    public func onboardingStart() async {
   
    }
    
    private func profileModelSave() {
        profileModel.onboarding.sayHello = false
        casManager.saveProfileData(profileModel)
    }
}
