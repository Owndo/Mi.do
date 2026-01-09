//
//  WeekVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import SwiftUI
import DateManager
import TaskManager
import AppearanceManager
import TelemetryManager
import Models

@Observable
public final class WeekVM: HashableNavigation {
    var appearanceManager: AppearanceManagerProtocol
    var dateManager: DateManagerProtocol
    var taskManager: TaskManagerProtocol
    var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
    }
    
    //MARK: - Create VM
    
    public static func createVM(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) -> WeekVM {
        WeekVM(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
    }
    
    
    //MARK: - Create PreviewVM
    
    public static func createPreviewVM() -> WeekVM {
        WeekVM(
            appearanceManager: AppearanceManager.createMockAppearanceManager(),
            dateManager: DateManager.createMockDateManager(),
            taskManager: TaskManager.createMockTaskManager()
        )
    }
    
    var selectedDayOfWeek = Date()
    
    var scaleEffect: CGFloat = 1
    
    var trigger = false {
        didSet {
            Task {
                scaleEffect = 1.2
                try? await Task.sleep(for: .seconds(0.3))
                scaleEffect = 1
            }
        }
    }
    
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
        if selectedDayIsToday() {
            trigger.toggle()
        }
        
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
        let symbols = calendar.shortWeekdaySymbols
        let weekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[weekdayIndex...] + symbols[..<weekdayIndex])
    }
    
    func dateToString() -> LocalizedStringKey {
        dateManager.dateToString(for: selectedDate, useForWeekView: true)
    }
    
    //MARK: Telemtry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
