//
//  OnboardingVM.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/29/25.
//

import Foundation
import Managers
import Models
import SwiftUICore

@Observable
final class OnboardingVM {
    @ObservationIgnored
    @Injected(\.onboardingManager) var onboardingManager
    @ObservationIgnored
    @Injected(\.casManager) var casManager
    
    var title = "Welcome to Mi.dō"
    var createdDate = Date()
    var closeTriger = false
    
    var profileModel = mockProfileData()
    
    var description1: LocalizedStringKey = "Life isn’t a goal, it's journey.\nWe’re happy to walk it with you."
    var description2: LocalizedStringKey = "Create tasks, reminders,\nnotes or voice recordings - we’ll\nsafe them and quietly remind you\nwhen it matters."
    var description3: LocalizedStringKey = "Everything stays in your hands\nand never leaves your device.\nPlan your life with Mi.dō!"
    
    init() {
        profileModel = casManager.profileModel
        createdDate = Date(timeIntervalSince1970: casManager.profileModel.value.onboarding.onboardingCreatedDate)
    }
    
    func continueButtontapped() {
        guard onboardingManager.sayHello else {
            return
        }
        
        closeTriger.toggle()
        onboardingManager.sayHello = false
        profileModel.value.onboarding.sayHello = false
    }
}
