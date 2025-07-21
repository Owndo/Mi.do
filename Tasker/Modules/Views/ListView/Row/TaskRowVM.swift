//
//  TaskRowVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/14/25.
//

import Foundation
import Managers
import Models

@Observable
final class TaskRowVM {
    //MARK: Dependecies
    @ObservationIgnored
    @Injected(\.playerManager) private var playerManager: PlayerManagerProtocol
    @ObservationIgnored
    @Injected(\.dateManager) private var dateManager: DateManagerProtocol
    @ObservationIgnored
    @Injected(\.casManager) private var casManager: CASManagerProtocol
    @ObservationIgnored
    @Injected(\.taskManager) private var taskManager: TaskManagerProtocol
    @ObservationIgnored
    @Injected(\.notificationManager) private var notificationManager: NotificationManagerProtocol
    @ObservationIgnored
    @Injected(\.telemetryManager) private var telemetryManager: TelemetryManagerProtocol
    
    //MARK: - Properties
    var playingTask: TaskModel?
    var selectedTask: MainModel?
    
    //MARK: - UI States
    var taskDoneTrigger = false
    var taskDeleteTrigger = false
    var listRowHeight = CGFloat(52)
    var startPlay = false
    var disabledScroll = false
    
    //MARK: Confirmation dialog
    var confirmationDialogIsPresented = false
    var messageForDelete = ""
    var singleTask = true
    
    //MARK: Computed Properties
    var playing: Bool {
        playerManager.isPlaying && playerManager.task?.id == playingTask?.id
    }
    
    //MARK: Private Properties
    private var currentTime: Date {
        dateManager.currentTime
    }
    
    func onAppear(task: MainModel) {
        if task.value.title.count < 25 {
            disabledScroll = true
        }
    }
    
    //MARK: Selected task
    func selectedTaskButtonTapped(_ task: MainModel) {
        selectedTask = task
        stopToPlay()
        
        // telemetry
        telemetryAction(.taskAction(.openTaskButtonTapped))
    }
    
    //MARK: - Check Mark Function
    func checkCompletedTaskForToday(task: MainModel) -> Bool {
        taskManager.checkCompletedTaskForToday(task: task.value)
    }
    
    func checkMarkTapped(task: MainModel) {
        Task {
            let model = task
            let task = taskManager.checkMarkTapped(task: model.value)
            
            taskDoneTrigger.toggle()
            stopToPlay()
            
            model.value = task
            
            casManager.saveModel(model)
            
            await notificationManager.createNotification()
        }
    }
    
    //MARK: - Delete functions
    func deleteTaskButtonSwiped(task: MainModel) {
        guard task.value.repeatTask == .never else {
            messageForDelete = "This's a recurring task."
            singleTask = false
            confirmationDialogIsPresented.toggle()
            return
        }
        
        messageForDelete = "Delete this task?"
        singleTask = true
        confirmationDialogIsPresented.toggle()
    }
    
    func deleteButtonTapped(task: MainModel, deleteCompletely: Bool = false) {
        Task {
            let newModel = taskManager.deleteTask(task: task, deleteCompletely: deleteCompletely)
            taskDeleteTrigger.toggle()
            casManager.saveModel(newModel)
            
            
            await notificationManager.createNotification()
        }
        
        if task.value.repeatTask == .never {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteSingleTask(.taskListView))))
        }
        
        if task.value.repeatTask != .never && deleteCompletely == true {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteAllTasks(.taskListView))))
        }
        
        if task.value.repeatTask != .never && deleteCompletely == false {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteOneOfManyTasks(.taskListView))))
        }
    }
    
    //MARK: Change date for overdue task
    func updateNotificationTimeForDueDateSwipped(task: MainModel) {
        let newModel = taskManager.updateNotificationTimeForDueDate(task: task)
        casManager.saveModel(newModel)
    }
    
    //MARK: Play sound function
    func playButtonTapped(task: MainModel) async {
        if !playing {
            playingTask = task.value
            await playerManager.playAudioFromData(task: task.value)
        } else {
            stopToPlay()
        }
        
        // telemetry
        telemetryAction(.taskAction(.playVoiceButtonTapped(.taskListView)))
    }
    
    private func stopToPlay() {
        playerManager.stopToPlay()
        playingTask = nil
        
        // telemetry
        telemetryAction(.taskAction(.stopPlayingVoiceButtonTapped(.taskListView)))
    }
    
    //MARK: - Telemetry manager
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
