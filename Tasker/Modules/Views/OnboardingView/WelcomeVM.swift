//
//  WelcomeVM.swift
//  OnboardingView
//
//  Created by Rodion Akhmedov on 2/9/26.
//


import Foundation
import SwiftUI
import AppearanceManager
import OnboardingManager
import Models

@Observable
public final class WelcomeVM: HashableNavigation {
    var appearanceManager: AppearanceManagerProtocol
    var onboardingManager: OnboardingManagerProtocol
    
    //MARK: - Private init
    
    private init(appearanceManager: AppearanceManagerProtocol, onboardingManager: OnboardingManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.onboardingManager = onboardingManager
    }
    
    //MARK: - Title
    
    var title = "Welcome to Mi.dō"
    var createdDate = Date(timeIntervalSince1970: 1753717500.0)
    var closeTriger = false
    
    //MARK: - Description
    
    // Old value
//    var description1: LocalizedStringKey = "Life isn’t a goal, it's a journey.\nWe’re happy to walk it with you."
//    var description2: LocalizedStringKey = "Create tasks, reminders,\nnotes or voice recordings - we’ll\nsafe them and quietly remind you\nwhen it matters."
//    var description3: LocalizedStringKey = "Everything stays in your hands\nand never leaves your device.\nPlan your life with Mi.dō!"
    
    // New value
    var description1: LocalizedStringKey = "Life isn’t a goal, it's a journey.\nWe’re here to walk it with you."
    var description2: LocalizedStringKey = "Create tasks, reminders,\nnotes or voice recordings - we’ll\nsave and gently remind you\nwhen it truly matters."
    var description3: LocalizedStringKey = "Everything stays in your hands\nand never leaves your device.\nYour life. Your data."
    
    //MARK: - Create VM
    
    public static func createVM(appearacneManager: AppearanceManagerProtocol, onboardingManager: OnboardingManagerProtocol) -> WelcomeVM {
        WelcomeVM(appearanceManager: appearacneManager, onboardingManager: onboardingManager)
    }
    
    //MARK: - Create previewVM
    
    static func createPreviewVM() -> WelcomeVM {
        WelcomeVM(appearanceManager: AppearanceManager.createEnvironmentManager(), onboardingManager: OnboardingManager.createMockManager())
    }
    
    func welcomeToMidoClose() async {
        do {
            try await onboardingManager.firstTimeOpenDone()
        } catch {
            //TODO: - Error
            print("Error")
        }
    }
}
