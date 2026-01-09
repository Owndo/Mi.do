//
//  NotesVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import ProfileManager
import TelemetryManager
import Models
import SwiftUI

@Observable
public final class NotesVM {
    //MARK: - Dependencies
    
    var profileManager: ProfileManagerProtocol
    var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    var profileModel: UIProfileModel
    
    public var mainViewIsOpen = true
    
    //MARK: - Init
    
    private init(profileManager: ProfileManagerProtocol) {
        self.profileManager = profileManager
        self.profileModel = profileManager.profileModel
    }
    
    //MARK: - Create VM
    
    public static func createVM(profileManager: ProfileManagerProtocol) -> NotesVM {
        let vm = NotesVM(profileManager: profileManager)
        return vm
    }
    
    //MARK: - CreatePreview VM
    
    public static func createPreviewVM() -> NotesVM {
        let vm = NotesVM(profileManager: ProfileManager.createMockProfileManager())
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
