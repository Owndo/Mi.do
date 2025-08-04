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
    
    var profileModel = mockProfileData()
    
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
    }
    
    public func firstTimeOpen() async {
        
        if profileModel.value.onboarding.sayHello {
            sayHello = true
            
            while sayHello {
                try? await Task.sleep(for: .seconds(0.1))
            }
        }
        
        guard !profileModel.value.onboarding.onboardingCompleted else {
            return
        }
        
        await onboardingStart()
    }
    
    //MARK: - Onboarding flow
    public func onboardingStart() async {
        if profileModel.value.onboarding.dayTip == false {
            dayTip = true
            
            while dayTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            profileModel.value.onboarding.dayTip = true
        }
        
        if profileModel.value.onboarding.calendarTip == false {
            calendarTip = true
            
            while calendarTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            profileModel.value.onboarding.calendarTip = true
        }
        
        if profileModel.value.onboarding.profileTip == false {
            profileTip = true
            
            while profileTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.value.onboarding.profileTip = true
        }
        
        if profileModel.value.onboarding.noteTip == false {
            notesTip = true
            
            while notesTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.value.onboarding.noteTip = true
        }
        
        if profileModel.value.onboarding.deleteTip == false {
            deleteTip = true
            
            while deleteTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.value.onboarding.deleteTip = true
        }
        
        if profileModel.value.onboarding.listSwipeTip == false {
            listSwipeTip = true
            
            while listSwipeTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.value.onboarding.listSwipeTip = true
        }
        
        if profileModel.value.onboarding.createButtonTip == false {
            createButtonTip = true
            
            while createButtonTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.value.onboarding.createButtonTip = true
        }
        
        profileModel.value.onboarding.onboardingCompleted = true
        sayHello = false
        profileModel.value.onboarding.sayHello = false
        
        profileModelSave()
    }
    
    func profileModelSave() {
        casManager.saveProfileData(profileModel)
    }
}
