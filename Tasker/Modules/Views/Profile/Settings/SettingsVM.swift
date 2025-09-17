//
//  SettingsVM.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/28/25.
//

import Foundation
import Managers
import Models
import SwiftUI

@Observable
final class SettingsVM {
    @ObservationIgnored
    @Injected(\.casManager) var casManager: CASManagerProtocol
    @ObservationIgnored
    @Injected(\.dateManager) var dateManager: DateManagerProtocol
    @ObservationIgnored
    @Injected(\.telemetryManager) private var telemetryManager: TelemetryManagerProtocol
    @ObservationIgnored
    @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerProtocol
    
    
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
    
    var syncWithIcloud = false {
        didSet {
            Task {
                await changeToogleOfSync()
            }
        }
    }
    
    var calendar: Calendar = .current
    var profileModel: ProfileData = mockProfileData()
    var createdDate = Date()
    var firstWeekday: LocalizedStringKey = "Sunday"
    
    init() {
        profileModel = casManager.profileModel
        firstDayOfWeek = profileModel.settings.firstDayOfWeek == 1 ? .sunday : .monday
        
        createdDate = Date(timeIntervalSince1970: profileModel.createdProfile)
        syncWithIcloud = profileModel.settings.iCloudSyncEnabled
        calendar = dateManager.calendar
    }
    
    func goTo(path: inout NavigationPath, destination: ProfileDestination) {
        path.append(destination)
    }
    
    func changeFirstDayOfWeek(_ firstDayOfWeek: Int) {
        dateManager.calendar.firstWeekday = firstDayOfWeek
        profileModel.settings.firstDayOfWeek = firstDayOfWeek
        profileModelSave()
    }
    
    func changeToogleOfSync() async {
        profileModel.settings.iCloudSyncEnabled = syncWithIcloud
        profileModelSave()
        
        guard profileModel.settings.iCloudSyncEnabled else { return }
    }
    
    func actuallAppVersion() -> String {
        profileModel.onboarding.latestVersion ?? "Latest Version"
    }
    
    /// Save profile to cas
    private func profileModelSave() {
        casManager.saveProfileData(profileModel)
    }
    
    func closeButtonTapped(_ path: inout NavigationPath) {
        path.removeLast()
        telemetryAction(action: .profileAction(.closeButtonTapped))
    }
    
    //MARK: - Telemetry action
    private func telemetryAction(action: EventType) {
        telemetryManager.logEvent(action)
    }
}
