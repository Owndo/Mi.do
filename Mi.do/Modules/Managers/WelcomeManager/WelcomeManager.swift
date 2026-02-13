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
    
    //MARK: - Managers
    
    private var dateManager: DateManagerProtocol
    private var profileManager: ProfileManagerProtocol
    private var taskManager: TaskManagerProtocol
    
    private var firstTimeLaunch = false
    
    //MARK: - Profile model
    
    private var profileModel: UIProfileModel
    
    //MARK: - Private init
    
    private init(dateManager: DateManagerProtocol, profileManager: ProfileManagerProtocol, taskManager: TaskManagerProtocol) {
        self.dateManager = dateManager
        self.profileManager = profileManager
        self.taskManager = taskManager
        self.profileModel = profileManager.profileModel
    }
    
    //MARK: - Create Manager
    
    public static func createManager(dateManager: DateManagerProtocol, profileManager: ProfileManagerProtocol, taskManager: TaskManagerProtocol) -> WelcomeManagerProtocol {
        let manager = WelcomeManager(dateManager: dateManager, profileManager: profileManager, taskManager: taskManager)
        
        return manager
    }
    
    public static func createMockManager() -> WelcomeManagerProtocol {
        WelcomeManager(dateManager: DateManager.createEmptyManager(), profileManager: ProfileManager.createMockManager(), taskManager: TaskManager.createMockTaskManager())
    }
    
    //MARK: - Say Hello
    
    /// First time ever open
    public func appLaunchState() -> AppLaunchState? {
        guard let storedVersion = profileModel.onboarding.latestVersion else {
            if profileModel.onboarding.onboardingCreatedDate != nil {
                return .afterUpdate
            }
            
            firstTimeLaunch = true
            return .welcome
        }
        
        guard let stored = majorMinor(from: storedVersion), let current = majorMinor(from: ConfigurationFile.appVersion) else {
            return nil
        }
        
        if stored.major < current.major {
            return .afterUpdate
        }
        
        if stored.major == current.major && stored.minor < current.minor {
            return .afterUpdate
        }
        
        return nil
    }
    
    public func firstTimeOpenDone() async throws {
        try await profileManager.updateVersion(to: ConfigurationFile.appVersion)
        guard firstTimeLaunch else { return }
        try await createBaseTasks()
    }
    
    //MARK: - Create base Task
    
    private func createBaseTasks() async throws {
        let factory = ModelsFactory(dateManager: dateManager)
        
        try await taskManager.saveTask(factory.create(.bestApp))
        try await taskManager.saveTask(factory.create(.planForTommorow, repeatTask: .weekly))
        try await taskManager.saveTask(factory.create(.randomHours, repeatTask: .weekly))
        try await taskManager.saveTask(factory.create(.readSomething))
        
        guard !dateManager.calendar.isDate(dateManager.currentTime, inSameDayAs: dateManager.sunday()) else {
            return
        }
        
        try await taskManager.saveTask(factory.create(.planForTommorow))
    }
    
    private func profileModelSave() async throws {
        profileModel.onboarding.latestVersion = ConfigurationFile.appVersion
        try await profileManager.updateProfileModel()
    }
    
    //MARK: - Convert Version
    private func majorMinor(from version: String) -> (major: Int, minor: Int)? {
        
        let components = version.split(separator: ".")
        
        guard components.count >= 2,
              let major = Int(components[0]),
              let minor = Int(components[1]) else {
            return nil
        }
        
        return (major, minor)
    }
}

//MARK: - App Lanch State

public enum AppLaunchState {
    case welcome
    case afterUpdate
}
