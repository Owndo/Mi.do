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
    @ObservationIgnored
    @Injected(\.telemetryManager) var telemetryManager: TelemetryManagerProtocol
    
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
        
        // telemetry
        telemetryAction(.calendarAction(.selectedDateButtonTapped(.mainView)))
    }
    
    func backToTodayButtonTapped() {
        dateManager.backToToday()
        
        // telemetry
        telemetryAction(.calendarAction(.backToTodayButtonTapped(.mainView)))
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
        let symbols = calendar.veryShortWeekdaySymbols
        let weekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[weekdayIndex...] + symbols[..<weekdayIndex])
    }
    
    func dateToString() -> LocalizedStringKey {
        dateManager.dateToString(for: selectedDate, format: nil, useForWeekView: true)
    }
    
    //MARK: Telemtry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
