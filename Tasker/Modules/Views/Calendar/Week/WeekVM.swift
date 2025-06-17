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
    
    var selectedWeekDay: Int {
        calendar.component(.weekday, from: dateManager.selectedDate)
    }
    
    func selectedDateButtonTapped(_ day: Date) {
        dateManager.selectedDateChange(day)
    }
    
    func backToTodayButtonTapped() {
        dateManager.backToToday()
    }
    
    func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: dateManager.selectedDate)
    }
    
    func selectedDayIsToday() -> Bool {
        !calendar.isDate(selectedDate, inSameDayAs: today)
    }
    
    func isSelectedDayOfWeek(_ index: Int) -> Bool {
        return index == selectedWeekDay
    }
    
    func orderedWeekdaySymbols() -> [String] {
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday - 1
        
        let orderedSymbols = Array(weekdaySymbols[firstWeekday..<weekdaySymbols.count] + weekdaySymbols[0..<firstWeekday])
        
        return orderedSymbols
    }
    
    func dateToString() -> String {
        dateManager.dateToString(for: selectedDate, format: nil, useForWeekView: true)
    }
}
