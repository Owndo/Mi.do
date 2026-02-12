//
//  FirstLaunchVM.swift
//  OnboardingView
//
//  Created by Rodion Akhmedov on 2/9/26.
//


import Foundation
import SwiftUI
import AppearanceManager
import WelcomeManager
import Models
import UIComponents

@Observable
public final class FirstLaunchVM: WelcomeVMProtocol, HashableNavigation {
    public var appearanceManager: AppearanceManagerProtocol
    public var welcomeManager: WelcomeManagerProtocol
    
    //MARK: - Private init
    
    private init(appearanceManager: AppearanceManagerProtocol, welcomeManager: WelcomeManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.welcomeManager = welcomeManager
    }
    
    //MARK: - Title
    
    public let title = FirstLaunchVMResources.title
    
    public let createdText = FirstLaunchVMResources.createdText
    
    //MARK: - Created date
    
    public var createdDate = FirstLaunchVMResources.createdDate
    
    public let imageDescription = FirstLaunchVMResources.imageDescription
    public let imageDescription1 = FirstLaunchVMResources.imageDescription1
    public let imageDescription2 = FirstLaunchVMResources.imageDescription2
    
    //MARK: - Description title
    
    public let descriptionTitle: LocalizedStringKey = FirstLaunchVMResources.descriptionTitle
    public let descriptionTitle1: LocalizedStringKey = FirstLaunchVMResources.descriptionTitle1
    public let descriptionTitle2: LocalizedStringKey = FirstLaunchVMResources.descriptionTitle2
    
    //MARK: - Description
    
    public let description = FirstLaunchVMResources.description
    public let description1 = FirstLaunchVMResources.description1
    public let description2 = FirstLaunchVMResources.description2
    
    //MARK: - Create VM
    
    public static func createVM(appearacneManager: AppearanceManagerProtocol, welcomeManager: WelcomeManagerProtocol) -> FirstLaunchVM {
        FirstLaunchVM(appearanceManager: appearacneManager, welcomeManager: welcomeManager)
    }
    
    //MARK: - Create previewVM
    
    static func createPreviewVM() -> FirstLaunchVM {
        FirstLaunchVM(appearanceManager: AppearanceManager.createEnvironmentManager(), welcomeManager: WelcomeManager.createMockManager())
    }
    
    //MARK: - Welcome close
    
    public func welcomeToMidoClose() async {
        do {
            try await welcomeManager.firstTimeOpenDone()
        } catch {
            //TODO: - Error
            print("Error")
        }
    }
}

//MARK: - Resources

struct FirstLaunchVMResources {
    // Version 1.1.3
    ///    var description1: LocalizedStringKey = "Life isn’t a goal, it's a journey.\nWe’re happy to walk it with you."
    ///    var description2: LocalizedStringKey = "Create tasks, reminders,\nnotes or voice recordings - we’ll\nsafe them and quietly remind you\nwhen it matters."
    ///    var description3: LocalizedStringKey = "Everything stays in your hands\nand never leaves your device.\nPlan your life with Mi.dō!"
    
    
    //MARK: - Version 1.2
    
    //Title
    static let title: LocalizedStringKey = "Welcome to Mi.dō"
    
    static let createdText: LocalizedStringKey = "Created:"
    
    //Created date
    static let createdDate = Date(timeIntervalSince1970: 1753717500.0)
    
    // Image description
    static let imageDescription: String = "road.lanes.curved.right"
    static let imageDescription1: String = osVersion.majorVersion < 26 ? "checkmark.square" : "checkmark.app"
    static let imageDescription2: String = "hand.point.up.left.and.text"
    
    // Description title
    static let descriptionTitle: LocalizedStringKey = "Your path"
    static let descriptionTitle1: LocalizedStringKey = "Your focus"
    static let descriptionTitle2: LocalizedStringKey = "Your data"
    
    // Description
    static let description: LocalizedStringKey = "Life isn’t a goal, it's a journey. We’re here to walk it with you."
    static let description1: LocalizedStringKey = "Create tasks, reminders, notes or voice recordings - we’ll save and gently remind you when it truly matters."
    static let description2: LocalizedStringKey = "Everything stays in your hands and never leaves your device. Your life. Your data."
}
