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
    
    //MARK: - Model
    var model: MainModel?
    
    var profileModel: ProfileData = mockProfileData()
    
    //MARK: - UI States
    var mainViewIsOpen = true
    var profileViewIsOpen = false
    var isRecording = false
    var showDetailsScreen = false
    var alert: AlertModel?
    var disabledButton = false
    
    
    var presentationPosition: PresentationDetent = PresentationMode.base.detent {
        didSet {
            if presentationPosition == .fraction(0.96) {
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
        taskManager.activeTasks.isEmpty && taskManager.completedTasks.isEmpty
    }
    
    public var profileUpdateTrigger: Bool {
        casManager.profileUpdateTriger
    }
    
    public init() {
        createCustomProfileModel()
        Task {
            await updateNotifications()
        }
    }
    
    func disappear() {
        recordManager.resetDataFromText()
    }
    
    public func updateNotifications() async {
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
        if let model = casManager.profileModel {
            profileModel = model
        } else {
            let model = mockProfileData()
            
            profileModel = model
            profileModelSave()
        }
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
    
    func createTask(with audioHash: String? = nil) {
        model = MainModel.initial(TaskModel(
            id: UUID().uuidString,
            title: recordManager.recognizedText,
            info: "",
            audio: audioHash,
            notificationDate: dateManager.getDefaultNotificationTime().timeIntervalSince1970,
            voiceMode: audioHash != nil ? true : false,
            dayOfWeek: DayOfWeekEnum.dayOfWeekArray(for: calendar),
            done: [],
            deleted: []
        ))
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
            let task = taskManager.activeTasks.first { task in
                extractBaseId(from: task.value.id) == baseSearchId
            }
            model = task
            return
        }
        
        if let taskId = notification?.userInfo?["taskId"] as? String {
            let baseSearchId = extractBaseId(from: taskId)
            let task = taskManager.activeTasks.first { task in
                extractBaseId(from: task.value.id) == baseSearchId
            }
            model = task
        }
    }
    
    private func changeDisabledButton() {
        disabledButton.toggle()
    }
    
    private func checkNotificationPermission() {
        Task {
            await notificationManager.checkPermission()
            alert = notificationManager.alert
        }
    }
}

enum PresentationMode: CGFloat, CaseIterable {
    case base = 0.96
    case bottom = 0.20
    
    var detent: PresentationDetent {
        .fraction(rawValue)
    }
    
    static let detents = Set(PresentationMode.allCases.map { $0.detent })
}
