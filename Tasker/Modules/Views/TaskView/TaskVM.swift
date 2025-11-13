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
public final class TaskVM: Identifiable {
    // MARK: - Managers
//    @ObservationIgnored @Injected(\.casManager) var casManager: CASManagerProtocol
//    @ObservationIgnored @Injected(\.playerManager) private var playerManager: PlayerManagerProtocol
//    @ObservationIgnored @Injected(\.recorderManager) private var recorderManager: RecorderManagerProtocol
//    @ObservationIgnored @Injected(\.permissionManager) private var recordPermission: PermissionProtocol
//    @ObservationIgnored @Injected(\.dateManager) private var dateManager: DateManagerProtocol
//    @ObservationIgnored @Injected(\.notificationManager) private var notificationManager: NotificationManagerProtocol
//    @ObservationIgnored @Injected(\.taskManager) private var taskManager: TaskManagerProtocol
//    @ObservationIgnored @Injected(\.storageManager) private var storageManager: StorageManagerProtocol
//    @ObservationIgnored @Injected(\.appearanceManager) private var appearanceManager: AppearanceManagerProtocol
//    @ObservationIgnored @Injected(\.telemetryManager) private var telemetryManager: TelemetryManagerProtocol
//    @ObservationIgnored @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerProtocol
    
    let taskManager: TaskManagerProtocol
    
    let profileManager: ProfileManagerProtocol
    
    let dateManager: DateManagerProtocol
    
    let playerManager: PlayerManagerProtocol
    
    let recorderManager: RecorderManagerProtocol
    
    let permissionManager: PermissionProtocol
    
    let telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    let subscriptionManager: SubscriptionManagerProtocol = SubscriptionManager.createSubscriptionManager()
    
    // MARK: - Models
    
    var task: UITaskModel
    var profileModel: UIProfileModel
    
    var backgroundColor: Color = .white
    
    var repeatTask = RepeatTask.never {
        didSet {
            if repeatTask == .dayOfWeek {
                showDayOfWeekSelector = true
            } else {
                showDayOfWeekSelector = false
            }
        }
    }
    var dayOfWeek = [DayOfWeek]()
    
    // MARK: - UI States
    var titleFocused = false
    var showDatePicker = false
    var showTimePicker = false
    var showDayOfWeekSelector = false
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
    var defaultTimeHasBeenSet = false
    
    var initing = false
    
    var showPaywall: Bool {
        subscriptionManager.showPaywall
    }
    
    // MARK: - Confirmation dialog
    var confirmationDialogIsPresented = false
    var messageForDelete: LocalizedStringKey = ""
    var singleTask = true
    
    // MARK: - Computed properties
    var calendar: Calendar { dateManager.calendar }
    
    var notificationDate = Date() {
        didSet {
            checkTimeAfterSelected()
            dateHasBeenChanged = true
        }
    }
    
    var hasDeadline = false {
        didSet {
            if hasDeadline == true {
                guard !initing else {
                    return
                }
                showDeadline = true
            } else {
                removeDeadlineFromTask()
            }
        }
    }
    
    var deadLineDate = Date() {
        didSet {
            checkTimeAfterDeadlineSelected()
            setUpDeadlineDate()
        }
    }
    
    var showDeadline = false {
        didSet {
            if showDeadline == true {
                guard subscriptionManager.hasSubscription() else {
                    showDeadline = false
                    return
                }
            }
        }
    }
    
    /// First notification Date for task with repeat
    var sourseDateOfNotification = Date()
    
    var textForNotificationDate: LocalizedStringKey {
        notificationDateToText()
    }
    
    var textForDeadlineDate: LocalizedStringKey {
        deadlineToText()
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
//    public init(mainModel: MainModel, titleFocused: Bool = false) {
//        initing = true
//        self.titleFocused = titleFocused
//        setUPViewModel(mainModel)
//        initing = false
//    }
    
    private func setUPViewModel(_ mainModel: MainModel) async {
        preSetTask(mainModel)
        setUpTime()
        setUpColor()
        await playerManager.setUpTotalTime(task: task)
    }
    
    private func preSetTask(_ mainModel: MainModel) {
//        profileModel = casManager.profileModel
        self.task = mainModel
        setUpRepeat()
        
        if let endDate = task.deadline {
            hasDeadline = true
            deadLineDate = Date(timeIntervalSince1970: endDate)
        }
    }
    
    func onAppear(colorScheme: ColorScheme) {
        backgroundColorForTask(colorScheme: colorScheme)
    }
    
    func disappear() {
        stopPlaying()
//        subscriptionManager.showPaywall = false
    }
    
    private func setUpTime() {
        sourseDateOfNotification = Date(timeIntervalSince1970: task.notificationDate)
        
        guard let data = firstTimeCreateTask(task) else {
            notificationDate = createNotificationDateFromExistTask()
            dateHasBeenChanged = false
            return
        }
        
        notificationDate = data
        dateHasBeenChanged = false
    }
    
    func createNotificationDateFromExistTask() -> Date {
        var dateComponent = DateComponents()
        dateComponent.year = calendar.dateComponents([.year], from: dateManager.selectedDate).year
        dateComponent.month = calendar.dateComponents([.month], from: dateManager.selectedDate).month
        dateComponent.day = calendar.dateComponents([.day], from: dateManager.selectedDate).day
        dateComponent.hour = originalNotificationTimeComponents.hour
        dateComponent.minute = originalNotificationTimeComponents.minute
        return calendar.date(from: dateComponent)!
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
    
    //MARK: - Repeat actions
    func changeTypeOfRepeat(_ value: RepeatTask) {
        if value == .dayOfWeek {
            showDayOfWeekSelector = true
        } else {
            showDayOfWeekSelector = false
        }
    }
    
    private func setUpRepeat() {
        repeatTask = task.repeatTask
        
        if task.repeatTask == .dayOfWeek {
            showDayOfWeekSelector = true
        }
        
        dayOfWeek = task.dayOfWeek.actualyDayOFWeek(calendar)
    }
    
    //MARK: - Color task
    func backgroundColorForTask(colorScheme: ColorScheme) {
        if task.taskColor == .baseColor {
            backgroundColor = colorScheme.backgroundColor()
        } else {
            backgroundColor = task.taskColor.color(for: colorScheme)
        }
    }
    
    func selectedColorButtonTapped(_ taskColor: TaskColor, colorScheme: ColorScheme) {
        backgroundColor = taskColor.color(for: colorScheme)
        task.taskColor = taskColor
        selectedColorTapped.toggle()
        
        // telemetry
        telemetryAction(.taskAction(.changeColorButtonTapped(taskColor)))
    }
    
    func checkColorForCheckMark(_ taskColor: TaskColor, for colorScheme: ColorScheme) -> Bool {
        guard taskColor == .baseColor && backgroundColor == colorScheme.backgroundColor() else {
            if taskColor.color(for: colorScheme) == backgroundColor {
                return true
            } else {
                return false
            }
        }
        
        return true
    }
    
    func shareViewButtonTapped() {
        shareViewIsShowing.toggle()
    }
    
    func typeOfRepeatHasBeenChanged(_ type: RepeatTask) {
        repeatTask = type
    }
    
    //MARK: - Save task
    func saveTask() async {
        saveRepeat()
        
        task.notificationDate = changeNotificationTime()
        
        do {
           try  await taskManager.saveTask(task)
            createTempAudioFile(audioHash: task.audio ?? "")
        } catch {
            //TODO: - Error
        }
    }
    
    func closeButtonTapped() async {
        
        await saveTask()
        // telemetry
        telemetryAction(.taskAction(.repeatTaskButtonTapped(task.repeatTask)))
        telemetryAction(.taskAction(.closeButtonTapped(.list)))
        
        if recorderManager.recognizedText != "" && task.title != recorderManager.recognizedText {
            telemetryAction(.taskAction(.correctionTitle))
        }
        
        if recorderManager.dateTimeFromtext != nil && notificationDate != recorderManager.dateTimeFromtext {
            telemetryAction(.taskAction(.correctionDate))
        }
        
        recorderManager.resetDataFromText()
    }
    
    
    private func changeNotificationTime() -> Double {
        guard dateHasBeenChanged else {
            return sourseDateOfNotification.timeIntervalSince1970
        }
        
        guard !defaultTimeHasBeenSet else {
            return notificationDate.timeIntervalSince1970
        }
        
        guard calendar.isDate(notificationDate, inSameDayAs: dateManager.selectedDate) else {
            return notificationDate.timeIntervalSince1970
        }
        
        guard !calendar.isDate(notificationDate, inSameDayAs: dateManager.selectedDate) else {
            var sourceDate = calendar.dateComponents([.year, .month, .day], from: sourseDateOfNotification)
            sourceDate.hour = calendar.component(.hour, from: notificationDate)
            sourceDate.minute = calendar.component(.minute, from: notificationDate)
            
            return calendar.date(from: sourceDate)!.timeIntervalSince1970
        }
        
        return notificationDate.timeIntervalSince1970
    }
    
    // MARK: - Prepeare task
    
    // MARK: - Logic for save repeat
    private func saveRepeat() {
        task.repeatTask = repeatTask
        
        guard task.repeatTask == .dayOfWeek else {
            dayOfWeek = []
            return
        }
        
        let emptyDayOfWeek = dayOfWeek.count == 7 && dayOfWeek.allSatisfy { $0.value == false }
        
        if emptyDayOfWeek {
            task.repeatTask = .never
        }
        
        let everyDay = dayOfWeek.count == 7 && dayOfWeek.allSatisfy { $0.value == true }
        
        guard everyDay else {
            task.dayOfWeek = dayOfWeek
            return
        }
        
        task.repeatTask = .daily
        task.dayOfWeek = dayOfWeek
    }
    //    private func preparedTask() -> UITaskModel {
    //        taskManager.preparedTask(task: task, date: notificationDate)
    //    }
    
    //MARK: - Date and time
    private func notificationDateToText() -> LocalizedStringKey {
        dateManager.dateToString(for: notificationDate, useForWeekView: false)
    }
    
    private func deadlineToText() -> LocalizedStringKey {
        dateManager.dateForDeadline(for: deadLineDate)
    }
    
    //MARK: - First time check
    private func firstTimeCreateTask(_ task: UITaskModel) -> Date? {
        guard taskManager.activeTasks.contains(where: { $0.id == task.id }) else {
            defaultTimeHasBeenSet = true
            return recorderManager.dateTimeFromtext ?? dateManager.combineDateAndTime(timeComponents: originalNotificationTimeComponents)
        }
        
        return nil
    }
    
    private func dateHasBeenSelected() {
        showDatePicker = false
        showTimePicker = false
        showDeadline = false
    }
    
    private func checkTimeAfterSelected() {
        guard initing == false else {
            return
        }
        
        isDeadlineInCorrectDate()
        
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
    
    //MARK: - Deadline
    func setUpDeadlineDate() {
        task.deadline = deadLineDate.timeIntervalSince1970
        
        if task.repeatTask == .never {
            task.repeatTask = .daily
        }
        
        hasDeadline = true
    }
    
    func showDedalineButtonTapped() {
        showDeadline.toggle()
    }
    
    func removeDeadlineFromTask() {
        showDeadline = false
        task.deadline = nil
    }
    
    func isDeadlineInCorrectDate() {
        guard hasDeadline else {
            return
        }
        
        if notificationDate.timeIntervalSince1970 > deadLineDate.timeIntervalSince1970 {
            deadLineDate = notificationDate
        }
    }
    
    //MARK: - Auto close functionality
    private func checkTimeAfterDeadlineSelected() {
        guard initing == false else {
            return
        }
        
        debounceTimer?.invalidate()
        lastChangeTime = Date()
        
        let oldComponents = calendar.dateComponents([.day, .month, .year], from: lastNotificationDate)
        let newComponents = calendar.dateComponents([.day, .month, .year], from: deadLineDate)
        
        let timeInterval: TimeInterval = (oldComponents != newComponents) ? 0.1 : 1.0
        lastNotificationDate = deadLineDate
        
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
        do {
            try await taskManager.checkMarkTapped(task: task)
            taskDoneTrigger.toggle()
            
            // telemetry
            telemetryAction(.taskAction(.checkMarkButtonTapped(.taskView)))
        } catch {
            
        }
    }
    
    
    //MARK: - Delete
    func deleteTaskButtonTapped() {
        if task.repeatTask == .never {
            messageForDelete = "Delete task?"
            singleTask = true
        } else {
            messageForDelete = "This's a recurring task."
            singleTask = false
        }
        confirmationDialogIsPresented.toggle()
    }
    
    func deleteButtonTapped(model: MainModel, deleteCompletely: Bool = false) async {
        do {
            try await taskManager.deleteTask(task: model, deleteCompletely: deleteCompletely)
        } catch {
            //TODO: - Error
        }
    }
    
    // MARK: - Playback
    func playButtonTapped(task: UITaskModel) async {
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
        let duration = await playerManager.returnTotalTime(task: task)
        
        //FIXME: What's it?
//        playerManager.totalTime = duration
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
            try permissionManager.peremissionSessionForRecording()
            try await permissionManager.permissionForSpeechRecognition()
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
//            hashOfAudio = casManager.saveAudio(url: audioURLString)
        }
        
        if let hashOfAudio {
            task.audio = hashOfAudio
        }
        
        task.voiceMode = true
        
        if task.title.isEmpty || task.title == "New task" {
            if !recorderManager.recognizedText.isEmpty {
                task.title = recorderManager.recognizedText
            }
        }
        
        Task { [weak self] in
            await self?.loadTotalTimeIfNeeded()
        }
        
        playButtonTrigger.toggle()
    }
    
    private func createTempAudioFile(audioHash: String) {
        _ = storageManager.createFileInSoundsDirectory(hash: audioHash)
    }
    
    private func changeDisabledButton() {
        disabledButton.toggle()
    }
    
    //MARK: Subscription
    func deadlineButtonTapped() async {
        guard !subscriptionManager.hasSubscription() else {
            return
        }
        
        while subscriptionManager.showPaywall {
            try? await Task.sleep(for: .seconds(0.3))
        }
        
        hasDeadline = subscriptionManager.subscribed
    }
    
    
    //MARK: - Telemetry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
