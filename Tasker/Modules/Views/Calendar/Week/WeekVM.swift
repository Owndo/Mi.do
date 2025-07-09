//
//  WeekVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import SwiftUI
import Managers
import Models

@Observable
final class WeekVM {
    @ObservationIgnored
    @Injected(\.dateManager) var dateManager: DateManagerProtocol
    
    var selectedDayOfWeek = Date()
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var selectedDate: Date {
        dateManager.selectedDate
    }
    
    var today: Date {
        dateManager.currentTime
    }
    
    var indexForWeek: Int {
        dateManager.indexForWeek
    }
    
    var weeks: [PeriodModel] {
        dateManager.allWeeks
    }
    
    func selectedDateButtonTapped(_ day: Date) {
        dateManager.selectedDateChange(day)
        selectedDayOfWeek = day
    }
    
    func backToTodayButtonTapped() {
        dateManager.backToToday()
    }
    
    func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: dateManager.selectedDate)
    }
    
    func selectedDayIsToday() -> Bool {
        dateManager.selectedDayIsToday()
    }
    
    func isSelectedDayOfWeek(_ index: Int) -> Bool {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let firstWeekday = calendar.firstWeekday
        
        let adjustedWeekday = (weekday - firstWeekday + 7) % 7
        
        return index == adjustedWeekday
    }
    
    func orderedWeekdaySymbols() -> [String] {
        if calendar.firstWeekday == 2 {
            return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        } else {
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }
    }
    
    func dateToString() -> String {
        dateManager.dateToString(for: selectedDate, format: nil, useForWeekView: true)
    }
}
