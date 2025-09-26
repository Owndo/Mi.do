//
//  MainVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Foundation
import SwiftUI
import Managers
import Models
import TaskView
import ListView

@MainActor
@Observable
public final class MainVM {
    //MARK: - Depencies
    @ObservationIgnored
    @Injected(\.casManager) private var casManager: CASManagerProtocol
    @ObservationIgnored
    @Injected(\.permissionManager) private var recordPermission: PermissionProtocol
    @ObservationIgnored
    @Injected(\.recorderManager) private var recordManager: RecorderManagerProtocol
    @ObservationIgnored
    @Injected(\.playerManager) private var playerManager: PlayerManagerProtocol
    @ObservationIgnored
    @Injected(\.dateManager) private var dateManager: DateManagerProtocol
    @ObservationIgnored
    @Injected(\.notificationManager) var notificationManager: NotificationManagerProtocol
    @ObservationIgnored
    @Injected(\.taskManager) private var taskManager: TaskManagerProtocol
    @ObservationIgnored
    @Injected(\.appearanceManager) private var appearanceManager: AppearanceManagerProtocol
    @ObservationIgnored
    @Injected(\.telemetryManager) private var telemetryManager: TelemetryManagerProtocol
    @ObservationIgnored
    @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerProtocol
    @ObservationIgnored
    @Injected(\.onboardingManager) var onboardingManager: OnboardingManagerProtocol
    
    //MARK: - Model
    var mainModel: MainModel?
    var profileModel: ProfileData = mockProfileData()
    
    let listVM = ListVM()
    var taskVM: TaskVM?
    
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
    
    /// First time ever opened
    var sayHello = false
    
    var mainViewPaywall = false
    
    var showPaywall: Bool {
        mainViewPaywall && subscriptionManager.showPaywall
    }
    
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
    
    var path = NavigationPath()
    
    enum Destination: CaseIterable, Hashable {
        case main
        case calendar
    }
    
    private var isProcessingStop = false
    
    //MARK: Copmputed properties
    
    var calendar: Calendar {
        dateManager.calendar
    }
    var currentlyTime: Double {
        recordManager.currentlyTime
    }
    
    var selectedDate: Date {
        dateManager.selectedDate
    }
    
    var progress: Double {
        recordManager.progress
    }
    
    var decibelLvl: Float {
        recordManager.decibelLevel
    }
    
    var showTip: Bool {
        taskManager.activeTasks.isEmpty && taskManager.completedTasks.isEmpty
    }
    
    public var profileUpdateTrigger: Bool {
        casManager.profileUpdateTriger
    }
    
    //MARK: - Init
    public init() {
        downloadProfileModelFromCas()
        
        Task {
            await onboardingStart()
            await updateNotifications()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFirstTimeOpenDone),
            name: NSNotification.Name("firstTimeOpenHasBeenDone"),
            object: nil
        )
        
        listVM.onTaskSelected = { [weak self] task in
            guard let self else { return }
            sheetDestination = .details(TaskVM(mainModel: task))
        }
    }
    
    //MARK: - Update notification
    public func updateNotifications() async {
        guard onboardingManager.onboardingComplete == true else {
            return
        }
        
        try? await Task.sleep(for: .seconds(0.2))
        
        await notificationManager.createNotification()
    }
    
    /// Only once time for ask notification reqest
    @objc private func handleFirstTimeOpenDone() {
        Task {
            await updateNotifications()
        }
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("firstTimeOpenHasBeenDone"),
            object: nil
        )
    }
    
    public func mainScreenOpened() {
        telemetryManager.logEvent(.openView(.home(.open)))
    }
    
    // MARK: - Telemetry action
    func telemetryAction(_ event: EventType) {
        telemetryManager.logEvent(event)
    }
    
    //MARK: - Profile actions
    func profileModelSave() {
        casManager.saveProfileData(profileModel)
    }
    
    private func downloadProfileModelFromCas() {
        profileModel = casManager.profileModel
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
        guard subscriptionManager.hasSubscription() else {
            while showPaywall {
                try await Task.sleep(for: .seconds(0.1))
            }
            
            mainViewPaywall = false
            return
        }
        
        recordingState = .recording
        playerManager.stopToPlay()
        
        // telemetry
        telemetryAction(.mainViewAction(.recordTaskButtonTapped(.tryRecording)))
        
        do {
            changeDisabledButton()
            try recordPermission.peremissionSessionForRecording()
            try await recordPermission.permissionForSpeechRecognition()
            
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
        await recordManager.startRecording()
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
        
        if let audioURLString = recordManager.stopRecording() {
            hashOfAudio = casManager.saveAudio(url: audioURLString)
        }
        
        createTask(with: hashOfAudio)
        recordManager.clearFileFromDirectory()
        
        // telemetry
        telemetryAction(.mainViewAction(.recordTaskButtonTapped(.stopRecording)))
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        recordingState = .idle
    }
    
    //MARK: - Create task
    func createTask(with audioHash: String? = nil) {
        let model = MainModel(
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
        
        sheetDestination = .details(TaskVM(mainModel: model, titleFocused: true))
    }
    
    //MARK: - Recognize data
    func defaultTitle() -> String? {
        guard recordManager.recognizedText == "" else {
            return recordManager.recognizedText
        }
        return nil
    }
    
    func speechDescription() -> String? {
        recordManager.wholeDescription
    }
    
    func defaultNotificationTime() -> Double {
        if let recognizedDate = recordManager.dateTimeFromtext {
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
    
    //MARK: - Calendar
    func calendarButtonTapped() {
        path.append(Destination.calendar)
        mainViewIsOpen = false
        
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
            let task = casManager.models.values.first { task in
                extractBaseId(from: task.id) == baseSearchId
            }
            
            if let task {
                mainModel = task
            }
            
            return
        }
        
        if let taskId = notification?.userInfo?["taskId"] as? String {
            let baseSearchId = extractBaseId(from: taskId)
            let task = casManager.models.values.first { task in
                extractBaseId(from: task.id) == baseSearchId
            }
            if let task {
                mainModel = task
            }
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
        
        guard casManager.completedTaskCount() >= 23 && profileModel.onboarding.requestedReview == false else {
            return
        }
        
        askReview = true
        profileModel.onboarding.requestedReview = true
        profileModelSave()
    }
    
    //MARK: Function before closeApp
    public func closeApp() async {
        let backgroundManager = BackgroundManager()
        casManager.updateCASAfterWork()
        await updateNotifications()
        await backgroundManager.scheduleAppRefreshTask()
    }
    
    //MARK: - Background update
    public func backgroundUpdate() async {
        let backgroundManager = BackgroundManager()
        
        await backgroundManager.backgroundUpdate()
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

extension Data {
    func thumbnailImageData(maxPixelSize: Int = 64) -> Data? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8)
    }
}
