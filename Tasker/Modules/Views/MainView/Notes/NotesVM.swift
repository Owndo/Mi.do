//
//  NotesVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import Managers
import Models

@Observable
final class NotesVM {
    @ObservationIgnored
    @Injected(\.casManager) var casManager
    @ObservationIgnored
    @Injected(\.appearanceManager) var appearanceManager
    @ObservationIgnored
    @Injected(\.telemetryManager) var telemetryManager
    
    var profileModel: ProfileData = mockProfileData()
    
    func colorScheme() -> String {
        appearanceManager.colorScheme()
    }
    
    init() {
        profileModel = casManager.profileModel ?? mockProfileData()
    }
    
    func saveNotes() {
        casManager.saveProfileData(profileModel)
        telemetryAction(.mainViewAction(.addNotesButtonTapped))
    }
    
    private func telemetryAction(_ event: EventType) {
        telemetryManager.logEvent(event)
    }
}
