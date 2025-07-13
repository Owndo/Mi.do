//
//  TaskVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/14/25.
//

import Foundation
import SwiftUI
import Managers
import Models
import PhotosUI

@Observable
final class ProfileVM {
    // MARK: - Managers
    @ObservationIgnored @Injected(\.casManager) var casManager: CASManagerProtocol
    @ObservationIgnored @Injected(\.playerManager) private var playerManager: PlayerManagerProtocol
    @ObservationIgnored @Injected(\.recorderManager) private var recorderManager: RecorderManagerProtocol
    @ObservationIgnored @Injected(\.dateManager) private var dateManager: DateManagerProtocol
    @ObservationIgnored @Injected(\.notificationManager) private var notificationManager: NotificationManagerProtocol
    @ObservationIgnored @Injected(\.taskManager) private var taskManager: TaskManagerProtocol
    @ObservationIgnored @Injected(\.storageManager) private var storageManager: StorageManagerProtocol
    @ObservationIgnored @Injected(\.appearanceManager) private var appearanceManager: AppearanceManagerProtocol
    @ObservationIgnored @Injected(\.permissionManager) private var permissionManager: PermissionProtocol
    
    var profileModel: ProfileData = mockProfileData()
    
    var showLibrary = false
    var alert: AlertModel?
    
    var photoPosition = CGSize.zero
    
    @ObservationIgnored
    var pickerSelection: PhotosPickerItem? {
        didSet {
            Task {
                if let imageData = try await pickerSelection?.loadTransferable(type: Data.self) {
                    addPhotoToProfile(image: imageData)
                    photoPosition = .zero
                }
            }
        }
    }
    
    var path = NavigationPath()
    
    enum ProfileDestination: Hashable {
        case articles
        case history
        case appearance
    }
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var today: Date {
        dateManager.currentTime
    }
    
    var firstWeekday: String {
        calendar.firstWeekday == 1 ? "Sunday" : "Monday"
    }
    
    init() {
        profileModel = casManager.profileModel ?? mockProfileData()
        photoPosition = profileModel.value.photoPosition
    }
    
    //MARK: - Navigation to
    func goTo(_ destination: ProfileDestination) {
        switch destination {
        case .articles:
            path.append(destination)
        case .history:
            path.append(destination)
        case .appearance:
            path.append(destination)
        }
    }
    
    //MARK: Task's statistics
    func tasksState(of type: TypeOfTask) -> String {
        
        var tasks = [TaskModel]()
        var count = 0
        
        switch type {
        case .today:
            tasks = casManager.activeTasks.map { $0.value }
                .filter { $0.isScheduledForDate(today.timeIntervalSince1970, calendar: calendar) }
            
            count = tasks.count
        case .week:
            let weekday = calendar.component(.weekday, from: today)
            let daysFromStartOfWeek = weekday - calendar.firstWeekday
            let startOfWeek = calendar.date(byAdding: .day, value: -daysFromStartOfWeek, to: today)!
            
            for offset in 0..<7 {
                let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
                let dayTasks = casManager.activeTasks.map { $0.value }
                    .filter {
                        $0.isScheduledForDate(date.timeIntervalSince1970, calendar: calendar)
                    }
                tasks.append(contentsOf: dayTasks)
            }
            
            count = tasks.count
        case .completed:
            count = casManager.allCompletedTasks.map { $0.value.done.map { $0 }}.count
        }
        
        if count >= 1000 {
            let formatted = String(format: "%.1fK", Double(count) / 1000.0)
            return formatted
        } else {
            return "\(count)"
        }
    }
    
    enum TypeOfTask {
        case today
        case week
        case completed
    }
    
    func editAvatarButtonTapped() async {
        
        let premissionStatus = await permissionManager.permissionForGallery()
        
        guard premissionStatus else {
            if let attentionAlert = permissionManager.alert {
                alert = AlertModel(alert: attentionAlert)
            }
            return
        }
        
        showLibrary = true
    }
    
    func getPhotoFromCAS() -> Data? {
        let hash = profileModel.value.photo
        
        return casManager.getData(hash)
    }
    
    private func addPhotoToProfile(image: Data) {
        profileModel.value.photo = casManager.saveImage(image) ?? ""
        casManager.saveProfileData(profileModel)
    }
    
    /// Save profile to cas
    func profileModelSave() {
        casManager.saveProfileData(profileModel)
    }
    
    func savePhotoPosition() {
        profileModel.value.photoPosition = photoPosition
    }
    
    
    func changeFirstDayOfWeek(_ firstDayOfWeek: Int) {
        dateManager.calendar.firstWeekday = firstDayOfWeek
    }
    
    func colorScheme() -> String {
        appearanceManager.colorScheme()
    }
    
    func backgroundColor() -> Color {
        appearanceManager.backgroundColor()
    }
    
    func accentColor() -> Color {
        appearanceManager.accentColor()
    }
}
