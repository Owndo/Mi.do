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
    @ObservationIgnored @Injected(\.dateManager) private var dateManager: DateManagerProtocol
    @ObservationIgnored @Injected(\.notificationManager) private var notificationManager: NotificationManagerProtocol
    @ObservationIgnored @Injected(\.taskManager) private var taskManager: TaskManagerProtocol
    @ObservationIgnored @Injected(\.storageManager) private var storageManager: StorageManagerProtocol
    @ObservationIgnored @Injected(\.appearanceManager) private var appearanceManager: AppearanceManagerProtocol
    
    // MARK: - Model
    var mainModel: MainModel = mockModel()
    var task: TaskModel = mockModel().value
    
    // MARK: - UI States
    var showDatePicker = false
    var showTimePicker = false
    var shareViewIsShowing = false
    var taskDoneTrigger = false
    var playButtonTrigger = false
    var sliderValue = 0.0
    var isDragging = false
    var pause = false
    var dateHasBeenChanged = false
    
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
    var sourseDateOfNotification = Double()
    
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
    }
    
    private func preSetTask(_ mainModel: MainModel) {
        self.mainModel = mainModel
        task = mainModel.value
    }
    
    private func setUpTime() {
        let time = originalNotificationTimeComponents
        notificationDate = combineDateAndTime(timeComponents: time)
        
        sourseDateOfNotification = mainModel.value.notificationDate
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
    }
    
    func selectTimeButtonTapped() {
        showTimePicker.toggle()
    }
    
    func selectedColorButtonTapped(_ taskColor: TaskColor) {
        task.taskColor = taskColor
    }
    
    func shareViewButtonTapped() {
        shareViewIsShowing.toggle()
    }
    
    //MARK: - Save task
    func saveTask() async {
        task = preparedTask()
        task.notificationDate = dateHasBeenChanged ? notificationDate.timeIntervalSince1970 : sourseDateOfNotification
        mainModel.value = task
        
        casManager.saveModel(mainModel)
        createTempAudioFile(audioHash: task.audio ?? "")
        
        await notificationManager.createNotification()
    }
    
    
    
    private func preparedTask() -> TaskModel {
        taskManager.preparedTask(task: task, date: notificationDate)
    }
    
    //MARK: - Date and time
    private func dateToString() -> String {
        dateManager.dateToString(for: notificationDate, format: "MMMM d", useForWeekView: false)
    }
    
    private func combineDateAndTime(timeComponents: DateComponents) -> Date {
        if setUpDefaultTime(task) {
            return dateManager.combineDateAndTime(timeComponents: timeComponents)
        } else {
            return Date(timeIntervalSince1970: task.notificationDate)
        }
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
        
        let timeInterval: TimeInterval = (oldComponents != newComponents) ? 0.1 : 0.8
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
    }
    
    
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
        task = taskManager.deleteTask(task: model, deleteCompletely: deleteCompletely).value
        await saveTask()
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
        
    }
    
    func stopPlaying() {
        playerManager.stopToPlay()
    }
    
    func seekAudio(_ time: TimeInterval) {
        playerManager.seekAudio(time)
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
        if isRecording {
            stopRecord()
        } else {
            await startRecord()
        }
    }
    
    @MainActor
    func stopAfterCheck(_ newValue: Double?) {
        guard let value = newValue, value >= 15.0 else { return }
        stopRecord()
    }
    
    private func startRecord() async {
        await recorderManager.startRecording()
    }
    
    private func stopRecord() {
        var hashOfAudio: String?
        if let audioURLString = recorderManager.stopRecording() {
            hashOfAudio = casManager.saveAudio(url: audioURLString)
        }
        task.audio = hashOfAudio
        task.voiceMode = true
        
        Task { [weak self] in
            await self?.loadTotalTimeIfNeeded()
        }
    }
    
    private func createTempAudioFile(audioHash: String) {
        _ = storageManager.createFileInSoundsDirectory(hash: audioHash)
    }
    
    //MARK: Appearance
    func colorScheme() -> String {
        appearanceManager.colorScheme()
    }
    
    func backgroundColor() -> Color {
        appearanceManager.backgroundColor()
    }
    
    func accentColor() -> Color {
        appearanceManager.accentColor()
    }
}
