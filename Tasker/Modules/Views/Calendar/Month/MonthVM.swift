//
//  MonthVM.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/9/25.
//

import Foundation
import Models
import Managers
import SwiftUI

@Observable
final class MonthVM {
    @ObservationIgnored
    @Injected(\.dateManager) var dateManager
    
    var scrollID: Int?
    
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    }
    
    var selectedDate: Date {
        dateManager.selectedDate
    }
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var today: Date {
        dateManager.currentTime
    }
    
    var allMonths: [PeriodModel] {
        dateManager.allMonths
    }
    
    func selectedDateChange(_ day: Date) {
        dateManager.selectedDateChange(day)
        dateManager.initializeWeek()
    }
    
    func onAppear() {
        dateManager.initializeMonth()
        scrollID = 1
    }
    
    func calculateEmptyDay(for month: PeriodModel) -> Int {
        guard let firstDate = month.date.first else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDate)
        
        let shift = (weekday - calendar.firstWeekday + 7) % 7
        return shift
    }
    
    func shiftedWeekdaySymbols() -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let weekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[weekdayIndex...] + symbols[..<weekdayIndex])
    }
    
    func isSameDay(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: today)
    }
    
    func isSelectedDay(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: selectedDate)
    }
    
    func selectedDayIsToday() -> Bool {
        dateManager.selectedDayIsToday()
    }
    
    func backToTodayButtonTapped() {
        dateManager.backToToday()
        scrollID = 1
        dateManager.initializeMonth()
    }
    
    func closeScreenButtonTapped(path: inout NavigationPath, mainViewIsOpen: inout Bool) {
        path.removeLast()
        mainViewIsOpen = true
    }
    
    func handleMonthAppeared(_ month: PeriodModel) {
        if let last = allMonths.last, month.id >= last.id - 5 {
            dateManager.appendMonthsForward()
        }
    }
}
