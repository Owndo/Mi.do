//
//  TaskVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/14/25.
//

import AppearanceManager
import Foundation
import SwiftUI
import Models
import StorageManager
import DateManager
import PlayerManager
import TaskManager
import ProfileManager
import RecorderManager
import PermissionManager
import SubscriptionManager
import TelemetryManager
import PaywallView
import CustomErrors

@Observable
public final class TaskVM: HashableNavigation {
    // MARK: - Managers
    
    let appearanceManager: AppearanceManagerProtocol
    
    let taskManager: TaskManagerProtocol
    
    let profileManager: ProfileManagerProtocol
    
    let dateManager: DateManagerProtocol
    
    var playerManager: PlayerManagerProtocol
    
    let recorderManager: RecorderManagerProtocol
    
    let permissionManager: PermissionProtocol = PermissionManager.createPermissionManager()
    
    let subscriptionManager: SubscriptionManagerProtocol
    
    let storageManager: StorageManagerProtocol
    
    let telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    //MARK: - PaywallVM
    
    var paywallVM: PaywallVM?
    
    // MARK: - Models
    
    public var task: UITaskModel
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
    public var titleFocused = false
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
    
    // Scroll Id
    var scrollId: String?
    var anchor: UnitPoint = .top
    
    var mainSectionID = "TitleSectionID"
    var dateSectionID = "DateSectionID"
    var timeSectionID = "TimeSectionID"
    var deadlineSectionID = "DeadlineSectionID"
    
    var taskCompletedforToday = false
    
    var initing = false
    
    //MARK: - Show paywall
    
    var showPaywall = false
    
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
    
    //MARK: - Deadline Toggle
    
    var deadlineToggle = false {
        willSet {
            Task {
                await checkSubscriptionAfterToggle(newValue)
            }
        }
    }
    
    var showDeadlineDates = false
    
    /// Only for toogle
    var deadlineDateSelected = false
    var resettingDeadline = false
    
    
    //MARK: - Deadline Date
    
    var deadLineDate = Date() {
        willSet {
            if !resettingDeadline {
                task.deadline = newValue.timeIntervalSince1970
            }
        }
        
        didSet {
            checkTimeAfterDeadlineSelected()
            setUpDeadlineDate()
        }
    }
    
    var showDeadline = false {
        didSet {
            Task {
                if showDeadline == true {
                    guard await subscriptionManager.hasSubscription() else {
                        showDeadline = false
                        return
                    }
                }
            }
        }
    }
    
    //MARK: - New Task
    
    var newTask = false
    
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
    
    private init(
        appearanceManager: AppearanceManagerProtocol,
        taskManager: TaskManagerProtocol,
        profileManager: ProfileManagerProtocol,
        dateManager: DateManagerProtocol,
        playerManager: PlayerManagerProtocol,
        recorderManager: RecorderManagerProtocol,
        storageManager: StorageManagerProtocol,
        subscriptionManager: SubscriptionManagerProtocol,
        task: UITaskModel,
    ) {
        self.appearanceManager = appearanceManager
        self.taskManager = taskManager
        self.profileManager = profileManager
        self.dateManager = dateManager
        self.playerManager = playerManager
        self.recorderManager = recorderManager
        self.storageManager = storageManager
        self.subscriptionManager = subscriptionManager
        self.task = task
        self.profileModel = profileManager.profileModel
    }
    
    //MARK: - VM Creator
    
    public static func createTaskVM(
        appearanceManager: AppearanceManagerProtocol,
        taskManager: TaskManagerProtocol,
        playerManager: PlayerManagerProtocol,
        storageManager: StorageManagerProtocol,
        profileManager: ProfileManagerProtocol,
        dateManager: DateManagerProtocol,
        recorderManager: RecorderManagerProtocol,
        task: UITaskModel,
    ) async -> TaskVM {
        let subscriptionManager = await SubscriptionManager.createSubscriptionManager()
        let vm = TaskVM(
            appearanceManager: appearanceManager,
            taskManager: taskManager,
            profileManager: profileManager,
            dateManager: dateManager,
            playerManager: playerManager,
            recorderManager: recorderManager,
            storageManager: storageManager,
            subscriptionManager: subscriptionManager,
            task: task
        )
        
        await vm.setUPViewModel()
        
        return vm
    }
    
    //MARK: - Mock VM Creator
    
    static func createPreviewTaskVM() -> TaskVM {
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let taskManager = TaskManager.createMockTaskManager()
        let profileManager = ProfileManager.createMockManager()
        let dateManager = DateManager.createPreviewManager()
        let playerManager = PlayerManager.createMockPlayerManager()
        let recorderManager = RecorderManager.createRecorderManager(dateManager: dateManager)
        let storageManager = StorageManager.createMockStorageManager()
        let subscriptionManager = MockSubscriptionManager.createNotSubscribedManager()
        
        let task = UITaskModel(.initial(mockModel().model.value))
        
        let vm = TaskVM(
            appearanceManager: appearanceManager,
            taskManager: taskManager,
            profileManager: profileManager,
            dateManager: dateManager,
            playerManager: playerManager,
            recorderManager: recorderManager,
            storageManager: storageManager,
            subscriptionManager: subscriptionManager,
            task: task,
        )
        
        return vm
    }
    
    //MARK: - CreateSubscriptionPreviewTaskVM
    
    static func createSubscribedPreviewTaskVM() -> TaskVM {
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let taskManager = TaskManager.createMockTaskManager()
        let profileManager = ProfileManager.createMockManager()
        let dateManager = DateManager.createPreviewManager()
        let playerManager = PlayerManager.createMockPlayerManager()
        let recorderManager = RecorderManager.createRecorderManager(dateManager: dateManager)
        let storageManager = StorageManager.createMockStorageManager()
        
        let task = UITaskModel(.initial(mockModel().model.value))
        
        let subscriptionManager = MockSubscriptionManager.createSubscribedManager()
        
        let vm = TaskVM(
            appearanceManager: appearanceManager,
            taskManager: taskManager,
            profileManager: profileManager,
            dateManager: dateManager,
            playerManager: playerManager,
            recorderManager: recorderManager,
            
            storageManager: storageManager,
            subscriptionManager: subscriptionManager,
            task: task,
        )
        
        return vm
    }
    
    private func createPaywallVM() async {
        paywallVM = await PaywallVM.createPaywallVM(subscriptionManager: subscriptionManager)
        
        paywallVM?.closePaywall = {
            self.paywallVM = nil
        }
    }
    
    //TODO: What's it?
    private func setUPViewModel() async {
        
        preSetTask()
        
        await setUpTime()
        await playerManager.setUpTotalTime(task: task)
        await checkCompletedTaskForToday()
        
        setUpColor()
    }
    
    private func preSetTask() {
        setUpRepeat()
        
        if let deadlineDate = task.deadline {
            deadLineDate = Date(timeIntervalSince1970: deadlineDate)
        }
    }
    
    func onAppear(colorScheme: ColorScheme) {
        backgroundColorForTask(colorScheme: colorScheme)
    }
    
    func disappear() {
        stopPlaying()
        showPaywall = false
    }
    
    private func setUpTime() async {
        sourseDateOfNotification = Date(timeIntervalSince1970: task.notificationDate)
        
        guard let date = await firstTimeCreateTask(task) else {
            notificationDate = createNotificationDateFromExistTask()
            dateHasBeenChanged = false
            return
        }
        
        newTask = true
        titleFocused = true
        notificationDate = date
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
        if showDatePicker {
            scrollToDate()
        } else {
            scrollToMainContent()
        }
        
        // telemetry
        telemetryAction(.taskAction(.selectDateButtonTapped))
    }
    
    func selectTimeButtonTapped() {
        showTimePicker.toggle()
        if showTimePicker {
            scrollToTime()
        } else {
            scrollToMainContent()
        }
        
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
            backgroundColor = appearanceManager.backgroundColor
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
        guard taskColor == .baseColor && backgroundColor == appearanceManager.backgroundColor else {
            return taskColor.color(for: colorScheme) == backgroundColor
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
            try await taskManager.saveTask(task)
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
        if newTask == true {
            return notificationDate.timeIntervalSince1970
        }
        
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
    
    //MARK: - Date and time
    private func notificationDateToText() -> LocalizedStringKey {
        dateManager.dateToString(for: notificationDate, useForWeekView: false)
    }
    
    private func deadlineToText() -> LocalizedStringKey {
        dateManager.dateForDeadline(for: deadLineDate)
    }
    
    //MARK: - First time check
    
    private func firstTimeCreateTask(_ task: UITaskModel) async -> Date? {
        if await !taskManager.tasks.contains(where: { $0.value.id == task.id }) {
            return Date(timeIntervalSince1970: task.notificationDate)
        }
        
        return nil
    }
    
    private func dateHasBeenSelected() {
        showDatePicker = false
        showTimePicker = false
        showDeadline = false
        
        scrollToMainContent()
    }
    
    private func checkTimeAfterSelected() {
        guard initing == false else {
            return
        }
        
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
    
    //MARK: - Check Complete Task
    
    func checkCompletedTaskForToday() async {
        taskCompletedforToday = await taskManager.checkCompletedTaskForToday(task: task)
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
        confirmationDialogIsPresented.toggle()
    }
    
    func deleteButtonTapped(deleteCompletely: Bool = false) async {
        do {
            try await taskManager.deleteTask(task: task, deleteCompletely: deleteCompletely)
            stopPlaying()
        } catch {
            //TODO: - Error
            print("Error deleting task")
        }
    }
    
    // MARK: - Playback
    
    func playButtonTapped() async {
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
    
    //MARK: - Stop Playing
    
    func stopPlaying() {
        if playerManager.isPlaying {
            playerManager.stopToPlay()
            
            // telemetry
            telemetryAction(.taskAction(.stopPlayingVoiceButtonTapped(.taskView)))
        }
    }
    
    //MARK: - Seek audio
    
    func seekAudio() {
        playerManager.seekAudio()
        
        // telemetry
        telemetryAction(.taskAction(.seekToTime))
    }
    
    func currentTimeString() -> String {
        let time = isPlaying || pause ? currentProgressTime : totalProgressTime
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    //MARK: - Load Total Time
    
    private func loadTotalTimeIfNeeded() async {
        guard totalProgressTime == 0 else { return }
        
        await playerManager.setUpTotalTime(task: task)
    }
    
    private func pauseAudio() {
        pause = true
        playerManager.pauseAudio()
    }
    
    private func resetAudioProgress() {
        playerManager.resetAudioProgress()
    }
    
    // MARK: - Recording
    func recordButtonTapped() async {
        guard await subscriptionManager.hasSubscription() else {
            await createPaywallVM()
            return
        }
        
        if isRecording {
            await stopRecord()
        } else {
            try? await startRecord()
        }
        
        // telemetry
        telemetryAction(.taskAction(.addVoiceButtonTapped))
    }
    
    func stopAfterCheck(_ newValue: Double?) async {
        guard let value = newValue, value >= 15.0 else { return }
        await stopRecord()
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
    
    //MARK: - Stop Record
    
    private func stopRecord() async {
        var hashOfAudio: String?
        
        if let audioURLString = recorderManager.stopRecording() {
            if let data = try? Data(contentsOf: audioURLString) {
                do {
                    hashOfAudio = try await taskManager.storeAudio(data)
                    task.audio = hashOfAudio
                } catch {
                    hashOfAudio = try? await taskManager.storeAudio(data)
                    //TODO: Add cache for case like this
                }
            }
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
    
    private func changeDisabledButton() {
        disabledButton.toggle()
    }
    
    //MARK: - Set Up Deadline
    
    func setUpDeadlineDate() {
        guard task.deadline != nil else {
            return
        }
        
        if !calendar.isDate(notificationDate, inSameDayAs: deadLineDate) {
            if repeatTask == .never {
                repeatTask = .daily
            }
        }
        
        deadlineDateSelected = true
        
        showDeadlineDates = false
        deadlineToggle = true
        
        scrollToMainContent()
    }
    
    //MARK: - Combined Date
    func combineDateWithNotificationTime(_ date: Date) -> Date {
        let calendar = Calendar.current
        
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        let time = calendar.dateComponents([.hour, .minute, .second], from: notificationDate)
        
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = time.hour
        components.minute = time.minute
        components.second = time.second
        
        return calendar.date(from: components) ?? date
    }
    
    
    //MARK: - Show deadline dates
    
    func showDedalineDatesButtonTapped() async {
        guard await subscriptionManager.hasSubscription() else {
            await createPaywallVM()
            
            //TODO: After user pay it has to be opened
            while paywallVM != nil  {
                try? await Task.sleep(for: .seconds(0.25))
                
                if await subscriptionManager.hasSubscription() {
                    showDeadlineDates = true
                    resettingDeadline = false
                    
                    scrollToDeadlineDates()
                }
            }
            
            return
        }
        
        if showDeadlineDates {
            showDeadlineDates = false
            
            if task.deadline == nil {
                deadlineToggle = false
            }
            
            scrollToMainContent()
        } else {
            showDeadlineDates = true
            resettingDeadline = false
            
            scrollToDeadlineDates()
        }
    }
    
    //MARK: - Deadline Toggle Logic
    
    func checkSubscriptionAfterToggle(_ newValue: Bool) async {
        
        // If false - invalidate deadline
        guard newValue else {
            showDeadlineDates = false
            task.deadline = nil
            deadlineDateSelected = false
            resettingDeadline = true
            deadLineDate = Date()
            return
        }
        
        guard !deadlineDateSelected else {
            return
        }
        
        // Check Subscription and wait update
        guard await subscriptionManager.hasSubscription() else {
            try? await Task.sleep(for: .seconds(0.3))
            
            await createPaywallVM()
            
            //TODO: After user pay it has to be opened
            while paywallVM != nil  {
                try? await Task.sleep(for: .seconds(0.3))
            }
            
            if await subscriptionManager.hasSubscription() {
                // If user bought - pen deadline dates
                showDeadlineDates = true
                deadlineToggle = true
                resettingDeadline = false
                
                scrollToDeadlineDates()
            } else {
                // If user close paywall
                deadlineToggle = false
            }
            
            return
        }
        
        showDeadlineDates = true
        resettingDeadline = false
        
        scrollToDeadlineDates()
    }
    
    //MARK: - Scroll to main content
    
    private func scrollToMainContent() {
        scrollId = mainSectionID
        anchor = .center
    }
    
    //MARK: - Scroll to date
    
    private func scrollToDate() {
        scrollId = dateSectionID
        anchor = .center
    }
    
    //MARK: - Scroll to time
    
    private func scrollToTime() {
        scrollId = timeSectionID
        anchor = .center
    }
    
    //MARK: - Scroll to deadline
    
    private func scrollToDeadlineDates() {
        scrollId = deadlineSectionID
        anchor = .center
    }
    
    //MARK: - Telemetry action
    
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
