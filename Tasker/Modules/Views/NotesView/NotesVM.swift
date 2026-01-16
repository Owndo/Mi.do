//
//  NotesVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import AppearanceManager
import ProfileManager
import TelemetryManager
import Models
import SwiftUI

@Observable
public final class NotesVM {
    
    //MARK: - Dependencies
    
    private var appearanceManager: AppearanceManagerProtocol
    private var profileManager: ProfileManagerProtocol
    private var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    var profileModel: UIProfileModel
    
    public var mainViewIsOpen = true
    
    //MARK: - Init
    
    private init(appearanceManager: AppearanceManagerProtocol, profileManager: ProfileManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.profileManager = profileManager
        self.profileModel = profileManager.profileModel
    }
    
    //MARK: - Create VM
    
    public static func createVM(appearanceManager: AppearanceManagerProtocol, profileManager: ProfileManagerProtocol) -> NotesVM {
        let vm = NotesVM(appearanceManager: appearanceManager, profileManager: profileManager)
        return vm
    }
    
    //MARK: - CreatePreview VM
    
    public static func createPreviewVM() -> NotesVM {
        let vm = NotesVM(appearanceManager: AppearanceManager.createMockAppearanceManager(), profileManager: ProfileManager.createMockManager())
        return vm
    }
    
    func saveNotes() async {
        do {
            try await profileManager.updateProfileModel()
            telemetryAction(.mainViewAction(.addNotesButtonTapped))
        } catch {
            print("Couldn't update profile model notes")
        }
    }
    
    private func telemetryAction(_ event: EventType) {
        telemetryManager.logEvent(event)
    }
}
