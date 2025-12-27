//
//  TaskVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/14/25.
//

import AppearanceManager
import DateManager
import Foundation
import SwiftUI
import Models
import PhotosUI
import ProfileManager
import SubscriptionManager
import TaskManager
import TelemetryManager
import SettingsView
import AppearanceView
import HistoryView
import ArticlesView
import PaywallView

@Observable
public final class ProfileVM {
    // MARK: - Managers
    private var profileManager: ProfileManagerProtocol
    private var taskManager: TaskManagerProtocol
    private var appearanceManager: AppearanceManagerProtocol
    private var dateManager: DateManagerProtocol
    private var subscriptionManager: SubscriptionManagerProtocol
    
    private var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    var profileModel: UIProfileModel
    
    var settingsVM: SettingsVM
    var appearanceVM: AppearanceVM
    var paywallVM: PaywallVM?
    
    //MARK: UI state
    // Path for navigation
    var path: [ProfileDestination] = []
    // Profile created date
    var createdDate = Date()
    /// Library showing
    var showLibrary = false
    /// Paywall is presenting
    var showPaywall = true
    var alert: AlertModel?
    var navigationTriger = false
    
    var settingsScreenIsPresented = false
    
    // Animation
    var gearAnimation = false
    var rotationAngle: Double = 0
    var buttonOffset: CGSize = CGSize(
        width: CGFloat.random(in: 120...160),
        height: CGFloat.random(in: -50...50)
    )
    
    // MARK: - Photo
    var photoPosition = CGSize.zero
    var selectedItems = [PhotosPickerItem]() {
        didSet {
            Task {
                await addSelectedImageFromPicker()
            }
        }
    }
    var selectedImage: Image?
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var today: Date {
        dateManager.currentTime
    }
    
    var todayForFilter: Double {
        calendar.startOfDay(for: Date(timeIntervalSince1970: dateManager.currentTime.timeIntervalSince1970)).timeIntervalSince1970
    }
    
    var tasks: [UITaskModel]?
    
    //    var showPaywall: Bool {
    //        subscriptionManager.showPaywall
    //    }
    
    private init(
        profileManager: ProfileManagerProtocol,
        taskManager: TaskManagerProtocol,
        appearanceManager: AppearanceManagerProtocol,
        dateManager: DateManagerProtocol,
        subscriptionManager: SubscriptionManagerProtocol,
        profileModel: UIProfileModel,
        settingsVM: SettingsVM,
        appearanceVM: AppearanceVM
    ) {
        self.profileManager = profileManager
        self.taskManager = taskManager
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.subscriptionManager = subscriptionManager
        self.profileModel = profileModel
        self.settingsVM = settingsVM
        self.appearanceVM = appearanceVM
    }
    
    
    //MARK: - Create profileVM
    
    public static func createProfileVM(profileManager: ProfileManagerProtocol, taskManager: TaskManagerProtocol, appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol) async -> ProfileVM {
        let subscriptionManager = await SubscriptionManager.createSubscriptionManager()
        let settingsVM = SettingsVM.createSettingsVM(dateManager: dateManager, profileManager: profileManager)
        let appearanceVM = AppearanceVM.createAppearanceVM(appearanceManager: appearanceManager)
        let vm = ProfileVM(profileManager: profileManager, taskManager: taskManager, appearanceManager: appearanceManager, dateManager: dateManager, subscriptionManager: subscriptionManager, profileModel: profileManager.profileModel, settingsVM: settingsVM, appearanceVM: appearanceVM)
        vm.tasks = await taskManager.tasks.map { $0.value }
        await vm.setUpProfile()
        vm.onAppear()
        vm.syncNavigation()
        
        return vm
    }
    
    //MARK: - Create PreviewProfileVM
    
    public static func createProfilePreviewVM() -> ProfileVM {
        let dateManager = DateManager.createMockDateManager()
        let profileManager = ProfileManager.createMockProfileManager()
        let subscriptionManager = SubscriptionManager.createMockSubscriptionManager()
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let taskManager = TaskManager.createMockTaskManager()
        
        let settingsVM = SettingsVM.createSettingsVM(dateManager: dateManager, profileManager: profileManager)
        let appearanceVM = AppearanceVM.createAppearanceVM(appearanceManager: appearanceManager)
        let vm = ProfileVM(profileManager: profileManager, taskManager: taskManager, appearanceManager: appearanceManager, dateManager: dateManager, subscriptionManager: subscriptionManager, profileModel: profileManager.profileModel, settingsVM: settingsVM, appearanceVM: appearanceVM)
        vm.onAppear()
        vm.tasks = []
        vm.syncNavigation()
//        vm.setUpProfile()
        
        return vm
    }
    
    func syncNavigation() {
        settingsVM.appearanceButton = { [weak self] in
            guard let self else { return }
            
            self.path.append(.appearance(appearanceVM))
        }
        
        settingsVM.backButton = { [weak self] in
            guard let self else { return }
            
            self.path.removeLast()
        }
        
        appearanceVM.backButton = { [weak self] in
            guard let self else { return }
            
            self.path.removeLast()
        }
    }
    
    func setUpProfile() async {
                if let data = try? await getPhotoFromCAS() {
                    if let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                    }
                }
        photoPosition = profileModel.photoPosition
        createdDate = Date(timeIntervalSince1970: profileModel.createdProfile)
    }
    
    func isnotActiveSubscription() -> Bool {
        true
        //        !subscriptionManager.subscribed
    }
    
    //MARK: - Subscription Button tapped
    func subscriptionButtonTapped() async {
       await createPaywallVM()
    }
    
    //MARK: - Create PaywallVM
    
    private func createPaywallVM() async {
        paywallVM = await PaywallVM.createPaywallVM(subscriptionManager: subscriptionManager)
        showPaywall = true
        
        paywallVM?.closePaywall = { [weak self] in
            guard let self else { return }
            
            paywallVM = nil
            showPaywall = false
        }
    }
    
    func onAppear() {
        gearAnimation.toggle()
        //        startAnimation()
        
        //telemetry
        telemetryAction(action: .openView(.profile(.open)))
    }
    
    func onDisappear() {
        //        endAnimationButton()
        //        subscriptionManager.showPaywall = false
        
        //telemetry
        telemetryAction(action: .openView(.profile(.close)))
    }
    
    //MARK: - Navigation to settings
    
    func goToSettingsButtonTapped() {
        path.append(.settings(settingsVM))
    }
    
    func settingsButtonTapped() {
        settingsScreenIsPresented = true
    }
    
    //MARK: - Navigation to articles
    
    func articlesButtonTapped() {
        path.append(.articles)
    }
    
    //MARK: - Task History Button Tapped
    
    func taskHistoryButtonTapped() {
        path.append(.history)
    }
    
    //MARK: Task's statistics
    func tasksState(of type: TypeOfTask) -> String {
        
        var tasks = [UITaskModel]()
        var count = 0
        
        switch type {
        case .today:
            tasks = tasks
                .filter {
                    $0.deleteRecords.contains { $0.deletedFor == todayForFilter } != true &&
                    $0.isScheduledForDate(todayForFilter, calendar: calendar)
                }
            
            count = tasks.count
        case .week:
            var daysFromStartOfWeek = dateManager.startOfWeek(for: today)
            
            (0..<7).forEach { _ in
                tasks = tasks
                    .filter { $0.isScheduledForDate(daysFromStartOfWeek.timeIntervalSince1970, calendar: calendar) }
                
                count += tasks.count
                daysFromStartOfWeek = calendar.date(byAdding: .day, value: 1, to: daysFromStartOfWeek)!
            }
        case .completed:
            count = tasks.count
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
    
    //MARK: - Avatar
    func addPhotoButtonTapped() {
        showLibrary = true
        telemetryAction(action: .profileAction(.addPhotoButtonTapped))
    }
    
    func addSelectedImageFromPicker() async {
        if let image = try? await selectedItems.first?.loadTransferable(type: Data.self) {
            if let uiImage = UIImage(data: image) {
                selectedImage = Image(uiImage: uiImage)
                await addPhotoToProfile(image: image)
            }
        }
    }
    
    func getPhotoFromCAS() async throws -> Data? {
        guard await profileHasPhoto() else {
            return nil
        }
        
        return try? await profileManager.getPhoto()
    }
    
    func profileHasPhoto() async -> Bool {
        guard profileModel.photo != "" else {
            return false
        }
        return true
        //        casManager.getData(profileModel.photo) != nil
    }
    
    private func addPhotoToProfile(image: Data) async {
        try? await profileManager.updatePhoto(image)
        photoPosition = .zero
        profileModel.photoPosition = photoPosition
        //        casManager.saveProfileData(profileModel)
        selectedItems.removeAll()
    }
    
    func deletePhotoFromProfile() async {
        try? await profileManager.deletePhoto()
        selectedImage = nil
        photoPosition = .zero
    }
    
    /// Save profile to cas
    func profileModelSave() async {
        try? await profileManager.updateProfileModel()
    }
    
    func savePhotoPosition() {
        profileModel.photoPosition = photoPosition
    }
    
    func closeButtonTapped() {
        telemetryAction(action: .profileAction(.closeButtonTapped))
    }
    
    //MARK: - Telemetry action
    private func telemetryAction(action: EventType) {
        telemetryManager.logEvent(action)
    }
}

enum ProfileDestination: Hashable {
    case articles
    case history
    case settings(SettingsVM)
    case appearance(AppearanceVM)
}

enum SettingsDestination: Hashable {
    case settings
    case appearance
}

extension ProfileDestination {
    @ViewBuilder
    func destination() -> some View {
        switch self {
        case .articles:
            ArticlesView()
        case .history:
            HistoryView()
        case .settings(let settingsVM):
            SettingsView(vm: settingsVM)
        case .appearance(let appearanceVM):
            AppearanceView(vm: appearanceVM)
        }
    }
}
