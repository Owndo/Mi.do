//
//  ListVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/26/25.
//

import Foundation
import SwiftUI
import Models
import AppearanceManager
import DateManager
import TaskManager
import TelemetryManager
import TaskRowView
import NotificationManager
import ProfileManager

@Observable
public final class ListVM: HashableNavigation {
    
    //MARK: - Dependencies
    
    private var dateManager: DateManagerProtocol
    private var notificationManager: NotificationManagerProtocol
    private var taskManager: TaskManagerProtocol
    private let profileManager: ProfileManagerProtocol
    
    private var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    public var onTaskSelected: ((UITaskModel) -> Void)?
    
    //MARK: UI State
    
    var contentHeight: CGFloat = 0
    
    //MARK: Confirmation dialog
    var completedTasksHidden = false
    
    var tasksRowVM: [TaskRowVM] = []
    var completedTasksRowVM: [TaskRowVM] = []
    
    //MARK: - Private Init
    
    private init(dateManager: DateManagerProtocol, notificationManager: NotificationManagerProtocol, taskManager: TaskManagerProtocol, profileManager: ProfileManagerProtocol) {
        self.dateManager = dateManager
        self.notificationManager = notificationManager
        self.taskManager = taskManager
        self.profileManager = profileManager
    }
    
    //MARK: - Create ListVM
    
    public static func createListVM(dateManager: DateManagerProtocol, notificationManager: NotificationManagerProtocol, taskManager: TaskManagerProtocol, profileManager: ProfileManagerProtocol) async -> ListVM {
        let vm = ListVM(dateManager: dateManager, notificationManager: notificationManager, taskManager: taskManager, profileManager: profileManager)
        await vm.updateTasks()
        vm.completedTasksHidden = profileManager.profileModel.settings.completedTasksHidden
        vm.observeTasks()
        
        return vm
    }
    
    //MARK: - Create mock ListVM
    
    public static func creteMockListVM() -> ListVM {
            let taskManager = TaskManager.createMockTaskManager()
            let dateManager = DateManager.createMockDateManager()
            let notificationManager = MockNotificationManager()
            let profileManager = ProfileManager.createMockProfileManager()
            
            let vm = ListVM(dateManager: dateManager, notificationManager: notificationManager, taskManager: taskManager, profileManager: profileManager)
            vm.observeTasks()
            
            return vm
    }
    
    //MARK: - Create PreviewListVM
    
    public static func createPreviewListVM() async -> ListVM {
        let taskManager = await TaskManager.createMockTaskManagerWithModels()
        let dateManager = DateManager.createMockDateManager()
        let notificationManager = MockNotificationManager()
        let profileManager = ProfileManager.createMockProfileManager()
        
        let vm = ListVM(dateManager: dateManager, notificationManager: notificationManager, taskManager: taskManager, profileManager: profileManager)
        await vm.updateTasks()
        vm.observeTasks()
        
        return vm
    }
    
    
    //MARK: - Update tasks
    
    private func updateTasks() async {
        let active = await taskManager.activeTasks
        let completed = await taskManager.completedTasks
        
        tasksRowVM = await withTaskGroup(of: TaskRowVM.self) { group in
            for task in active {
                group.addTask {
                    await TaskRowVM.createTaskRowVM(
                        task: task,
                        dateManager: self.dateManager,
                        notificationManager: self.notificationManager,
                        taskManager: self.taskManager
                    )
                }
            }
            
            var result: [TaskRowVM] = []
            for await vm in group { result.append(vm) }
            return result
        }
        
        completedTasksRowVM = await withTaskGroup(of: TaskRowVM.self) { group in
            for task in completed {
                group.addTask {
                    await TaskRowVM.createTaskRowVM(
                        task: task,
                        dateManager: self.dateManager,
                        notificationManager: self.notificationManager,
                        taskManager: self.taskManager
                    )
                }
            }
            
            var result: [TaskRowVM] = []
            for await vm in group { result.append(vm) }
            return result
        }
    }
    
    private func observeTasks() {
        Task { [weak self] in
            guard let self else { return }
            
            for await _ in await taskManager.updates {
                await self.updateTasks()
            }
        }
    }
    
    //MARK: - Task tapped
    
    func taskTapped(_ task: UITaskModel) {
        onTaskSelected?(task)
    }
    
    func completedTaskViewChange() async {
        profileManager.profileModel.settings.completedTasksHidden.toggle()
        
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
    
    func heightOfList() -> CGFloat {
        CGFloat((tasksRowVM.count + completedTasksRowVM.count) * 52 + 170)
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
