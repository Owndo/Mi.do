//
//  SegmentedCircleVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//
import Foundation
import Models
import Managers

@Observable
final class SegmentedCircleVM {
    @ObservationIgnored
    @Injected(\.taskManager) var taskManager
    @ObservationIgnored
    @Injected(\.dateManager) var dateManager
    @ObservationIgnored
    @Injected(\.casManager) var casManager
    
    var useTaskColors = true
    
    var currentDay: Date = Date()
    var tasksForToday: [MainModel] = []
    var isLoading = false
    
    var completedFlagsForToday: [Bool] {
        tasksForToday.map { task in
            guard let doneArray = task.value.done else { return false }
            return doneArray.contains { $0.completedFor == currentDay.timeIntervalSince1970 }
        }
    }
    
    var allTaskCompletedForToday: Bool {
        !tasksForToday.isEmpty && completedFlagsForToday.allSatisfy { $0 }
    }
    
    var updateWeek: Int {
        dateManager.indexForWeek
    }
    
    var updateTask: Bool {
        casManager.taskUpdateTrigger
    }
    
    init() {
        Task { [weak self] in
            await self?.updateTasks()
        }
    }
    
    func onAppear(date: Date) {
        currentDay = date
        Task {
            await updateTasks()
        }
    }
    
    @MainActor
    func updateTasks() async {
        var filteredTasks: [MainModel] = []
        
        let weekTasks = taskManager.thisWeekTasks
        
        for task in weekTasks {
            let isScheduled = task.value.isScheduledForDate(
                currentDay.timeIntervalSince1970,
                calendar: dateManager.calendar
            )
            if isScheduled {
                filteredTasks.append(task)
            }
        }
        
        tasksForToday = filteredTasks
    }
}
