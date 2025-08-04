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
    @ObservationIgnored @Injected(\.telemetryManager) private var telemetryManager: TelemetryManagerProtocol
    @ObservationIgnored @Injected(\.onboardingManager) private var onboardingManager: OnboardingManagerProtocol
    
    var profileModel: ProfileData = mockProfileData()
    
    //MARK: UI state
    var showLibrary = false
    var alert: AlertModel?
    var navigationTriger = false
    
    var settingsScreenIsPresented = false
    
    // Animation
    var buttonOffset: CGSize = CGSize(
        width: CGFloat.random(in: 120...160),
        height: CGFloat.random(in: -50...50)
    )
    
    var rotationAngle: Double = 0
    private var orbitRadius: CGFloat = 25
    var orbitRadiusY: CGFloat = 20
    var orbitRadiusX: CGFloat = 35
    var animationTimer: Timer?
    
    var photoPosition = CGSize.zero
    
    @ObservationIgnored
    var pickerSelection: PhotosPickerItem? {
        didSet {
            Task {
                if let imageData = try await pickerSelection?.loadTransferable(type: Data.self) {
                    addPhotoToProfile(image: imageData)
                }
            }
        }
    }
    
    var path = NavigationPath()
    
    var createdDate = Date()
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var today: Date {
        dateManager.currentTime
    }
    
    var todayForFilter: Double {
        calendar.startOfDay(for: Date(timeIntervalSince1970: dateManager.currentTime.timeIntervalSince1970)).timeIntervalSince1970
    }
    
    init() {
        profileModel = casManager.profileModel
        photoPosition = profileModel.photoPosition
        createdDate = Date(timeIntervalSince1970: profileModel.createdProfile)
    }
    
    func onAppear() {
        //        startAnimation()
        
        //telemetry
        telemetryAction(action: .openView(.profile(.open)))
    }
    
    func onDisappear() {
        onboardingManager.showingProfile = nil
        //        endAnimationButton()
        profileModelSave()
        
        //telemetry
        telemetryAction(action: .openView(.profile(.close)))
    }
    
    //MARK: - Navigation to
    func goTo(_ destination: ProfileDestination) {
        navigationTriger.toggle()
        
        switch destination {
        case .articles:
            path.append(destination)
            
            // telemtry
            telemetryAction(action: .profileAction(.productivityArticleView(.openArticle)))
        case .history:
            path.append(destination)
            // telemtry
            telemetryAction(action: .profileAction(.taskHistoryButtonTapped))
            
        case .settings:
            path.append(destination)
        case .appearance:
            path.append(destination)
        }
    }
    
    func settingsButtonTapped() {
        settingsScreenIsPresented = true
    }
    
    //MARK: Task's statistics
    func tasksState(of type: TypeOfTask) -> String {
        
        var tasks = [UITaskModel]()
        var count = 0
        
        switch type {
        case .today:
            tasks = casManager.models.values
                .filter {
                    $0.deleted.contains { $0.deletedFor == todayForFilter } != true &&
                    $0.isScheduledForDate(todayForFilter, calendar: calendar)
                }
            
            count = tasks.count
        case .week:
            var daysFromStartOfWeek = dateManager.startOfWeek(for: today)
            
            (0..<7).forEach { _ in
                tasks = casManager.models.values
                    .filter { $0.isScheduledForDate(daysFromStartOfWeek.timeIntervalSince1970, calendar: calendar) }
                
                count += tasks.count
                daysFromStartOfWeek = calendar.date(byAdding: .day, value: 1, to: daysFromStartOfWeek)!
            }
        case .completed:
            count = casManager.allCompletedTasksCount
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
        
        // telemtry
        telemetryAction(action: .profileAction(.addPhotoButtonTapped))
    }
    
    func getPhotoFromCAS() -> Data? {
        let hash = profileModel.photo
        
        return casManager.getData(hash)
    }
    
    private func addPhotoToProfile(image: Data) {
        profileModel.photo = casManager.saveImage(image) ?? ""
        photoPosition = .zero
        profileModel.photoPosition = photoPosition
        casManager.saveProfileData(profileModel)
    }
    
    func deletePhotoFromProfile() {
        profileModel.photo = ""
        photoPosition = .zero
        profileModel.photoPosition = photoPosition
        casManager.saveProfileData(profileModel)
    }
    
    /// Save profile to cas
    func profileModelSave() {
        casManager.saveProfileData(profileModel)
    }
    
    func savePhotoPosition() {
        profileModel.photoPosition = photoPosition
    }
    
    func closeButtonTapped() {
        onboardingManager.showingProfile = nil
        telemetryAction(action: .profileAction(.closeButtonTapped))
    }
    
    //MARK: - Telemetry action
    private func telemetryAction(action: EventType) {
        telemetryManager.logEvent(action)
    }
    
    //MARK: - Animation
    //    private func startAnimation() {
    //        animationTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
    //            withAnimation(.linear(duration: 3.5)) {
    //                self.buttonOffset = CGSize(
    //                    width: CGFloat.random(in: 120...160),
    //                    height: CGFloat.random(in: -50...50)
    //                )
    //            }
    //        }
    //    }
    //    
    //    private func endAnimationButton() {
    //        animationTimer?.invalidate()
    //        animationTimer = nil
    //        
    //    }
}

enum ProfileDestination: Hashable {
    case articles
    case history
    case settings
    case appearance
}


enum SettingsDestination: Hashable {
    case settings
    case appearance
}
