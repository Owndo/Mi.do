//
//  ListVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/26/25.
//

import AppearanceManager
import Foundation
import SwiftUI
import Models
import AppearanceManager
import DateManager
import PlayerManager
import ProfileManager
import TaskManager
import TaskView
import TelemetryManager
import NotificationManager
//For Preview
import RecorderManager
import StorageManager

@Observable
public final class ListVM: HashableNavigation {
    
    //MARK: - Dependencies
    private let appearanceManager: AppearanceManagerProtocol
    private var dateManager: DateManagerProtocol
    private var notificationManager: NotificationManagerProtocol
    private var playerManager: PlayerManagerProtocol
    private let profileManager: ProfileManagerProtocol
    private var taskManager: TaskManagerProtocol
    
    let recorderManager = RecorderManager.createMock()
    let storageManager = StorageManager.createMockStorageManager()
    
    private var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    var taskVM: TaskVM?
    
    var tasksVM: [TaskVM] = []
    
    //MARK: UI State
    
    /// For task Row
    var playingTask: UITaskModel?
    
    var showDeadlinePicker = false
    var taskDoneTrigger = false
    var deletTaskButtonTrigger = false
    var startPlay = false
    
    //MARK: Confirmation dialog
    
    var confirmationDialogIsPresented = false
    
    /// Show or hide completed tasks
    var completedTasksHidden = false
    
    //MARK: - Tasks
    
    var activeTasks: [UITaskModel] = []
    var completedTasks: [UITaskModel] = []
    
    /// ID for update ForEach inside the view
    var forEachID = UUID()
    
    var candidateForDeletion: UITaskModel?
    
    //MARK: - Async stream
    
    public var selectedTaskStream: AsyncStream<UITaskModel>?
    private var continuation: AsyncStream<UITaskModel>.Continuation?
    
    private var tasksTask: Task<Void, Never>?
    
    //MARK: - Computed properties
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var selectedDate: Date {
        dateManager.selectedDate
    }
    
    var playing: Bool {
        playerManager.isPlaying && playerManager.task?.id == playingTask?.id
    }
    
    
    //MARK: - Private Init
    
    private init(
        appearanceManager: AppearanceManagerProtocol,
        dateManager: DateManagerProtocol,
        notificationManager: NotificationManagerProtocol,
        playerManager: PlayerManagerProtocol,
        profileManager: ProfileManagerProtocol,
        taskManager: TaskManagerProtocol
    ) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.notificationManager = notificationManager
        self.playerManager = playerManager
        self.profileManager = profileManager
        self.taskManager = taskManager
    }
    
    //MARK: - Create ListVM
    
    public static func createListVM(
        appearanceManager: AppearanceManagerProtocol,
        dateManager: DateManagerProtocol,
        notificationManager: NotificationManagerProtocol,
        playerManager: PlayerManagerProtocol,
        profileManager: ProfileManagerProtocol,
        taskManager: TaskManagerProtocol
    ) async -> ListVM {
        let vm = ListVM(appearanceManager: appearanceManager, dateManager: dateManager, notificationManager: notificationManager, playerManager: playerManager, profileManager: profileManager, taskManager: taskManager)
        
        let (stream, cont) = AsyncStream<UITaskModel>.makeStream()
        vm.selectedTaskStream = stream
        vm.continuation = cont
        
        vm.completedTasksHidden = profileManager.profileModel.settings.completedTasksHidden
        await vm.downloadTasks()
        vm.asyncUpdateTasks()
        
        return vm
    }
    
    //MARK: - Create mock ListVM
    
    public static func creteMockListVM() -> ListVM {
        let appearanceManager = AppearanceManager.createEnvironmentManager()
        let dateManager = DateManager.createPreviewManager()
        let notificationManager = MockNotificationManager()
        let profileManager = ProfileManager.createMockManager()
        let playerManager = PlayerManager.createMockPlayerManager()
        let taskManager = TaskManager.createMockTaskManager()
        
        let vm = ListVM(appearanceManager: appearanceManager, dateManager: dateManager, notificationManager: notificationManager, playerManager: playerManager, profileManager: profileManager, taskManager: taskManager)
        
        return vm
    }
    
    //MARK: - Create PreviewListVM
    
    public static func createPreviewListVM() async -> ListVM {
        let appearanceManager = AppearanceManager.createEnvironmentManager()
        let dateManager = DateManager.createPreviewManager()
        let notificationManager = MockNotificationManager()
        let playerManager = PlayerManager.createMockPlayerManager()
        let profileManager = ProfileManager.createMockManager()
        let taskManager = await TaskManager.createMockTaskManagerWithModels()
        
        let vm = ListVM(appearanceManager: appearanceManager, dateManager: dateManager, notificationManager: notificationManager, playerManager: playerManager, profileManager: profileManager, taskManager: taskManager)
        
        return vm
    }
    
    func downloadTasks() async {
        await updateTasks()
    }
    
    //MARK: - Async Stream
    
    func asyncUpdateTasks() {
        tasksTask = Task { [weak self] in
            guard let self else { return }
            
            async let tasksStreamTask: () = listenTasksStream()
            async let dataStreamTask: () = listenDataStream()
            
            _ = await (tasksStreamTask, dataStreamTask)
        }
    }
    
    private func listenTasksStream() async {
        guard let stream = await taskManager.tasksStream else { return }
        for await _ in stream {
            await updateTasks()
        }
    }
    
    private func listenDataStream() async {
        for await _ in dateManager.dateStream {
            await updateTasks()
        }
    }
    
    @MainActor
    private func updateTasks() async {
        activeTasks = sortedTasks(tasks: await taskManager.activeTasks(for: selectedDate))
        
        completedTasks = sortedTasks(tasks: await taskManager.completedTasks(for: selectedDate))
        
        let tasks = [activeTasks, completedTasks].flatMap { $0 }
        
        for i in tasks {
            let taskVM = await TaskVM.createTaskVM(
                appearanceManager: appearanceManager,
                taskManager: taskManager,
                playerManager: playerManager,
                storageManager: storageManager,
                profileManager: profileManager,
                dateManager: dateManager,
                recorderManager: recorderManager,
                task: i
            )
            
            tasksVM.append(taskVM)
        }
        
        forEachID = UUID()
    }
    
    //MARK: - Sorted tasks
    
    private func sortedTasks(tasks: [UITaskModel]) -> [UITaskModel] {
        tasks.sorted {
            let hour1 = calendar.component(.hour, from: Date(timeIntervalSince1970: $0.notificationDate))
            let hour2 = calendar.component(.hour, from: Date(timeIntervalSince1970: $1.notificationDate))
            
            let minutes1 = calendar.component(.minute, from: Date(timeIntervalSince1970: $0.notificationDate))
            let minutes2 = calendar.component(.minute, from: Date(timeIntervalSince1970: $1.notificationDate))
            
            return (hour1, minutes1, $0.createDate) < (hour2, minutes2, $1.createDate)
        }
    }
    
    //MARK: - Task tapped
    
    func taskTapped(_ task: UITaskModel) {
        continuation?.yield(task)
    }
    
    func completedTaskViewChange() async {
        completedTasksHidden.toggle()
        profileManager.profileModel.settings.completedTasksHidden = completedTasksHidden
        
        do {
            try await profileManager.updateProfileModel()
            // telemetry
            if profileManager.profileModel.settings.completedTasksHidden {
                telemetryAction(.taskAction(.showCompletedButtonTapped))
            } else {
                telemetryAction(.taskAction(.hideCompletedButtonTapped))
            }
        } catch {
            print("Couldn't update profile")
        }
    }
    
    //MARK: - TaskRow
    
    //MARK: - Task title
    func taskTitle(task: UITaskModel) -> String {
        if task.title != "" {
            return task.title
        } else {
            return "New task"
        }
    }
    
    //MARK: - Check Mark Function
    
    func checkCompletedTaskForToday(task: UITaskModel) -> Bool {
        task.completeRecords.contains(where: { $0.completedFor == calendar.startOfDay(for: selectedDate).timeIntervalSince1970 })
    }
    
    //MARK: - Checkmark tapped
    
    public func checkMarkTapped(task: UITaskModel) async {
        do {
            taskDoneTrigger.toggle()
            try await taskManager.checkMarkTapped(task: task)
            stopToPlay()
        } catch {
            
        }
    }
    
    //MARK: - Delete functions
    
    func dialogBinding(for task: UITaskModel) -> Binding<Bool> {
        guard let candidateForDeletion else {
            return Binding(get:  { self.confirmationDialogIsPresented } , set: { _ in })
        }
        
        return Binding(
            get: { self.confirmationDialogIsPresented && candidateForDeletion.id == task.id },
            set: { newValue in self.confirmationDialogIsPresented = newValue }
        )
    }
    
    public func deleteTaskButtonSwiped(task: UITaskModel) {
        candidateForDeletion = task
        confirmationDialogIsPresented.toggle()
    }
    
    func deleteButtonTapped(task: UITaskModel, deleteCompletely: Bool = false) async {
        do {
            deletTaskButtonTrigger.toggle()
            try await taskManager.deleteTask(task: task, deleteCompletely: deleteCompletely)
        } catch {
            
        }
    }
    
    //MARK: Play sound function
    
    @MainActor
    func playButtonTapped(task: UITaskModel) async {
        guard playingTask != task else {
            stopToPlay()
            return
        }
        
        if !playing {
            playingTask = task
            await playerManager.playAudioFromData(task: task)
        } else {
            stopToPlay()
            playingTask = task
            await playerManager.playAudioFromData(task: task)
        }
        
        // telemetry
        telemetryAction(.taskAction(.playVoiceButtonTapped(.taskListView)))
    }
    
    //MARK: - Stop play
    
    private func stopToPlay() {
        if playerManager.isPlaying {
            playerManager.stopToPlay()
            playingTask = nil
            
            // telemetry
            telemetryAction(.taskAction(.stopPlayingVoiceButtonTapped(.taskListView)))
        }
    }
    
    func playButton(task: UITaskModel) -> Bool {
        playing == true && playingTask?.id == task.id
    }
    
    //MARK: - Deadline
    func showDedalineButtonTapped(task: UITaskModel) {
        guard isTaskHasDeadline(task: task) else {
            return
        }
        
        showDeadlinePicker.toggle()
    }
    
    //MARK: - Is task has deadline
    
    func isTaskHasDeadline(task: UITaskModel) -> Bool {
        guard task.deadline != nil else {
            return false
        }
        return true
    }
    
    //MARK: - Is task overdue
    
    func isTaskOverdue(task: UITaskModel) -> Bool {
        guard let endTimestamp = task.deadline,
              endTimestamp < dateManager.currentTime.timeIntervalSince1970 else {
            return false
        }
        
        if task.completeRecords.contains(where: { dateManager.calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: Date(timeIntervalSince1970: task.deadline!)) }) {
            return false
        }
        return true
    }
    
    func timeRemainingString(task: UITaskModel) -> String {
        guard !task.completeRecords.contains(where: { dateManager.calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: dateManager.selectedDate) }) else {
            return "Completed"
        }
        
        guard let endTimestamp = task.deadline,
              endTimestamp > dateManager.currentTime.timeIntervalSince1970 else {
            
            if task.completeRecords.contains(where: {
                dateManager.calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: Date(timeIntervalSince1970: task.deadline!)) &&
                dateManager.calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: dateManager.selectedDate) }) {
                return "Completed"
            }
            
            return "Overdue"
        }
        
        guard let lastDay = dayUntillDeadLine(task) else {
            return ""
        }
        
        return "\(lastDay) days left"
    }
    
    
    //MARK: Deadline logic
    
    public func dayUntillDeadLine(_ task: UITaskModel) -> Int? {
        guard task.deadline != nil else {
            return nil
        }
        
        guard task.repeatTask != .never else {
            return nil
        }
        
        let today = dateManager.currentTime
        let notificationDate = Date(timeIntervalSince1970: task.notificationDate)
        
        var day: Date
        var lastActualDay: Date
        
        if calendar.isDate(notificationDate, inSameDayAs: today) || notificationDate <= today {
            day = today
            lastActualDay = today
            
            while task.isScheduledForDate(day.timeIntervalSince1970, calendar: calendar) {
                lastActualDay = day
                
                if task.repeatTask == .weekly {
                    day = calendar.date(byAdding: .day, value: 7, to: day)!
                } else if task.repeatTask == .monthly {
                    day = calendar.date(byAdding: .month, value: 1, to: day)!
                } else if task.repeatTask == .yearly {
                    day = calendar.date(byAdding: .year, value: 1, to: day)!
                } else {
                    day = calendar.date(byAdding: .day, value: 1, to: day)!
                }
            }
            
            let difference = calendar.dateComponents([.day], from: today, to: lastActualDay)
            return difference.day ?? 0
            
        } else {
            day = notificationDate
            lastActualDay = notificationDate
            
            while task.isScheduledForDate(day.timeIntervalSince1970, calendar: calendar) {
                lastActualDay = day
                
                if task.repeatTask == .weekly {
                    day = calendar.date(byAdding: .day, value: 7, to: day)!
                } else if task.repeatTask == .monthly {
                    day = calendar.date(byAdding: .month, value: 1, to: day)!
                } else if task.repeatTask == .yearly {
                    day = calendar.date(byAdding: .year, value: 1, to: day)!
                } else {
                    day = calendar.date(byAdding: .day, value: 1, to: day)!
                }
            }
            
            let todayToNotification = calendar.dateComponents([.day], from: today, to: notificationDate)
            let notificationToLast = calendar.dateComponents([.day], from: notificationDate, to: lastActualDay)
            
            return (todayToNotification.day ?? 0) + (notificationToLast.day ?? 0)
        }
    }
    
    //MARK: - Empty Day
    
    public func emptyDay() -> Bool {
        if activeTasks.isEmpty && completedTasks.isEmpty {
            return true
        } else if (activeTasks.count + completedTasks.count) < 5 {
            return true
        } else {
            return false
        }
    }
    
    
    //MARK: - Date
    func backToTodayButtonTapped() {
        //        dateManager.backToToday()
        //        indexForList = 54
    }
    
    private func indexResetWithDate() -> Bool {
        //        dateManager.selectedDayIsToday()
        true
    }
    
    
    private func nextDaySwiped() {
        //        dateManager.addOneDay()
    }
    
    private func previousDaySwiped() {
        //        dateManager.subtractOneDay()
    }
    
    
    //MARK: - Telemetry action
    private func telemetryAction(_ action: EventType) {
        //        telemetryManager.logEvent(action)
    }
}
