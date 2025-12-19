//
//  SegmentedCircleVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//
import Foundation
import Models
import TaskManager
import DateManager
import AppearanceManager

@Observable
final class SegmentedCircleVM {
    var taskManager: TaskManagerProtocol
    var dateManager: DateManagerProtocol
    var appearanceManager: AppearanceManagerProtocol
    
    private init(taskManager: TaskManagerProtocol, dateManager: DateManagerProtocol, appearanceManager: AppearanceManagerProtocol) {
        self.taskManager = taskManager
        self.dateManager = dateManager
        self.appearanceManager = appearanceManager
    }
    
    static func createSegmentedCircleVM(taskManager: TaskManagerProtocol, dateManager: DateManagerProtocol, appearanceManager: AppearanceManagerProtocol)  -> SegmentedCircleVM {
        SegmentedCircleVM(taskManager: taskManager, dateManager: dateManager, appearanceManager: appearanceManager)
    }
    
    static func createPreview() -> SegmentedCircleVM {
        SegmentedCircleVM(taskManager: TaskManager.createMockTaskManager(), dateManager: DateManager.createMockDateManager(), appearanceManager: AppearanceManager.createMockAppearanceManager())
    }
    
    var useTaskColors: Bool {
        let minimal = appearanceManager.profileModel.settings.minimalProgressMode
                return !minimal
    }
    
    var completedFlags: [Bool] = []
    var allCompleted: Bool = false
    
    var currentDay: Date = Date()
    var tasksForToday: [UITaskModel] = []
    var isLoading = false
    
    var completedFlagsForToday: [Bool] {
        completedFlags
    }
    
    var allTaskCompletedForToday: Bool {
        allCompleted
    }
    
    var updateWeek: Int {
        dateManager.indexForWeek
    }
    
    var updateTask: Bool {
        //        casManager.taskUpdateTrigger
        true
    }
    
    func onAppear(date: Date) {
        currentDay = date
        
        Task {
            await updateTasks()
        }
    }
    
    @MainActor
    func updateTasks() async {
        isLoading = true
        
        let weekTasks = await taskManager.thisWeekTasks(date: currentDay.timeIntervalSince1970)
        
        let filtered = weekTasks.filter {
            $0.isScheduledForDate(currentDay.timeIntervalSince1970, calendar: dateManager.calendar)
        }
        
        let sorted = filtered.sorted { $0.notificationDate < $1.notificationDate }
        tasksForToday = sorted
        
        let timeKey = currentDay.timeIntervalSince1970
        
        completedFlags = sorted.map {
            $0.completeRecords.contains { $0.completedFor == timeKey }
        }
        
        allCompleted = !sorted.isEmpty && completedFlags.allSatisfy { $0 }
        
        isLoading = false
    }
}
