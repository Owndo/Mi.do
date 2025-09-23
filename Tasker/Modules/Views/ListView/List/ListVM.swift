//
//  ListVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/26/25.
//

import Foundation
import SwiftUI
import Models
import Managers
import TaskView

@Observable
public final class ListVM {
    @ObservationIgnored
    @Injected(\.casManager) private var casManager: CASManagerProtocol
    @ObservationIgnored
    @Injected(\.dateManager) private var dateManager: DateManagerProtocol
    @ObservationIgnored
    @Injected(\.playerManager) private var playerManager: PlayerManagerProtocol
    @ObservationIgnored
    @Injected(\.taskManager) private var taskManager: TaskManagerProtocol
    @ObservationIgnored
    @Injected(\.appearanceManager) private var appearanceManager: AppearanceManagerProtocol
    @ObservationIgnored
    @Injected(\.telemetryManager) private var telemetryManager: TelemetryManagerProtocol
    @ObservationIgnored
    @Injected(\.onboardingManager) var onboardingManager: OnboardingManagerProtocol
    
    public var onTaskSelected: ((MainModel) -> Void)?
    var taskForDeleted: MainModel = mockModel()
    var taskVM: TaskVM?
    
    //MARK: UI State
    var showDeleteDialog = false
    var contentHeight: CGFloat = 0
    
    //MARK: Confirmation dialog
    var taskForConfirmation: MainModel?
    var confirmationDialogIsPresented = false
    var messageForDelete: LocalizedStringKey = ""
    var singleTask = true
    
    var completedTasksHidden = false
    
    var tasks: [MainModel] {
        taskManager.activeTasks
    }
    
    var completedTasks: [MainModel] {
        taskManager.completedTasks
    }
    
    private var calendar: Calendar {
        dateManager.calendar
    }
    
    private var selectedDate: Double {
        calendar.startOfDay(for: dateManager.selectedDate).timeIntervalSince1970
    }
    
    public init() {
        completedTasksHidden = casManager.profileModel.settings.completedTasksHidden
    }
    
    func taskTapped(_ task: MainModel) {
        onTaskSelected?(task)
    }
    
    //MARK: - Complete task
    func checkMarkTapped(_ task: MainModel) {
            let task = taskManager.checkMarkTapped(task: task)
            
            taskManager.saveTask(task)
    }
    
    //MARK: - Delete functions
    func deleteTaskButtonSwiped(task: MainModel) {
        taskForDeleted = task
        
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
    
    func deleteButtonTapped(task: MainModel, deleteCompletely: Bool = false) {
//        Task {
            taskManager.deleteTask(task: task, deleteCompletely: deleteCompletely)
//            taskDeleteTrigger.toggle()
            
            
//            await notificationManager.createNotification()
//        }
        
        if task.repeatTask == .never {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteSingleTask(.taskListView))))
        }
        
        if task.repeatTask != .never && deleteCompletely == true {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteAllTasks(.taskListView))))
        }
        
        if task.repeatTask != .never && deleteCompletely == false {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteOneOfManyTasks(.taskListView))))
        }
    }
    
    func dialogBinding(for task: MainModel) -> Binding<Bool> {
        Binding(
            get: { self.confirmationDialogIsPresented && self.taskForDeleted.id == task.id },
            set: { newValue in self.confirmationDialogIsPresented = newValue }
        )
    }
    
    //MARK: - Check for visible
    func backToTodayButtonTapped() {
        dateManager.backToToday()
    }
    
    func nextDaySwiped() {
        dateManager.addOneDay()
    }
    
    func previousDaySwiped() {
        dateManager.subtractOneDay()
    }
    
    func completedTaskViewChange() {
        let model = casManager.profileModel
        completedTasksHidden.toggle()
        model.settings.completedTasksHidden = completedTasksHidden
        
        casManager.saveProfileData(model)
        
        // telemetry
        if model.settings.completedTasksHidden {
            telemetryAction(.taskAction(.showCompletedButtonTapped))
        } else {
            telemetryAction(.taskAction(.hideCompletedButtonTapped))
        }
    }
    
    //MARK: - Telemetry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
