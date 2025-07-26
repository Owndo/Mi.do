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

@Observable
final class TaskVM {
    // MARK: - Managers
    @ObservationIgnored @Injected(\.casManager) var casManager: CASManagerProtocol
    @ObservationIgnored @Injected(\.playerManager) private var playerManager: PlayerManagerProtocol
    @ObservationIgnored @Injected(\.recorderManager) private var recorderManager: RecorderManagerProtocol
    @ObservationIgnored @Injected(\.permissionManager) private var recordPermission: PermissionProtocol
    @ObservationIgnored @Injected(\.dateManager) private var dateManager: DateManagerProtocol
    @ObservationIgnored @Injected(\.notificationManager) private var notificationManager: NotificationManagerProtocol
    @ObservationIgnored @Injected(\.taskManager) private var taskManager: TaskManagerProtocol
    @ObservationIgnored @Injected(\.storageManager) private var storageManager: StorageManagerProtocol
    @ObservationIgnored @Injected(\.appearanceManager) private var appearanceManager: AppearanceManagerProtocol
    @ObservationIgnored @Injected(\.telemetryManager) private var telemetryManager: TelemetryManagerProtocol
    @ObservationIgnored @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerProtocol
    
    // MARK: - Model
    var mainModel: MainModel = mockModel()
    var task: TaskModel = mockModel().value
    var profileModel: ProfileData = mockProfileData()
    
    // MARK: - UI States
    var showDatePicker = false
    var showTimePicker = false
    var shareViewIsShowing = false
    var taskDoneTrigger = false
    var playButtonTrigger = false
    var sliderValue = 0.0
    var isDragging = false
    var pause = false
    var selectedColorTapped = false
    var dateHasBeenChanged = false
    var alert: AlertModel?
    var disabledButton = false
    var checkMarkTip = false
    
    var showPaywall: Bool {
        subscriptionManager.showPaywall
    }
    
    // MARK: - Confirmation dialog
    var confirmationDialogIsPresented = false
    var messageForDelete = ""
    var singleTask = true
    
    // MARK: - Computed properties
    var calendar: Calendar { dateManager.calendar }
    
    var notificationDate = Date() {
        didSet {
            checkTimeAfterSelected()
            dateHasBeenChanged = true
        }
    }
    
    /// First notification Date for task with repeat
    var sourseDateOfNotification = Date()
    
    var dateForAppearence: String {
        dateToString()
    }
    
    var isPlaying: Bool {
        playerManager.isPlaying
    }
    
    var currentProgressTime: TimeInterval {
        playerManager.currentTime
    }
    
    var totalProgressTime: TimeInterval {
        playerManager.totalTime
    }
    
    var totalStringProgressTime: String {
        currentTimeString()
    }
    
    var isRecording: Bool {
        recorderManager.isRecording
    }
    
    var decibelLVL: Float {
        recorderManager.decibelLevel
    }
    
    /// Time for check how many seconds recording goes
    var currentlyRecordTime: Double {
        recorderManager.currentlyTime
    }
    
    @ObservationIgnored
    var color = Color.black {
        didSet {
            task.taskColor = .custom(color.toHex())
        }
    }
    
    private var originalNotificationTimeComponents: DateComponents {
        calendar.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: task.notificationDate))
    }
    
    // MARK: - Private properties
    private var lastChangeTime = Date()
    private var debounceTimer: Timer?
    private var lastNotificationDate = Date()
    
    // MARK: - Init
    init(mainModel: MainModel) {
        setUPViewModel(mainModel)
    }
    
    private func setUPViewModel(_ mainModel: MainModel) {
        preSetTask(mainModel)
        setUpTime()
        setUpColor()
        playerManager.setUpTotalTime(task: task)
    }
    
    private func preSetTask(_ mainModel: MainModel) {
        profileModel = casManager.profileModel ?? mockProfileData()
        self.mainModel = mainModel
        task = mainModel.value
        
        Task {
            await onboarding()
        }
    }
    
    private func setUpTime() {
        notificationDate = combineDateAndTime(timeComponents: originalNotificationTimeComponents)
        
        sourseDateOfNotification = Date(timeIntervalSince1970: mainModel.value.notificationDate)
        dateHasBeenChanged = false
    }
    
    
    private func setUpColor() {
        switch task.taskColor {
        case .custom(let customColor):
            color = customColor.hexColor()
        default: break
        }
    }
    
    // MARK: - Actions
    func selectDateButtonTapped() {
        showDatePicker.toggle()
        
        // telemetry
        telemetryAction(.taskAction(.selectDateButtonTapped))
    }
    
    func selectTimeButtonTapped() {
        showTimePicker.toggle()
        
        // telemetry
        telemetryAction(.taskAction(.selectTimeButtonTapped))
    }
    
    func selectedColorButtonTapped(_ taskColor: TaskColor) {
        task.taskColor = taskColor
        selectedColorTapped.toggle()
        
        // telemetry
        telemetryAction(.taskAction(.changeColorButtonTapped(taskColor)))
    }
    
    func shareViewButtonTapped() {
        shareViewIsShowing.toggle()
    }
    
    //MARK: - Save task
    func saveTask() async {
        task = preparedTask()
        task.notificationDate = changeNotificationTime()
        mainModel.value = task
        
        casManager.saveModel(mainModel)
        createTempAudioFile(audioHash: task.audio ?? "")
        
        await notificationManager.createNotification()
        
        // telemetry
        telemetryAction(.taskAction(.repeatTaskButtonTapped(task.repeatTask)))
        telemetryAction(.taskAction(.closeButtonTapped(.list)))
        
        if recorderManager.recognizedText != "" && task.title != recorderManager.recognizedText {
            telemetryAction(.taskAction(.correctionTitle))
        }
        
        if recorderManager.dateTimeFromtext != nil && notificationDate != recorderManager.dateTimeFromtext {
            telemetryAction(.taskAction(.correctionDate))
        }
    }
    
    
    private func changeNotificationTime() -> Double {
        var sourceDate = calendar.dateComponents([.year, .month, .day], from: sourseDateOfNotification)
        
        if dateHasBeenChanged && !calendar.isDate(notificationDate, inSameDayAs: dateManager.selectedDate) {
            return notificationDate.timeIntervalSince1970
        } else if dateHasBeenChanged && !setUpDefaultTime(task) {
            sourceDate.hour = calendar.component(.hour, from: notificationDate)
            sourceDate.minute = calendar.component(.minute, from: notificationDate)
            
            return calendar.date(from: sourceDate)!.timeIntervalSince1970
        } else if calendar.isDate(notificationDate, inSameDayAs: dateManager.selectedDate) {
            return notificationDate.timeIntervalSince1970
        } else {
            return sourseDateOfNotification.timeIntervalSince1970
        }
    }
    
    private func preparedTask() -> TaskModel {
        taskManager.preparedTask(task: task, date: notificationDate)
    }
    
    //MARK: - Date and time
    private func dateToString() -> String {
        dateManager.dateToString(for: notificationDate, format: "MMMM d", useForWeekView: false)
    }
    
    private func combineDateAndTime(timeComponents: DateComponents) -> Date {
        guard setUpDefaultTime(task) else {
            return dateManager.createdtaskDate(task: task)
        }
        
        return recorderManager.dateTimeFromtext ?? dateManager.combineDateAndTime(timeComponents: timeComponents)
    }
    
    
    private func setUpDefaultTime(_ task: TaskModel) -> Bool {
        if taskManager.activeTasks.contains(where: { $0.value.id == task.id }) {
            return false
        } else {
            return true
        }
    }
    
    private func dateHasBeenSelected() {
        showDatePicker = false
        showTimePicker = false
    }
    
    private func checkTimeAfterSelected() {
        debounceTimer?.invalidate()
        lastChangeTime = Date()
        
        let oldComponents = calendar.dateComponents([.day, .month, .year], from: lastNotificationDate)
        let newComponents = calendar.dateComponents([.day, .month, .year], from: notificationDate)
        
        let timeInterval: TimeInterval = (oldComponents != newComponents) ? 0.1 : 1.0
        lastNotificationDate = notificationDate
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                if let self = self, Date().timeIntervalSince(self.lastChangeTime) >= timeInterval {
                    self.dateHasBeenSelected()
                }
            }
        }
    }
    
    func checkCompletedTaskForToday() -> Bool {
        taskManager.checkCompletedTaskForToday(task: task)
    }
    
    //MARK: - Complete tasks
    func checkMarkTapped() async {
        task = taskManager.checkMarkTapped(task: task)
        taskDoneTrigger.toggle()
        await saveTask()
        await notificationManager.createNotification()
        
        // telemetry
        telemetryAction(.taskAction(.checkMarkButtonTapped(.taskView)))
    }
    
    
    //MARK: - Delete
    func deleteTaskButtonTapped() {
        if task.repeatTask == .never {
            messageForDelete = "Delete this task?"
            singleTask = true
        } else {
            messageForDelete = "This's a recurring task."
            singleTask = false
        }
        confirmationDialogIsPresented.toggle()
    }
    
    func deleteButtonTapped(model: MainModel, deleteCompletely: Bool = false) async {
        Task {
            task = taskManager.deleteTask(task: model, deleteCompletely: deleteCompletely).value
            await saveTask()
            await notificationManager.createNotification()
        }
        
        // telemetry
        if model.value.repeatTask == .never {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteSingleTask(.taskView))))
        }
        
        // telemetry
        if model.value.repeatTask != .never && deleteCompletely == true {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteAllTasks(.taskView))))
        }
        
        // telemetry
        if model.value.repeatTask != .never && deleteCompletely == false {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteOneOfManyTasks(.taskView))))
        }
    }
    
    // MARK: - Playback
    func playButtonTapped(task: TaskModel) async {
        playButtonTrigger.toggle()
        pause = false
        
        guard !isPlaying else {
            pauseAudio()
            return
        }
        
        
        await loadTotalTimeIfNeeded()
        await playerManager.playAudioFromData(task: task)
        
        // telemetry
        telemetryAction(.taskAction(.playVoiceButtonTapped(.taskView)))
    }
    
    struct model: Codable {
        var name: String
    }
    
    func stopPlaying() {
        if playerManager.isPlaying {
            playerManager.stopToPlay()
            
            // telemetry
            telemetryAction(.taskAction(.stopPlayingVoiceButtonTapped(.taskView)))
        }
    }
    
    func seekAudio(_ time: TimeInterval) {
        playerManager.seekAudio(time)
        
        // telemetry
        telemetryAction(.taskAction(.seekToTime))
    }
    
    func currentTimeString() -> String {
        let time = isPlaying || pause ? currentProgressTime : totalProgressTime
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func loadTotalTimeIfNeeded() async {
        guard totalProgressTime == 0 else { return }
        let duration = playerManager.returnTotalTime(task: task)
        playerManager.totalTime = duration
    }
    
    private func getDataFromAudio() -> Data? {
        if let audio = task.audio {
            return casManager.getData(audio)
        }
        return nil
    }
    
    private func pauseAudio() {
        pause = true
        playerManager.pauseAudio()
    }
    
    private func resetAudioProgress() {
        playerManager.totalTime = 0.0
        playerManager.currentTime = 0.0
    }
    
    // MARK: - Recording
    func recordButtonTapped() async {
        guard subscriptionManager.hasSubscription() else {
            return
        }
        
        if isRecording {
            stopRecord()
        } else {
            try? await startRecord()
        }
        
        // telemetry
        telemetryAction(.taskAction(.addVoiceButtonTapped))
    }
    
    @MainActor
    func stopAfterCheck(_ newValue: Double?) {
        guard let value = newValue, value >= 15.0 else { return }
        stopRecord()
    }
    
    private func startRecord() async throws {
        do {
            try recordPermission.peremissionSessionForRecording()
            try await recordPermission.permissionForSpeechRecognition()
            await recorderManager.startRecording()
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
    
    private func stopRecord() {
        var hashOfAudio: String?
        
        if let audioURLString = recorderManager.stopRecording() {
            hashOfAudio = casManager.saveAudio(url: audioURLString)
        }
        task.audio = hashOfAudio
        task.voiceMode = true
        
        if task.title.isEmpty || task.title == "New task" {
            if !recorderManager.recognizedText.isEmpty {
                task.title = recorderManager.recognizedText
            }
        }
        
        Task { [weak self] in
            await self?.loadTotalTimeIfNeeded()
        }
    }
    
    private func createTempAudioFile(audioHash: String) {
        _ = storageManager.createFileInSoundsDirectory(hash: audioHash)
    }
    
    private func changeDisabledButton() {
        disabledButton.toggle()
    }
    
    //MARK: - Telemetry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
    
    //MARK: - Onboarding
    func onboarding() async {
        guard profileModel.value.onboarding.checkMarkTip == false else {
            return
        }
        
        checkMarkTip = true
        
        while checkMarkTip {
            try? await Task.sleep(for: .seconds(0.3))
        }
        
        profileModel.value.onboarding.checkMarkTip = true
        
        casManager.saveProfileData(profileModel)
    }
}
