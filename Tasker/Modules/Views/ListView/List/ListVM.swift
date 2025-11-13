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
//import TaskView

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
//    var taskVM: TaskVM?
    
    //MARK: UI State
    // TODO: - Until best days
//    var indexForList: Int = 54 {
//        didSet {
//            if oldValue < indexForList {
//                withAnimation {
//                    nextDaySwiped()
//                }
//            } else {
//                withAnimation {
//                    previousDaySwiped()
//                }
//            }
//            if oldValue >= indexes.last! - 10 {
//                indexForList = 54
//            } else if oldValue <= indexes.first! + 10 {
//                indexForList = 54
//            }
//        }
//    }
//    var indexes = Array(0...99)
    
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
    
    public init() {
//        completedTasksHidden = casManager.profileModel.settings.completedTasksHidden
    }
    
    func taskTapped(_ task: MainModel) {
        onTaskSelected?(task)
    }
    
    //MARK: - Complete task
    func checkMarkTapped(_ task: MainModel) async {
        do {
            try await taskManager.checkMarkTapped(task: task)
        } catch {
            //TODO: - Error
        }
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
    
    func deleteButtonTapped(task: MainModel, deleteCompletely: Bool = false) async {
        do {
            try await taskManager.deleteTask(task: task, deleteCompletely: deleteCompletely)
        } catch {
            //TODO: - Error
        }
    }
    
    func dialogBinding(for task: MainModel) -> Binding<Bool> {
        Binding(
            get: { self.confirmationDialogIsPresented && self.taskForDeleted.id == task.id },
            set: { newValue in self.confirmationDialogIsPresented = newValue }
        )
    }
    
    func completedTaskViewChange() {
//        let model = casManager.profileModel
        completedTasksHidden.toggle()
//        model.settings.completedTasksHidden = completedTasksHidden
        
//        casManager.saveProfileData(model)
        
        // telemetry
//        if model.settings.completedTasksHidden {
//            telemetryAction(.taskAction(.showCompletedButtonTapped))
//        } else {
//            telemetryAction(.taskAction(.hideCompletedButtonTapped))
//        }
    }
    
    func heightOfList() -> CGFloat {
        CGFloat((tasks.count + completedTasks.count) * 52 + 170)
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
