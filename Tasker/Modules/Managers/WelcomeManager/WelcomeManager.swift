//
//  WelcomeManager.swift
//  OnboardingView
//
//  Created by Rodion Akhmedov on 2/9/26.
//

import Foundation
import Models
import ProfileManager
import TaskManager
import DateManager
import ConfigurationFile

@Observable
public final class WelcomeManager: WelcomeManagerProtocol {
    
    private var profileManager: ProfileManagerProtocol
    private var profileModel: UIProfileModel
    
    //MARK: - Onboarding flow
    
    //MARK: - Private init
    
    private init(profileManager: ProfileManagerProtocol) {
        self.profileManager = profileManager
        self.profileModel = profileManager.profileModel
    }
    
    //MARK: - Create Manager
    
    public static func createManager(profileManager: ProfileManagerProtocol) -> WelcomeManagerProtocol {
        let manager = WelcomeManager(profileManager: profileManager)
        
        return manager
    }
    
    public static func createMockManager() -> WelcomeManagerProtocol {
        WelcomeManager(profileManager: ProfileManager.createMockManager())
    }
    
    //MARK: - Say Hello
    
    /// First time ever open
    public func appLaunchState() -> AppLaunchState? {
        //        guard let storedVersion = profileModel.onboarding.latestVersion else {
        return .welcome
        //        }
        
        //        guard storedVersion == ConfigurationFile.appVersion else {
        //            return .afterUpdate
        //        }
        
        //        return nil
    }
    
    public func firstTimeOpenDone() async throws {
        try await profileManager.updateVersion(to: ConfigurationFile.appVersion)
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
        try await profileManager.updateProfileModel()
    }
}

//MARK: - App Lanch State

public enum AppLaunchState {
    case welcome
    case afterUpdate
}
