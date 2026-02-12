//
//  NewVersionVM.swift
//  WelcomeView
//
//  Created by Rodion Akhmedov on 2/9/26.
//

import Foundation
import SwiftUI
import AppearanceManager
import WelcomeManager
import Models

@Observable
public final class WhatsNewVM: WelcomeVMProtocol, HashableNavigation {
    public var appearanceManager: AppearanceManagerProtocol
    public var welcomeManager: WelcomeManagerProtocol
    
    //MARK: - Private init
    
    private init(appearanceManager: AppearanceManagerProtocol, welcomeManager: WelcomeManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.welcomeManager = welcomeManager
    }
    
    //MARK: - Title
    
    public var title = WhatsNewVMResources.title
    
    //MARK: - Created text
    
    public let createdText = WhatsNewVMResources.createdText
    
    //MARK: - Created date
    
    public var createdDate = WhatsNewVMResources.createdDate
    
    //MARK: - Image description
    
    public let imageDescription = WhatsNewVMResources.imageDescription
    public let imageDescription1 = WhatsNewVMResources.imageDescription1
    public let imageDescription2 = WhatsNewVMResources.imageDescription2
    
    //MARK: - Description title
    
    public let descriptionTitle: LocalizedStringKey = WhatsNewVMResources.descriptionTitle
    public let descriptionTitle1: LocalizedStringKey = WhatsNewVMResources.descriptionTitle1
    public let descriptionTitle2: LocalizedStringKey = WhatsNewVMResources.descriptionTitle2
    
    //MARK: - Description
    
    public let description = WhatsNewVMResources.description
    public let description1 = WhatsNewVMResources.description1
    public let description2 = WhatsNewVMResources.description2
    
    //MARK: - Create VM
    
    public static func createVM(appearacneManager: AppearanceManagerProtocol, welcomeManager: WelcomeManagerProtocol) -> WhatsNewVM {
        WhatsNewVM(appearanceManager: appearacneManager, welcomeManager: welcomeManager)
    }
    
    //MARK: - Create previewVM
    
    static func createPreviewVM() -> WhatsNewVM {
        WhatsNewVM(appearanceManager: AppearanceManager.createEnvironmentManager(), welcomeManager: WelcomeManager.createMockManager())
    }
    
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

struct WhatsNewVMResources {
    
    //Title
    static let title: LocalizedStringKey = "What's New?"
    
    //MARK: - Version 1.2
    
    // Created text
    static let createdText: LocalizedStringKey = "Updated:"
    
    //Created date
    static let createdDate = Date(timeIntervalSince1970: 1753717500.0)
    
    // Image description
    static let imageDescription: String = "drop.circle.fill"
    static let imageDescription1: String = "calendar.badge.checkmark"
    static let imageDescription2: String = "eye.fill"
    
    // Description title
    static let descriptionTitle: LocalizedStringKey = "Liquid Glass"
    static let descriptionTitle1: LocalizedStringKey = "Calendar - now free"
    static let descriptionTitle2: LocalizedStringKey = "Task previews"
    
    // Description
    static let description: LocalizedStringKey = "A new, fluid look - light, depth, and motion that feel naturally alive."
    static let description1: LocalizedStringKey = "Plan your days freely. No limits, no unlocks."
    static let description2: LocalizedStringKey = "Tap a task to take a closer look - everything you need, right there."
}
