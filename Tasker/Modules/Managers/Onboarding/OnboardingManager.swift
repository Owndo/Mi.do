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
        
        if profileModel.onboarding.sayHello {
            sayHello = true
            
            while sayHello {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            sayHello = false
        }
        
        await onboardingStart()
    }
    
    //MARK: - Onboarding flow
    public func onboardingStart() async {
        if profileModel.onboarding.dayTip == false {
            dayTip = true
            
            while dayTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            profileModel.onboarding.dayTip = true
        }
        
        if profileModel.onboarding.calendarTip == false {
            calendarTip = true
            
            while calendarTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            profileModel.onboarding.calendarTip = true
        }
        
        if profileModel.onboarding.profileTip == false {
            profileTip = true
            
            while profileTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.onboarding.profileTip = true
        }
        
        if profileModel.onboarding.noteTip == false {
            notesTip = true
            
            while notesTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.onboarding.noteTip = true
        }
        
        if profileModel.onboarding.deleteTip == false {
            deleteTip = true
            
            while deleteTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.onboarding.deleteTip = true
        }
        
        if profileModel.onboarding.listSwipeTip == false {
            listSwipeTip = true
            
            while listSwipeTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.onboarding.listSwipeTip = true
        }
        
        if profileModel.onboarding.createButtonTip == false {
            createButtonTip = true
            
            while createButtonTip {
                try? await Task.sleep(for: .seconds(0.1))
            }
            
            profileModel.onboarding.createButtonTip = true
        }
        
        profileModel.onboarding.sayHello = false
        
        profileModelSave()
    }
    
    func profileModelSave() {
        casManager.saveProfileData(profileModel)
    }
}
