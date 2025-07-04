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
    
    var completedFlags: [Bool] = []
    var allCompleted: Bool = false
    
    var currentDay: Date = Date()
    var tasksForToday: [MainModel] = []
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
        isLoading = true

        let weekTasks = await taskManager.thisWeekTasks(date: currentDay.timeIntervalSince1970)

        let filtered = weekTasks.filter {
            $0.value.isScheduledForDate(currentDay.timeIntervalSince1970, calendar: dateManager.calendar)
        }

        let sorted = filtered.sorted { $0.value.notificationDate < $1.value.notificationDate }
        tasksForToday = sorted

        let timeKey = currentDay.timeIntervalSince1970
        
        completedFlags = sorted.map {
            $0.value.done.contains { $0.completedFor == timeKey }
        }

        allCompleted = !sorted.isEmpty && completedFlags.allSatisfy { $0 }

        isLoading = false
    }
}
