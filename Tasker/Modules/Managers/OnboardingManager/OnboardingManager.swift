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
    
    
//    public var sayHello = false
    /// User has old version
    public var showWhatsNew = false
    
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
        guard let version = welcomeToMido() else {
            return
        }
        
        guard version != ConfigurationFile.appVersion else {
            return
        }
        
        print("Old version")
    }
    
    //MARK: - Say Hello
    
    /// First time ever open
    public func welcomeToMido() -> String? {
        guard let version = profileModel.onboarding.latestVersion else {
            return nil
        }
        
        return version
    }
    
    public func firstTimeOpenDone() async throws {
        try await profileManager.updateVersion(to: ConfigurationFile.appVersion)
    }
    
    //MARK: - Onboarding flow
    
    public func onboardingStart() async {
        
    }
    
    //MARK: - Create base Task
    
    //    private func createBaseTasks() async throws {
    //        guard profileModel.onboarding.latestVersion == nil else {
    //            return
    //        }
    //
    //        let factory = ModelsFactory(dateManager: dateManager)
    //
    //        try await taskManager.saveTask(factory.create(.bestApp))
    //        try await taskManager.saveTask(factory.create(.planForTommorow, repeatTask: .weekly))
    //        try await taskManager.saveTask(factory.create(.randomHours))
    //        try await taskManager.saveTask(factory.create(.readSomething))
    //
    //
    //        guard !dateManager.calendar.isDate(dateManager.currentTime, inSameDayAs: dateManager.sunday()) else {
    //            return
    //        }
    //
    //        try await taskManager.saveTask(factory.create(.planForTommorow))
    //    }
    
    private func profileModelSave() async throws {
        profileModel.onboarding.latestVersion = ConfigurationFile.appVersion
        
//        try await profileManager.updateProfileModel()
    }
}
