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
    @ObservationIgnored
    @AppStorage("textForYourSelf", store: .standard) var textForYourSelf = "Write your title 🎯"
    
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
    
    //MARK: - Model
    var model: MainModel?
    
    var profileModel: ProfileData = mockProfileData()
    
    public var colorSchemeFromSettings: String?  {
        casManager.profileModel?.value.settings.colorScheme
    }
    
    //MARK: - UI States
    var mainViewIsOpen = true
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
        taskManager.tasks.isEmpty && taskManager.completedTasks.isEmpty
    }
    
    public var profileUpdateTrigger: Bool {
        casManager.profileUpdateTriger
    }
    
    public init() {
        createCustomProfileModel()
        Task {
            checkNotificationPermission()
            await notificationManager.createNotification()
        }
    }
    
    func startAfterChek() async throws {
        
        recordingState = .recording
        
        playerManager.stopToPlay()
        
        do {
            changeDisabledButton()
            try recordPermission.peremissionSessionForRecording()
            await startRecord()
            changeDisabledButton()
        } catch let error as MicrophonePermission {
            switch error {
            case .silentError: return
            case .microphoneIsNotAvalible:
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
    
    //MARK: - Profile model save
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
    
    //MARK: - Appearance
    public func changeColorScheme() -> ColorScheme {
        if profileModel.value.settings.colorScheme == "Light" {
            return .light
        } else {
            return .dark
        }
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
    
    @MainActor
    func stopAfterCheck(_ newValue: Double?) async {
        guard let value = newValue, value >= 15.0 else { return }
        await stopRecord()
    }
    
    func startRecord() async {
        isRecording = true
        await recordManager.startRecording()
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
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        recordingState = .idle
    }
    
    func createTask(with audioHash: String? = nil) {
        
        model = MainModel.initial(TaskModel(
            id: UUID().uuidString,
            title: "",
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
        }
    }
    
    //MARK: - Calendar
    func calendarButtonTapped() {
        path.append(Destination.calendar)
        mainViewIsOpen = false
    }
    
    private func extractBaseId(from fullId: String) -> String {
        return fullId.components(separatedBy: ".").first ?? fullId
    }
    
    public func selectedTask(by notification: Notification? = nil, taskId: String? = nil) {
        guard taskId == nil else {
            let baseSearchId = extractBaseId(from: taskId!)
            let task = taskManager.tasks.first { task in
                extractBaseId(from: task.value.id) == baseSearchId
            }
            model = task
            return
        }
        
        if let taskId = notification?.userInfo?["taskId"] as? String {
            let baseSearchId = extractBaseId(from: taskId)
            let task = taskManager.tasks.first { task in
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
