//
//  CalendarVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/9/25.
//

import Foundation
import Models
import SwiftUI
import DateManager
import AppearanceManager
import TelemetryManager
import TaskManager

@Observable
public final class CalendarVM: HashableNavigation {
    var dateManager: DateManagerProtocol
    var appearanceManager: AppearanceManagerProtocol
    var taskManager: TaskManagerProtocol
    
    private let telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    public var backToMainView: (() -> Void)?
    
    public var scrollID: Int?
    
    var viewStarted = false
    
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
    
    private init(dateManager: DateManagerProtocol, appearanceManager: AppearanceManagerProtocol, taskManager: TaskManagerProtocol) {
        self.dateManager = dateManager
        self.appearanceManager = appearanceManager
        self.taskManager = taskManager
    }
    
    //MARK: - CreateMonthVM
    
    public static func createMonthVM(dateManager: DateManagerProtocol, appearanceManager: AppearanceManagerProtocol, taskManager: TaskManagerProtocol) async -> CalendarVM {
        let vm = CalendarVM(dateManager: dateManager, appearanceManager: appearanceManager, taskManager: taskManager)
        
        return vm
    }
    
    //MARK: - Create previewVm
    
    public static func createPreviewVM() -> CalendarVM {
        let vm = CalendarVM(dateManager: DateManager.createMockDateManager(), appearanceManager: AppearanceManager.createMockAppearanceManager(), taskManager: TaskManager.createMockTaskManager())
        
        
        return vm
    }
    
    //MARK: - On appear
    
    func onAppear() {
        if scrollID == nil {
            scrollID = 10
        }
        
        viewStarted = true
    }
    
    func onDissapear() {
        guard calendar.isDateInToday(selectedDate) else {
            viewStarted = false
            return
        }
        
        scrollID = nil
        viewStarted = false
    }
    
    //MARK: - Go to selected date button
    
    func selectedDateChange(_ day: Date) {
        dateManager.selectedDateChange(day)
        dateManager.initializeWeek()
        backToMainView?()
        
        // telemetry
        telemetryAction(.calendarAction(.selectedDateButtonTapped(.calendarView)))
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
        !dateManager.selectedDayIsToday()
    }
    
    func backToTodayButtonTapped() async {
        await MainActor.run {
            dateManager.selectedDateChange(today)
            scrollID = 10
        }
        
        // telemetry
        telemetryAction(.calendarAction(.backToTodayButtonTapped(.calendarView)))
    }
    
    func currentYear(_ month: PeriodModel) -> String? {
        let day = month.date.first!
        
        let year = calendar.component(.year, from: day)
        
        if year == calendar.component(.year, from: today) {
            return nil
        } else {
            return String(year)
        }
    }
    
    //MARK: - Back to MainView Button
    
    func backToMainViewButtonTapped() {
        backToMainView?()
        
        // telemetry
        telemetryAction(.calendarAction(.backToSelectedDateButtonTapped(.calendarView)))
    }
    
    func handleMonthAppeared(_ month: PeriodModel) {
        guard viewStarted else { return }

        guard let first = allMonths.first else { return }

        if month.id <= first.id + 2 {
            let anchorID = first.id
            scrollID = anchorID
            dateManager.generatePreviousMonth()
        }

        if let last = allMonths.last, month.id >= last.id - 1 {
            dateManager.appendMonthsForward()
        }
    }

    
    //MARK: Telemtry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
