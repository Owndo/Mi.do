//
//  OnboardingManager.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/25/25.
//

import Foundation
import Models
import ProfileManager
import TaskManager
import DateManager
import ConfigurationFile

@Observable
public final class OnboardingManager: OnboardingManagerProtocol {
    
    private var profileManager: ProfileManagerProtocol
    
    private var profileModel: UIProfileModel
    
    //MARK: - Onboarding flow
    
    //MARK: - Private init
    
    private init(profileManager: ProfileManagerProtocol) {
        self.profileManager = profileManager
        self.profileModel = profileManager.profileModel
    }
    
    //MARK: - Create Manager
    
    public static func createManager(profileManager: ProfileManagerProtocol) -> OnboardingManagerProtocol {
        let manager = OnboardingManager(profileManager: profileManager)
        
        return manager
    }
    
    public static func createMockManager() -> OnboardingManagerProtocol {
        OnboardingManager(profileManager: ProfileManager.createMockManager())
    }
    
    private func startManager() {
      
    }
    

    
    //MARK: - Onboarding flow
    
    public func onboardingStart() async {
        
    }
    
    private func profileModelSave() async throws {
        //        try await profileManager.updateProfileModel()
    }
}
