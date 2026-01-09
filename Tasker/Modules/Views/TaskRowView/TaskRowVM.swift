//
//  TaskRowVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/14/25.
//

import Foundation
import Models
import SwiftUI
import DateManager
import NotificationManager
import PlayerManager
import TaskManager
import TelemetryManager

@Observable
public final class TaskRowVM: HashableObject {
    //MARK: Dependecies
    private var dateManager: DateManagerProtocol
    private var notificationManager: NotificationManagerProtocol
    private var playerManager: PlayerManagerProtocol
    private var taskManager: TaskManagerProtocol
    
    private var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    //MARK: - Properties
    
    var playingTask: UITaskModel?
    var selectedTask: UITaskModel?
    
    public var task: UITaskModel
    
    var taskTitle: String {
        if task.title != "" {
            return task.title
        } else {
            return "New task"
        }
    }
    
    //MARK: - UI States
    
    var taskDoneTrigger = false
    var taskDeleteTrigger = false
    var listRowHeight = CGFloat(52)
    var startPlay = false
    var disabledScroll = false
    var showDeadlinePicker = false
    
    var completedForToday = false
    
    var timeRemainingString: LocalizedStringKey = ""
    
    //MARK: Confirmation dialog
    
    var confirmationDialogIsPresented = false
    var messageForDelete: LocalizedStringKey = ""
    var singleTask = true
    
    //MARK: Computed Properties
    var playing: Bool {
        playerManager.isPlaying && playerManager.task?.id == playingTask?.id
    }
    
    //MARK: Private Properties
    
    private var currentTime: Date {
        dateManager.currentTime
    }
    
    //MARK: - Private init
    
    private init(task: UITaskModel, dateManager: DateManagerProtocol, notificationManager: NotificationManagerProtocol, taskManager: TaskManagerProtocol, playerManager: PlayerManagerProtocol) {
        self.task = task
        self.dateManager = dateManager
        self.notificationManager = notificationManager
        self.taskManager = taskManager
        self.playerManager = playerManager
    }
    
    //MARK: - Create TaskRowVm
    
    public static func createTaskRowVM(task: UITaskModel, dateManager: DateManagerProtocol, notificationManager: NotificationManagerProtocol, taskManager: TaskManagerProtocol) async -> TaskRowVM {
        let playerManager = await PlayerManager.createPlayerManager()
        let vm = TaskRowVM(task: task, dateManager: dateManager, notificationManager: notificationManager, taskManager: taskManager, playerManager: playerManager)
        await vm.timeRemainingString()
        await vm.checkCompletedTaskForToday()
        
        return vm
    }
    
    //MARK: - Create Preview TaskRowVM
    
    public static func createPreviewTaskRowVM(task: UITaskModel) -> TaskRowVM {
        let dateManager = DateManager.createMockDateManager()
        let notificationManager = MockNotificationManager()
        let taskManager = TaskManager.createMockTaskManager()
        let playerManager = PlayerManager.createMockPlayerManager()
        return TaskRowVM(task: task, dateManager: dateManager, notificationManager: notificationManager, taskManager: taskManager, playerManager: playerManager)
    }
    
    func onAppear(task: UITaskModel) {
        if task.title.count < 20 {
            disabledScroll = true
        }
    }
    
    //MARK: Selected task
    func selectedTaskButtonTapped() {
        //        taskVM = TaskVM(mainModel: task)
        stopToPlay()
        
        // telemetry
        telemetryAction(.taskAction(.openTaskButtonTapped(.list)))
    }
    
    //MARK: - Check Mark Function
    func checkCompletedTaskForToday() async {
        completedForToday = await taskManager.checkCompletedTaskForToday(task: task)
    }
    
    public func checkMarkTapped() async {
        do {
            try await taskManager.checkMarkTapped(task: task)
            stopToPlay()
        } catch {
            
        }
    }
    
    //MARK: - Delete functions
    public func deleteTaskButtonSwiped() {
        guard task.repeatTask == .never else {
            messageForDelete = "This's a recurring task."
            singleTask = false
            confirmationDialogIsPresented.toggle()
            return
        }
        
        messageForDelete = "Delete task?"
        singleTask = true
        confirmationDialogIsPresented.toggle()
    }
    
    func deleteButtonTapped(deleteCompletely: Bool = false) async {
        do {
            try await taskManager.deleteTask(task: task, deleteCompletely: deleteCompletely)
            taskDeleteTrigger.toggle()
        } catch {
            
        }
    }
    
    //MARK: - Deadline
    func showDedalineButtonTapped() {
        guard isTaskHasDeadline() else {
            return
        }
        showDeadlinePicker.toggle()
    }
    
    func isTaskHasDeadline() -> Bool {
        guard task.deadline != nil else {
            return false
        }
        return true
    }
    
    func isTaskOverdue() -> Bool {
        guard let endTimestamp = task.deadline,
              endTimestamp < dateManager.currentTime.timeIntervalSince1970 else {
            return false
        }
        
        if task.completeRecords.contains(where: { dateManager.calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: Date(timeIntervalSince1970: task.deadline!)) }) {
            return false
        }
        return true
    }
    
    func timeRemainingString() async {
        guard !task.completeRecords.contains(where: { dateManager.calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: dateManager.selectedDate) }) else {
            
            timeRemainingString = "Completed"
            return
        }
        
        guard let endTimestamp = task.deadline,
              endTimestamp > dateManager.currentTime.timeIntervalSince1970 else {
            
            if task.completeRecords.contains(where: {
                dateManager.calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: Date(timeIntervalSince1970: task.deadline!)) &&
                dateManager.calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: dateManager.selectedDate) }) {
                timeRemainingString = "Completed"
            }
            
            timeRemainingString = "Overdue"
            return
        }
        
        guard let lastDay = await taskManager.dayUntillDeadLine(task) else {
            return
        }
        
        timeRemainingString = "\(lastDay) days left"
    }
    
    //MARK: Change date for overdue task
    
    //    func updateNotificationTimeForDueDateSwipped(task: UITaskModel) async {
    //        let newModel = await taskManager.updateNotificationTimeForDueDate(task: task)
    //        //        casManager.saveModel(newModel)
    //    }
    
    //MARK: Play sound function
    
    func playButtonTapped() async {
        if !playing {
            playingTask = task
            await playerManager.playAudioFromData(task: task)
        } else {
            stopToPlay()
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
    
    //MARK: - Telemetry manager
    
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}

public protocol HashableObject: AnyObject, Hashable {}

extension HashableObject {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
