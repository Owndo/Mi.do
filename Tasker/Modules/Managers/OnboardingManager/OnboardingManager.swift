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

@Observable
public final class OnboardingManager: OnboardingManagerProtocol {
    private var profileManager: ProfileManagerProtocol
    private var taskManager: TaskManagerProtocol
    private var dateManager: DateManagerProtocol
    
    private var profileModel: UIProfileModel {
        get {
            profileManager.profileModel
        }
        set {
            profileManager.profileModel = newValue
        }
    }
    
    //MARK: - Onboarding flow
    public var sayHello = false
    
    public var showWhatsNew = false
    
    public var onboardingComplete = false
    
    init(profileManager: ProfileManagerProtocol, taskManager: TaskManagerProtocol, dateManager: DateManagerProtocol) {
        self.taskManager = taskManager
        self.profileManager = profileManager
        self.dateManager = dateManager
        
        firstTimeOpen()
    }
    
    func firstTimeOpen() {
        guard let latestVersion = profileModel.onboarding.latestVersion else {
            sayHello = true
            return
        }
        
        onboardingComplete = true
    }
    
    public func firstTimeOpenDone() async throws {
        sayHello = false
        
        try await createBaseTasks()
        try await profileModelSave()
    }
    
    //MARK: - Onboarding flow
    public func onboardingStart() async {
        
    }
    
    //MARK: - Create base Task
    
    private func createBaseTasks() async throws {
        guard profileModel.onboarding.latestVersion == nil else {
            return
        }
        
        let factory = ModelsFactory(dateManager: dateManager)
        
        try await taskManager.saveTask(factory.create(.bestApp))
        try await taskManager.saveTask(factory.create(.planForTommorow, repeatTask: .weekly))
        try await taskManager.saveTask(factory.create(.randomHours))
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
}
