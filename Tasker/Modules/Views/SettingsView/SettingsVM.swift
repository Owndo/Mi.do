//
//  SettingsVM.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/28/25.
//

import Foundation
import Models
import DateManager
import ProfileManager
import TelemetryManager
import SwiftUI

@Observable
public final class SettingsVM: HashableNavigation {
    private var dateManager: DateManagerProtocol
    private var profileManager: ProfileManagerProtocol
    private var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    var profileModel: UIProfileModel
    
    public var backButton: (() -> Void)?
    public var appearanceButton: (() -> Void)?
    
    var firstDayOfWeek: FirstWeekDay = .sunday
    
    enum FirstWeekDay: Int, CaseIterable, Hashable {
        case sunday = 1
        case monday = 2
        
        var description: LocalizedStringKey {
            switch self {
            case .sunday:
                return "Sunday"
            case .monday:
                return "Monday"
            }
        }
    }
    
    //    var syncWithIcloud = false {
    //        didSet {
    //            Task {
    //                await changeToogleOfSync()
    //            }
    //        }
    //    }
    
    var calendar: Calendar = .current
    var createdDate = Date()
    
    private init(dateManager: DateManagerProtocol, profilemanager: ProfileManagerProtocol, profileModel: UIProfileModel) {
        self.dateManager = dateManager
        self.profileManager = profilemanager
        self.profileModel = profileModel
        //        profileModel = profileManager.profileModel
        //        firstDayOfWeek = profileModel.settings.firstDayOfWeek == 1 ? .sunday : .monday
        
        //        createdDate = Date(timeIntervalSince1970: profileModel.createdProfile)
        //        syncWithIcloud = profileModel.settings.iCloudSyncEnabled
        //        calendar = dateManager.calendar
    }
    
    //TODO: - Check first day of week
    //MARK: - Create SettingsVM
    
    public static func createSettingsVM(dateManager: DateManagerProtocol, profileManager: ProfileManagerProtocol) -> SettingsVM {
        let settingsVM = SettingsVM(dateManager: dateManager, profilemanager: profileManager, profileModel: profileManager.profileModel)
        settingsVM.firstDayOfWeek = profileManager.profileModel.settings.firstDayOfWeek == 1 ? .sunday : .monday
        
        return settingsVM
    }
    
    //MARK: - Create MOKCSettingsVM
    
    static func createMOCKSettingsVM() -> SettingsVM {
        let dateManager = DateManager.createPreviewManager()
        let profilemanager = ProfileManager.createMockManager()
        let settingsVM = SettingsVM(dateManager: dateManager, profilemanager: profilemanager, profileModel: profilemanager.profileModel)
        settingsVM.firstDayOfWeek = profilemanager.profileModel.settings.firstDayOfWeek == 1 ? .sunday : .monday
        
        return settingsVM
    }
    
    //    func goTo(path: inout NavigationPath, destination: ProfileDestination) {
    //        path.append(destination)
    //    }
    
    func changeFirstDayOfWeek(_ firstDayOfWeek: FirstWeekDay) async {
        profileModel.settings.firstDayOfWeek = firstDayOfWeek.rawValue
        do {
            try await profileModelSave()
            self.firstDayOfWeek = firstDayOfWeek
            dateManager.calendar.firstWeekday = firstDayOfWeek.rawValue
        } catch {
            //TODO: - Add Some enum with error
            print("some error")
        }
    }
    
    //    func changeToogleOfSync() async {
    //        profileModel.settings.iCloudSyncEnabled = syncWithIcloud
    //        //        profileModelSave()
    //
    //        guard profileModel.settings.iCloudSyncEnabled else { return }
    //    }
    
    func actuallAppVersion() -> String {
        profileModel.onboarding.latestVersion ?? "Latest"
    }
    
    /// Save profile to cas
    private func profileModelSave() async throws {
        try await profileManager.updateProfileModel()
    }
    
    func backButtonTapped() {
        backButton?()
        telemetryAction(action: .profileAction(.closeButtonTapped))
    }
    
    func appearanceButtonTapped() {
        appearanceButton?()
    }
    
    //MARK: - Telemetry action
    private func telemetryAction(action: EventType) {
        telemetryManager.logEvent(action)
    }
}
