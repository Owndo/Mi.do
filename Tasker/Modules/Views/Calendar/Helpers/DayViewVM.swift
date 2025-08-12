//
//  DayViewVM.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 8/9/25.
//

import Foundation
import Managers

@Observable
final class DayViewVM {
    @ObservationIgnored
    @Injected(\.casManager) var casManager
    @ObservationIgnored
    @Injected(\.dateManager) var dateManager
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var showSmallFire = false
    var flameAnimation = false
    
    //MARK: - Deadline
    func lastDayForDeadline(_ day: Date) -> Bool {
        let tasks = casManager.models.values
        
        for i in tasks {
            guard let endDate = i.deadline else {
                continue
            }
            
            if i.done.contains(where: { calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: day) }) {
                return false
            }
            
            if calendar.isDate(Date(timeIntervalSince1970: endDate), inSameDayAs: day) {
                return true
            }
        }
        
        return false
    }
    
    func isOverdue(day: Date) -> Bool {
        let tasks = casManager.models.values
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
