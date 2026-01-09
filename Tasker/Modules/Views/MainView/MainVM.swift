//
//  MainVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//


import AppearanceManager
import CalendarView
import CustomErrors
import DateManager
import Foundation
import Models
import NotesView
import PaywallView
import PermissionManager
import ProfileManager
import RecorderManager
import SubscriptionManager
import SwiftUI
import TaskManager
import TaskView
import TelemetryManager

@Observable
public final class MainVM {
    //MARK: - Depencies
    private let profileManager: ProfileManagerProtocol
    
    private let taskManager: TaskManagerProtocol
    
    private let dateManager: DateManagerProtocol
    
    private let permissionManager: PermissionProtocol = PermissionManager.createPermissionManager()
    
    private let recorderManager: RecorderManagerProtocol
    
    private let subscriptionManager: SubscriptionManagerProtocol
    
    private let telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    //MARK: - ViewModels
    
    private var calendarVM: CalendarVM
    
    var notesVM: NotesVM
    
    //    private let playerManager: PlayerManagerProtocol
    
    //    var onboardingManager: OnboardingManagerProtocol
    
    //MARK: - Model
    var mainModel: UIProfileModel?
    var profileModel: UIProfileModel
    
    //    let listVM = ListVM()
    //    var taskVM: TaskVM?
    
    var sheetDestination: SheetDestination? {
        didSet {
            if sheetDestination == nil {
                presentationPosition = .fraction(0.93)
            } else {
                presentationPosition = .fraction(1.0)
            }
        }
    }
    
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
    
    //    var showPaywall: Bool {
    //        mainViewPaywall && subscriptionManager.showPaywall
    //    }
    
    var presentationPosition: PresentationDetent = PresentationMode.base.detent {
        didSet {
            backgroundAnimation.toggle()
            if presentationPosition == .fraction(0.93) {
                if path.count > 0 {
                    path.removeLast()
                }
            }
            
            if presentationPosition == .fraction(0.20) {
                // telemetry
                telemetryAction(.mainViewAction(.showNotesButtonTapped))
            }
        }
    }
    
    enum SheetDestination: Hashable, Identifiable {
        case profile
        case details(TaskVM)
        
        var id: Self { self }
        
        static func == (lhs: SheetDestination, rhs: SheetDestination) -> Bool {
            switch (lhs, rhs) {
            case (.details, .details): return true
            case (.profile, .profile): return true
            default: return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .details:
                hasher.combine(0)
            case .profile:
                hasher.combine(1)
            }
        }
    }
    
    var recordingState: RecordingState = .idle
    
    enum RecordingState {
        case idle
        case recording
        case stopping
    }
    
    var path: [MainViewNavigation] = []
    
    enum Destination: CaseIterable, Hashable {
        case main
        case calendar
    }
    
    //    private var isProcessingStop = false
    
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
        profileManager: ProfileManagerProtocol,
        taskManager: TaskManagerProtocol,
        dateManager: DateManagerProtocol,
        recorderManager: RecorderManagerProtocol,
        subscriptionManager: SubscriptionManagerProtocol,
        profileModel: UIProfileModel,
        calendarVM: CalendarVM,
        notesVM: NotesVM
    ) {
        self.profileManager = profileManager
        self.taskManager = taskManager
        self.dateManager = dateManager
        self.recorderManager = recorderManager
        self.subscriptionManager = subscriptionManager
        self.profileModel = profileModel
        self.calendarVM = calendarVM
        self.notesVM = notesVM
    }
    
    //MARK: - Create PreviewVM
    
    public static func createPreviewVM() -> MainVM {
        let profileManager = ProfileManager.createMockProfileManager()
//        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let taskManager = TaskManager.createMockTaskManager()
        let dateManager = DateManager.createMockDateManager()
        let recorderManager = RecorderManager.createRecorderManager(dateManager: dateManager)
        let subscriptionManager = SubscriptionManager.createMockSubscriptionManager()
        let profileModel = profileManager.profileModel
        
        let calendarVM = CalendarVM.createPreviewVM()
        let notesVM = NotesVM.createPreviewVM()
        
        let vm = MainVM(
            profileManager: profileManager,
            taskManager: taskManager,
            dateManager: dateManager,
            recorderManager: recorderManager,
            subscriptionManager: subscriptionManager,
            profileModel: profileModel,
            calendarVM: calendarVM,
            notesVM: notesVM
        )
        
        vm.syncNavigation()
        
        return vm
    }
    
    //MARK: - Sync navigation
    
    func syncNavigation() {
        calendarVM.backToMainView = { [weak self] in
            guard let self else { return }
            path.removeLast()
        }
    }
    
    //    public static func createMainVM() async -> Self {
    //        let dependenciesManager = await DependenciesManager.createDependencies()
    //        let mainVM = Self(dependenciesManager: dependenciesManager)
    //
    //        await mainVM.onboardingStart()
    //
    //        return mainVM
    //    }
    
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
    
    func profileViewButtonTapped() {
        
        sheetDestination = .profile
        //        profileViewIsOpen = true
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
        
        createTask(with: hashOfAudio)
        recorderManager.clearFileFromDirectory()
        
        // telemetry
        telemetryAction(.mainViewAction(.recordTaskButtonTapped(.stopRecording)))
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        recordingState = .idle
    }
    
    //MARK: - Create task
    func createTask(with audioHash: String? = nil) {
        let model = UITaskModel(
            .initial(
                TaskModel(
                    title: defaultTitle(),
                    speechDescription: speechDescription(),
                    audio: audioHash,
                    notificationDate: defaultNotificationTime(),
                    voiceMode: audioHash != nil ? true : nil,
                    taskColor: profileModel.settings.defaultTaskColor
                )
            )
        )
        
//        taskDetailsButtonTapped(model: model)
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
            createTask()
            
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
    case base = 0.93
    case bottom = 0.20
    
    var detent: PresentationDetent {
        .fraction(rawValue)
    }
    
    static let detents = Set(PresentationMode.allCases.map { $0.detent })
}

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
