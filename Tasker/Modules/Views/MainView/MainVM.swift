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
    
    //MARK: - UI States
    var mainViewIsOpen = true
    var profileViewIsOpen = false
    var isRecording = false
    var showDetailsScreen = false
    var alert: AlertModel?
    var disabledButton = false
    var askReview = false
    
    var onboardingComplete: Bool {
        onboardingManager.onboardingComplete
    }
    
    /// First time ever opened
    var sayHello = false
    
    var mainViewPaywall = false
    var showPaywall: Bool {
        mainViewPaywall && subscriptionManager.showPaywall
    }
    
    var presentationPosition: PresentationDetent = PresentationMode.base.detent {
        didSet {
            if presentationPosition == .fraction(0.96) {
                if path.count > 0 {
                    path.removeLast()
                }
                onboardingManager.showingNotes = nil
            }
            
            if presentationPosition == .fraction(0.20) {
                //                subscriptionManager.closePaywall()
                
                // telemetry
                telemetryAction(.mainViewAction(.showNotesButtonTapped))
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
    
    var showTips: Bool {
        taskManager.tasks.isEmpty
    }
    
    public var profileUpdateTrigger: Bool {
        casManager.profileUpdateTriger
    }
    
    //MARK: - Init
    public init() {
        createCustomProfileModel()
        setupCallbacks()
        
        Task {
            await onboardingStart()
            await updateNotifications()
        }
    }
    
    func disappear() {
        recordManager.resetDataFromText()
    }
    
    public func updateNotifications() async {
        guard profileModel.onboarding.createButtonTip else {
            return
        }
        
        while showPaywall == true {
            try? await Task.sleep(for: .seconds(0.1))
        }
        
        checkNotificationPermission()
        
        await notificationManager.createNotification()
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
    
    public func createCustomProfileModel() {
        profileModel = casManager.profileModel
    }
    
    func profileViewButtonTapped() {
        profileViewIsOpen = true
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
                    taskColor: profileModel.settings.defaultTaskColor
                )
            )
        )
        
        mainModel = model
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
    
    private func checkNotificationPermission() {
        Task {
            await notificationManager.checkPermission()
            
            guard let alert = notificationManager.alert else {
                return
            }
            
            self.alert = alert
        }
    }
    
    //MARK: - Onboarding
    private func onboardingStart() async {
        disabledButton = true
        mainViewPaywall = true
        
        await onboardingManager.firstTimeOpen()
        
        try? await Task.sleep(for: .seconds(0.8))
        
        if profileModel.onboarding.requestedReview == false {
            askReview = true
            profileModel.onboarding.requestedReview = true
            profileModelSave()
        }
        
        if showPaywall == false {
            mainViewPaywall = false
        }
        
        disabledButton = false
    }
    
    private func setupCallbacks() {
        guard profileModel.onboarding.createButtonTip == false else {
            return
        }
        onboardingManager.showingCalendar = { [weak self] _ in
            self?.calendarButtonTapped()
        }
        onboardingManager.showingProfile = { [weak self] _ in
            self?.profileViewButtonTapped()
        }
        onboardingManager.showingNotes = { [weak self] _ in
            self?.presentationPosition = .fraction(0.20)
        }
        
        onboardingManager.scrollWeek = { [weak self] _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                self?.dateManager.indexForWeek += 1
            }
        }
    }
    
    //MARK: Function before closeApp
    public func closeApp() async {
        let tasks = Array(taskManager.tasks.values)
        casManager.updateCASAfterWork(models: tasks)
        await updateNotifications()
    }
}

//MARK: - Helpers not a VM
enum PresentationMode: CGFloat, CaseIterable {
    case base = 0.96
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
