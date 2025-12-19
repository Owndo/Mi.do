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

@Observable
final class DayViewVM {
    private let taskManager: TaskManagerProtocol
    private let dateManager: DateManagerProtocol
    
    var segmentedCircleVM: SegmentedCircleVM
    
    var showSmallFire = false
    var flameAnimation = false
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    private var tasks: [UITaskModel]?
    
    init(dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol, segmentedCircleVM: SegmentedCircleVM) {
        self.dateManager = dateManager
        self.taskManager = taskManager
        self.segmentedCircleVM = segmentedCircleVM
    }
    
    static func createPreviewVM() -> DayViewVM {
        let dateManager = DateManager.createMockDateManager()
        let taskManager = TaskManager.createMockTaskManager()
        let vm = DayViewVM(dateManager: dateManager, taskManager: taskManager, segmentedCircleVM: SegmentedCircleVM.createSegmentedCircleVM(taskManager: taskManager, dateManager: dateManager))
        
        return vm
    }
    
    static func createVM(dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) async -> DayViewVM {
        let vm = DayViewVM(dateManager: dateManager, taskManager: taskManager, segmentedCircleVM: SegmentedCircleVM.createSegmentedCircleVM(taskManager: taskManager, dateManager: dateManager))
        vm.tasks = await taskManager.tasks.map { $0.value }
        
        return vm
    }
    
    //MARK: - Deadline
    func lastDayForDeadline(_ day: Date) -> Bool {
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
    
    func isOverdue(day: Date) -> Bool {
        
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
}
