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
    
    //MARK: - Model
    var model: MainModel?
    
    //MARK: - UI States
    var mainViewIsOpen = true
    var isRecording = false
    var showDetailsScreen = false
    var alert: AlertModel?
    var disabledButton = false
    
    var recordingState: RecordingState = .idle
    
    enum RecordingState {
        case idle
        case recording
        case stopping
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
    
    public init() {
        checkNotificationPermission()
    }
    
    func startAfterChek() async throws {
        
        guard recordingState == .idle else { return }
        
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
    
    public func selectedTask(by notification: Notification? = nil, taskId: String? = nil) {
        guard taskId == nil else {
            let task = taskManager.tasks.first { $0.value.id == taskId }
            model = task
            return
        }
        
        if let taskId = notification?.userInfo?["taskId"] as? String {
            let task = taskManager.tasks.first { $0.value.id == taskId }
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
