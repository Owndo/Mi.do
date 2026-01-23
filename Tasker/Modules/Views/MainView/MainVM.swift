//
//  MainVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//


import AppearanceManager
import CASManager
import CalendarView
import CustomErrors
import DateManager
import Foundation
import Models
import NotesView
import NotificationManager
import PaywallView
import PermissionManager
import PlayerManager
import ProfileManager
import RecorderManager
import SubscriptionManager
import StorageManager
import SwiftUI
import TaskManager
import TaskView
import TelemetryManager
import ListView
import ProfileView

@Observable
public final class MainVM: HashableNavigation {
    //MARK: - Depency
    public let appearanceManager: AppearanceManagerProtocol
    private let dateManager: DateManagerProtocol
    private let permissionManager: PermissionProtocol = PermissionManager.createPermissionManager()
    private let playerManager: PlayerManagerProtocol
    private let profileManager: ProfileManagerProtocol
    private let recorderManager: RecorderManagerProtocol
    private let storageManager: StorageManagerProtocol
    private let subscriptionManager: SubscriptionManagerProtocol
    
    private let taskManager: TaskManagerProtocol
    private let telemetryManager: TelemetryManagerProtocol
    
    
    //MARK: - ViewModels
    
    private var calendarVM: CalendarVM
    private var profileVM: ProfileVM?
    private var taskViewVM: TaskVM?
    
    var weekVM: WeekVM
    var listVM: ListVM
    
    var notesVM: NotesVM
    
    
    //    private let playerManager: PlayerManagerProtocol
    
    //    var onboardingManager: OnboardingManagerProtocol
    
    //MARK: - Model
    
    var mainModel: UIProfileModel?
    
    public var profileModel: UIProfileModel {
        didSet {
            print("Changed")
        }
    }
    
    //    let listVM = ListVM()
    //    var taskVM: TaskVM?
    
    //    var sheetDestination: SheetDestination? {
    //        didSet {
    //            if sheetDestination == nil {
    //                presentationPosition = .fraction(0.93)
    //            } else {
    //                presentationPosition = .fraction(1.0)
    //            }
    //        }
    //    }
    
    //MARK: - Async Stream
    
    private var selectedTaskTask: Task<Void, Never>?
    
    //MARK: - UI States
    
    var mainViewIsOpen = true
    var profileViewIsOpen = false
    var isRecording = false
    var showDetailsScreen = false
    var alert: AlertModel?
    var disabledButton = false
    var askReview = false
    
    var backgroundAnimation = false
    
    var mainViewPaywall = false
    
    var recordingState: RecordingState = .idle
    
    enum RecordingState {
        case idle
        case recording
        case stopping
    }
    
    //MARK: - Navigation
    
    var path: [MainViewNavigation] = [] {
        didSet {
            if path.isEmpty {
                mainViewSheetIsPresented = true
            } else {
                mainViewSheetIsPresented = false
            }
        }
    }
    
    //MARK: - Sheet navigation
    
    var mainViewSheetIsPresented = true
    
    var sheetNavigation: SheetNavigation? {
        didSet {
            if sheetNavigation != nil {
                presentationPosition = PresentationMode.full.detent
            } else {
                Task {
                    try await Task.sleep(for: .seconds(0.05))
                    presentationPosition = PresentationMode.base.detent
                }
            }
        }
    }
    
    //MARK: - Sheet postition
    
    var presentationPosition: PresentationDetent = PresentationMode.base.detent {
        didSet {
            backgroundAnimation.toggle()
        }
    }
    
    //MARK: Copmputed properties
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var currentlyTime: Double {
        recorderManager.currentlyTime
    }
    
    var selectedDate: Date {
        dateManager.selectedDate
    }
    
    var progress: Double {
        recorderManager.progress
    }
    
    var decibelLvl: Float {
        recorderManager.decibelLevel
    }
    
    //    public var profileUpdateTrigger: Bool {
    //        casManager.profileUpdateTriger
    //    }
    
    //MARK: - Init
    
    private init(
        appearanceManager: AppearanceManagerProtocol,
        dateManager: DateManagerProtocol,
        playerManager: PlayerManagerProtocol,
        profileManager: ProfileManagerProtocol,
        recorderManager: RecorderManagerProtocol,
        storageManager: StorageManagerProtocol,
        subscriptionManager: SubscriptionManagerProtocol,
        taskManager: TaskManagerProtocol,
        telemetryManager: TelemetryManagerProtocol,
        
        profileModel: UIProfileModel,
        
        calendarVM: CalendarVM,
        listVM: ListVM,
        notesVM: NotesVM,
        weekVM: WeekVM,
    ) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.playerManager = playerManager
        self.profileManager = profileManager
        self.recorderManager = recorderManager
        self.storageManager = storageManager
        self.subscriptionManager = subscriptionManager
        self.taskManager = taskManager
        self.telemetryManager = telemetryManager
        
        self.profileModel = profileModel
        
        self.calendarVM = calendarVM
        self.listVM = listVM
        self.notesVM = notesVM
        self.weekVM = weekVM
    }
    
    
    //MARK: - Create VM
    
    public static func createVM() async -> MainVM {
        // Managers
        
        let casManager = await CASManager.createCASManager()
        let profileManager = await ProfileManager.createManager(casManager: casManager)
        let storageManager = StorageManager.createStorageManager(casManager: casManager)
        
        let appearanceManager = AppearanceManager.createAppearanceManager(profileManager: profileManager)
        let dateManager = await DateManager.createDateManager(profileManager: profileManager)
        
        let notificationManager = await NotificationManager.createNotificationManager(dateManager: dateManager, profileManager: profileManager, storageManager: storageManager)
        let playerManager = PlayerManager.createPlayerManager(storageManager: storageManager)
        
        let taskManager = await TaskManager.createTaskManager(casManager: casManager, dateManager: dateManager, notificationManager: notificationManager)
        let recorderManager = RecorderManager.createRecorderManager(dateManager: dateManager)
        
        let subscriptionManager = await SubscriptionManager.createSubscriptionManager()
        let telemetryManager = TelemetryManager.createTelemetryManager()
        
        // Models
        let profileModel = profileManager.profileModel
        
        // ViewModels
        
        let dayVMStore = await DayVMStore.createStore(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
        let calendarVM = await CalendarVM.createMonthVM(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager, dayVMStore: dayVMStore)
        let weekVM = await WeekVM.createVM(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager, dayVMStore: dayVMStore)
        let listVM = await ListVM.createListVM(appearanceManager: appearanceManager, dateManager: dateManager, notificationManager: notificationManager, playerManager: playerManager, profileManager: profileManager, taskManager: taskManager)
        let notesVM = NotesVM.createVM(appearanceManager: appearanceManager, profileManager: profileManager)
        
        let vm = MainVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            playerManager: playerManager,
            profileManager: profileManager,
            recorderManager: recorderManager,
            storageManager: storageManager,
            subscriptionManager: subscriptionManager,
            taskManager: taskManager,
            telemetryManager: telemetryManager,
            profileModel: profileModel,
            calendarVM: calendarVM,
            listVM: listVM,
            notesVM: notesVM,
            weekVM: weekVM
        )
        
        await vm.selectedTaskSheetSync()
        vm.syncNavigation()
        
        return vm
    }
    
    //MARK: - Create PreviewVM
    
    public static func createPreviewVM() -> MainVM {
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let dateManager = DateManager.createPreviewManager()
        let playerManager = PlayerManager.createMockPlayerManager()
        let profileManager = ProfileManager.createMockManager()
        let recorderManager = RecorderManager.createRecorderManager(dateManager: dateManager)
        let storageManager = StorageManager.createMockStorageManager()
        let subscriptionManager = SubscriptionManager.createMockSubscriptionManager()
        let taskManager = TaskManager.createMockTaskManager()
        let telemetryManager = TelemetryManager.createTelemetryManager(mock: true)
        
        let profileModel = profileManager.profileModel
        
        let calendarVM = CalendarVM.createPreviewVM()
        let listVM = ListVM.creteMockListVM()
        let notesVM = NotesVM.createPreviewVM()
        let weekVM = WeekVM.createPreviewVM()
        
        let vm = MainVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            playerManager: playerManager,
            profileManager: profileManager,
            recorderManager: recorderManager,
            storageManager: storageManager,
            subscriptionManager: subscriptionManager,
            taskManager: taskManager,
            telemetryManager: telemetryManager,
            profileModel: profileModel,
            calendarVM: calendarVM,
            listVM: listVM,
            notesVM: notesVM,
            weekVM: weekVM
        )
        
        vm.syncNavigation()
        
        return vm
    }
    
    //MARK: - Sync navigation
    
    private func syncNavigation() {
        calendarVM.backToMainView = { [weak self] in
            guard let self else { return }
            path.removeLast()
        }
    }
    
    //MARK: - Selected Task Sheet
    
    private func selectedTaskSheetSync() async {
        selectedTaskTask = Task { [weak self, stream = listVM.selectedTaskStream] in
            guard let stream else { return }
            for await i in stream {
                guard let self else { break }
                
                await createTaskVM(i)
            }
        }
    }
    
    //MARK: - Profile Sheet
    
    private func profileSheetSync() async {
        profileVM?.closeButton = { [weak self] in
            guard let self else { return }
            self.sheetNavigation = nil
        }
    }
    
    //MARK: - Update notification
    //    public func updateNotifications() async {
    //        guard onboardingManager.onboardingComplete == true else {
    //            return
    //        }
    //
    //        try? await Task.sleep(for: .seconds(0.2))
    //
    //        //        await notificationManager.createNotification()
    //    }
    
    /// Only once time for ask notification reqest
    //    @objc private func handleFirstTimeOpenDone() {
    //        Task {
    //            await updateNotifications()
    //        }
    //
    //        NotificationCenter.default.removeObserver(
    //            self,
    //            name: NSNotification.Name("firstTimeOpenHasBeenDone"),
    //            object: nil
    //        )
    //    }
    
    public func mainScreenOpened() {
        telemetryManager.logEvent(.openView(.home(.open)))
    }
    
    // MARK: - Telemetry action
    func telemetryAction(_ event: EventType) {
        telemetryManager.logEvent(event)
    }
    
    //MARK: - Profile actions
    func profileModelSave() {
        //        casManager.saveProfileData(profileModel)
    }
    
    private func downloadProfileModelFromCas() {
        //        profileModel = casManager.profileModel
    }
    
    //MARK: - Profile Button
    
    func profileViewButtonTapped() async {
#if targetEnvironment(simulator)
        profileVM = ProfileVM.createProfilePreviewVM()
        
#else
        profileVM = await ProfileVM.createProfileVM(profileManager: profileManager, taskManager: taskManager, appearanceManager: appearanceManager, dateManager: dateManager)
        
#endif
        
        guard let profileVM else { return }
        
        await profileSheetSync()
        
        sheetNavigation = .profile(profileVM)
        backgroundAnimation.toggle()
        
        telemetryAction(.mainViewAction(.profileButtonTapped))
    }
    
    //MARK: - Recording
    func createTaskButtonHolding() async {
        guard isRecording else {
            return
        }
        
        await stopRecord(isAutoStop: true)
    }
    
    func startAfterChek() async throws {
        mainViewPaywall = true
        
        //        guard await subscriptionManager.hasSubscription() else {
        //            while showPaywall {
        //                try await Task.sleep(for: .seconds(0.1))
        //            }
        //
        //            mainViewPaywall = false
        //            return
        //        }
        
        recordingState = .recording
        //TODO: - Check if player manager will be stopped by default
        //        playerManager.stopToPlay()
        
        // telemetry
        telemetryAction(.mainViewAction(.recordTaskButtonTapped(.tryRecording)))
        
        do {
            changeDisabledButton()
            try permissionManager.peremissionSessionForRecording()
            try await permissionManager.permissionForSpeechRecognition()
            
            await startRecord()
            
            changeDisabledButton()
        } catch let error as MicrophonePermission {
            mainViewPaywall = true
            switch error {
            case .silentError: return
            case .microphoneIsNotAvailable:
                alert = AlertModel(alert: error.showingAlert(action: changeDisabledButton))
            case .speechRecognitionIsNotAvailable:
                alert = AlertModel(alert: error.showingAlert(action: changeDisabledButton))
            }
        } catch let error as ErrorRecorder {
            switch error {
            case .cannotInterruptOthers, .cannotStartRecording, .insufficientPriority, .isBusy, .siriIsRecordign, .timeIsLimited:
                alert = AlertModel(alert: error.showingAlert(action: changeDisabledButton))
            case .none:
                return
            }
        }
    }
    
    //MARK: - Stop after check
    @MainActor
    func stopAfterCheck(_ newValue: Double?) async {
        guard let value = newValue, value >= 15.0 else { return }
        await stopRecord()
        // telemetry
        telemetryAction(.mainViewAction(.recordTaskButtonTapped(.stopRecordingAfterTimeout)))
    }
    
    func startRecord() async {
        isRecording = true
        await recorderManager.startRecording()
        // telemetry
        telemetryAction(.mainViewAction(.recordTaskButtonTapped(.startRecording)))
    }
    
    func stopRecord(isAutoStop: Bool = false) async {
        guard recordingState == .recording else {
            return
        }
        
        recordingState = .stopping
        isRecording = false
        
        var hashOfAudio: String?
        
        if let audioURLString = recorderManager.stopRecording() {
            if let data = try? Data(contentsOf: audioURLString) {
                do {
                    hashOfAudio = try await taskManager.storeAudio(data)
                } catch {
                    print("Couldn't create audio hash - MainVM.363")
                }
            }
        }
        
        await createTask(with: hashOfAudio)
        recorderManager.clearFileFromDirectory()
        
        // telemetry
        telemetryAction(.mainViewAction(.recordTaskButtonTapped(.stopRecording)))
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        recordingState = .idle
    }
    
    //MARK: - Create task
    
    func createTask(with audioHash: String? = nil) async {
        let model = UITaskModel(
            .initial(
                TaskModel(
                    title: defaultTitle(),
                    speechDescription: speechDescription(),
                    audio: audioHash,
                    notificationDate: defaultNotificationTime(),
                    voiceMode: audioHash != nil ? true : nil,
                    taskColor: appearanceManager.profileModel.settings.defaultTaskColor == .baseColor ? nil : appearanceManager.profileModel.settings.defaultTaskColor
                )
            )
        )
        
        await createTaskVM(model, newTask: true)
    }
    
    //MARK: - Create Task VM
    
    private func createTaskVM(_ task: UITaskModel, newTask: Bool = false) async {
        taskViewVM = await TaskVM.createTaskVM(
            appearanceManager: appearanceManager,
            taskManager: taskManager,
            playerManager: playerManager,
            storageManager: storageManager,
            profileManager: profileManager,
            dateManager: dateManager,
            recorderManager: recorderManager,
            task: task
        )
        
        guard let taskViewVM else { return }
        
        taskViewVM.titleFocused = newTask
        sheetNavigation = .taskDetails(taskViewVM)
    }
    
    //MARK: - Recognize data
    func defaultTitle() -> String? {
        guard recorderManager.recognizedText == "" else {
            return recorderManager.recognizedText
        }
        return nil
    }
    
    func speechDescription() -> String? {
        recorderManager.wholeDescription
    }
    
    func defaultNotificationTime() -> Double {
        if let recognizedDate = recorderManager.dateTimeFromtext {
            return recognizedDate.timeIntervalSince1970
        } else {
            return dateManager.getDefaultNotificationTime().timeIntervalSince1970
        }
    }
    
    func handleButtonTap() async {
        if recordingState == .recording {
            await stopRecord()
        } else {
            await createTask()
            
            // telemetry
            telemetryAction(.mainViewAction(.addTaskButtonTapped))
        }
    }
    
    //MARK: - Calendar Button
    
    func calendarButtonTapped() async {
        path.append(.calendar(calendarVM))
        // telemetry
        telemetryAction(.mainViewAction(.calendarButtonTapped))
    }
    
    
    //MARK: - Find tasks after notification
    private func extractBaseId(from fullId: String) -> String {
        return fullId.components(separatedBy: ".").first ?? fullId
    }
    
    public func selectedTask(by notification: Notification? = nil, taskId: String? = nil) {
        guard taskId == nil else {
            let baseSearchId = extractBaseId(from: taskId!)
            //            let task = casManager.models.values.first { task in
            //                extractBaseId(from: task.id) == baseSearchId
            //            }
            
            //            if let task {
            //                mainModel = task
            //            }
            
            return
        }
        
        if let taskId = notification?.userInfo?["taskId"] as? String {
            let baseSearchId = extractBaseId(from: taskId)
            //            let task = casManager.models.values.first { task in
            //                extractBaseId(from: task.id) == baseSearchId
            //            }
            //            if let task {
            //                mainModel = task
            //            }
        }
    }
    
    private func changeDisabledButton() {
        disabledButton.toggle()
    }
    
    //MARK: - Onboarding
    private func onboardingStart() async {
        
        //        while onboardingManager.sayHello {
        //            try? await Task.sleep(for: .seconds(0.1))
        //        }
        //
        //        // If first time - return
        //        guard profileModel.onboarding.firstTimeOpen == false else {
        //            return
        //        }
        
        try? await Task.sleep(for: .seconds(0.8))
        
        //        guard casManager.completedTaskCount() >= 23 && profileModel.onboarding.requestedReview == false else {
        //            return
        //        }
        
        askReview = true
        //        profileModel.onboarding.requestedReview = true
        profileModelSave()
    }
    
    //MARK: Function before closeApp
    public func closeApp() async {
        //        let backgroundManager = BackgroundManager()
        //        casManager.updateCASAfterWork()
        //        await updateNotifications()
        //        await backgroundManager.scheduleAppRefreshTask()
    }
    
    //MARK: - Background update
    public func backgroundUpdate() async {
        //        let backgroundManager = BackgroundManager()
        
        //        await backgroundManager.backgroundUpdate()
    }
}

//MARK: - Helpers not a VM
enum PresentationMode: CGFloat, CaseIterable {
    case full = 1.00
    case base = 0.95
    case bottom = 0.20
    
    var detent: PresentationDetent {
        .fraction(rawValue)
    }
    
    static let detents = Set(PresentationMode.allCases.map { $0.detent })
}

//MARK: - Navigation

enum MainViewNavigation: Hashable {
    case calendar(CalendarVM)
}

extension MainViewNavigation {
    @ViewBuilder
    func destination() -> some View {
        switch self {
        case .calendar(let monthVM):
            CalendarView(vm: monthVM)
        }
    }
}

//MARK: - Sheet Navigation

enum SheetNavigation: Identifiable, Hashable, Equatable {
    case taskDetails(TaskVM)
    case profile(ProfileVM)
    
    var id: Self { self }
}

extension SheetNavigation {
    @ViewBuilder
    func destination() -> some View {
        switch self {
        case .taskDetails(let taskVM):
            TaskView(taskVM: taskVM)
        case .profile(let profileVM):
            ProfileView(vm: profileVM)
        }
    }
}
