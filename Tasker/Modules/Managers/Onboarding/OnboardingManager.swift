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
    
    //MARK: - Onboarding flow
    public var sayHello = false
    
    public var showWhatsNew = false
    
    public var onboardingComplete = false
    
    init() {
        profileModel = casManager.profileModel
        firstTimeOpen()
    }
    
    func firstTimeOpen() {
        guard let latestVersion = profileModel.onboarding.latestVersion else {
            sayHello = true
            return
        }
        
        onboardingComplete = true
    }
    
    public func firstTimeOpenDone() {
        sayHello = false
        onboardingComplete = true
        
        createBaseTasks()
        
        profileModel.onboarding.latestVersion = ConfigurationFile.appVersion
        
        profileModelSave()
        
        NotificationCenter.default.post(name: NSNotification.Name("firstTimeOpenHasBeenDone"), object: nil)
    }
    
    //MARK: - Onboarding flow
    public func onboardingStart() async {
        
    }
    
    //MARK: - Onboarding
    private func createBaseTasks() {
        guard profileModel.onboarding.latestVersion == nil else {
            return
        }
        
        let factory = ModelsFactory()
        
        casManager.saveModel(factory.create(.planForTommorow))
        casManager.saveModel(factory.create(.bestApp))
        casManager.saveModel(factory.create(.planForTommorow, repeatTask: .weekly))
        casManager.saveModel(factory.create(.randomHours))
        casManager.saveModel(factory.create(.readSomething))
    }
    
    private func profileModelSave() {
        casManager.saveProfileData(profileModel)
    }
}
