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
    
    //MARK: - Properties
    var playingTask: TaskModel?
    var selectedTask: MainModel?
    
    //MARK: - UI States
    var taskDoneTrigger = false
    var taskDeleteTrigger = false
    var listRowHeight = CGFloat(52)
    var startPlay = false
    
    //MARK: Confirmation dialog
    var confirmationDialogIsPresented = false
    var messageForDelete = ""
    var singleTask = true
    
    //MARK: Computed Properties
    var playing: Bool {
        playerManager.isPlaying && playerManager.task?.id == playingTask?.id
    }
    
    //MARK: Private Properties
    
    //MARK: Selected task
    func selectedTaskButtonTapped(_ task: MainModel) {
        selectedTask = task
        stopToPlay()
    }
    
    //MARK: - Check Mark Function
    func checkCompletedTaskForToday(task: MainModel) -> Bool {
        taskManager.checkCompletedTaskForToday(task: task.value)
    }
    
    func checkMarkTapped(task: MainModel) {
        let model = taskManager.checkMarkTapped(task: task)
        taskDoneTrigger.toggle()
        stopToPlay()
        
        casManager.saveModel(model)
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
        let newModel = taskManager.deleteTask(task: task, deleteCompletely: deleteCompletely)
        taskDeleteTrigger.toggle()
        casManager.saveModel(newModel)
    }
    
    //MARK: Play sound function
    func playButtonTapped(task: MainModel) async {
        var data: Data?
        
        if let audio = task.value.audio {
            data = casManager.getData(audio)
            
            if !playing {
                if let data = data {
                    playingTask = task.value
                    await playerManager.playAudioFromData(data, task: task.value)
                }
            } else {
                stopToPlay()
            }
        } else {
            selectedTask = task
        }
    }
    
    private func stopToPlay() {
        playerManager.stopToPlay()
        playingTask = nil
    }
}
