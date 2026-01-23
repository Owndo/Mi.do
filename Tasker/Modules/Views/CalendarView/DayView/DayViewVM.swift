//
//  DayViewVM.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 8/9/25.
//

import Foundation
import Models
import DateManager
import TaskManager
import AppearanceManager

@Observable
final class DayViewVM: HashableNavigation {
    let appearanceManager: AppearanceManagerProtocol
    private let taskManager: TaskManagerProtocol
    private let dateManager: DateManagerProtocol
    
    var day: Date
    
    var showSmallFire = false
    var flameAnimation = false
    
    /// For segmented view
    var segmentedTasks: [SegmentedTask] = []
    
    private var isLoading = false
    
    /// Flag in case we already download the tasks
    var hasLoaded = false
    
    var completedFlags: [Bool] = []
    var allCompleted: Bool = false
    
    //MARK: - States for SegmentedView
    
    var segmentProgress: Double = 0.0
    
    let center = CGPoint(x: 18, y: 18)
    let radius: CGFloat = 18
    let gapAngle: Double = 20.0
    
    var completedFlagsForToday: [Bool] {
        completedFlags
    }
    
    ///Property for segmented's color
    var useTaskColors: Bool {
        appearanceManager.profileModel.settings.minimalProgressMode
    }
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    private var tasks: [UITaskModel]?
    
    //MARK: - Private init
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol, day: Date) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
        self.day = day
    }
    
    //MARK: - Create VM
    
    static func createVM(dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol, appearanceManager: AppearanceManagerProtocol, day: Date) -> DayViewVM {
        let vm = DayViewVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            taskManager: taskManager,
            day: day
        )
        
        //        vm.tasks = await taskManager.tasks.map { $0.value }
        
        return vm
    }
    
    //MARK: - Create Preview
    
    static func createPreviewVM() -> DayViewVM {
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let dateManager = DateManager.createPreviewManager()
        let taskManager = TaskManager.createMockTaskManager()
        let day = Date()
        
        let vm = DayViewVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            taskManager: taskManager,
            day: day
        )
        
        return vm
    }
    
    
    func isDateInToday() -> Bool {
        calendar.isDate(day, inSameDayAs: Date())
    }
    
    //MARK: - Deadline
    
    func lastDayForDeadline() -> Bool {
        guard let tasks else {
            return false
        }
        
        for i in tasks {
            guard let endDate = i.deadline else {
                continue
            }
            
            if i.completeRecords.contains(where: { calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: day) }) {
                return false
            }
            
            if i.deleteRecords.contains(where: { calendar.isDate(Date(timeIntervalSince1970: $0.deletedFor), inSameDayAs: day) }) {
                return false
            }
            
            if calendar.isDate(Date(timeIntervalSince1970: endDate), inSameDayAs: day) {
                return true
            }
        }
        
        return false
    }
    
    //MARK: - IsOverdue
    
    func isOverdue() -> Bool {
        
        guard let tasks else {
            return false
        }
        
        let today = Date()
        
        for task in tasks {
            guard let endDate = task.deadline else {
                continue
            }
            
            let deadlineDate = Date(timeIntervalSince1970: endDate)
            
            if calendar.isDate(day, inSameDayAs: deadlineDate) && today > day {
                return true
            }
        }
        
        return false
    }
    
    //MARK: - Segmented Circle
    
    @MainActor
    func updateTasks(update: Bool = false) async {
        if update == true {
            hasLoaded = false
        }
        
        guard !hasLoaded else {
            return
        }
        
        defer {
            hasLoaded = true
        }

        let tasks = await taskManager.retrieveDayTasks(for: day)
            .sorted { $0.notificationDate < $1.notificationDate }

        let timeKey = day.timeIntervalSince1970

        segmentedTasks = tasks.map {
            SegmentedTask(
                id: $0.id,
                task: $0,
                isCompleted: $0.completeRecords.contains { $0.completedFor == timeKey }
            )
        }

        allCompleted = !segmentedTasks.isEmpty &&
                       segmentedTasks.allSatisfy { $0.isCompleted }
    }
}

struct SegmentedTask: Identifiable, Equatable {
    let id: String
    let task: UITaskModel
    let isCompleted: Bool
}
