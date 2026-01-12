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
    var appearanceManager: AppearanceManagerProtocol
    var dateManager: DateManagerProtocol
    var taskManager: TaskManagerProtocol
    
    private let telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    public var backToMainView: (() -> Void)?
    
    public var scrollID: Int? {
        didSet {
            findNameForMonth()
        }
    }
    
    //MARK: - UI State
    
    var viewStarted = false
    var navigationTitle = ""
    var navigationSubtitle = ""
    
    var imageForScrollBackButton = "chevron.up"
    
    var isScrolling = false
    var scrolledFromCurrentMonth = false
    
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
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
    }
    
    //MARK: - CreateMonthVM
    
    public static func createMonthVM(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) async -> CalendarVM {
        let vm = CalendarVM(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
        
        return vm
    }
    
    //MARK: - Create previewVm
    
    public static func createPreviewVM() -> CalendarVM {
        let vm = CalendarVM(appearanceManager: AppearanceManager.createMockAppearanceManager(), dateManager: DateManager.createMockDateManager(), taskManager: TaskManager.createMockTaskManager())
        
        return vm
    }
    
    //MARK: - On appear
    
    func onAppear() async {
        await dateManager.initializeMonth()
        jumpToSelectedMonth()
        
        try? await Task.sleep(for: .seconds(0.5))
        viewStarted = true
    }
    
    func onDissapear() {
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
        dateManager.selectedDateChange(today)
        await dateManager.initializeMonth()
        jumpToSelectedMonth()
        
        // telemetry
        telemetryAction(.calendarAction(.backToTodayButtonTapped(.calendarView)))
    }
    
    func backToSelectedDateButtonTapped() async {
        await dateManager.initializeMonth()
        viewStarted = false
        jumpToSelectedMonth()
        viewStarted = true
        scrolledFromCurrentMonth = false
    }
    
    func currentYear(_ month: PeriodModel) -> String? {
        guard let day = month.date.first else { return nil }
        return day.formatted(.dateTime.year())
    }
    
    func monthName(_ month: PeriodModel) -> String {
        guard let date = month.date.first else { return "" }
        
        return date.formatted(.dateTime.month(.abbreviated))
    }
    
    //MARK: - Back to MainView Button
    
    func backToMainViewButtonTapped() {
        backToMainView?()
        
        // telemetry
        telemetryAction(.calendarAction(.backToSelectedDateButtonTapped(.calendarView)))
    }
    
    //MARK: - Handle Month
    
    func handleMonthAppeared(_ month: PeriodModel) async {
        
        guard viewStarted else { return }
        
        if let first = allMonths.first, first == month {
            await dateManager.generatePreviousMonth()
        } else if let last = allMonths.last, last == month {
            await dateManager.generateFeatureMonth()
        }
    }
    
    func findNameForMonth() {
        guard let id = scrollID else { return }
        let month = allMonths.first(where: { $0.id == id })
        
        guard let month else { return }
        
        navigationTitle = month.name ?? ""
        navigationSubtitle = currentYear(month) ?? ""
        
        checkIfUserScrolledFromSelectedDate(month)
    }
    
    func checkIfUserScrolledFromSelectedDate(_ month: PeriodModel) {
        guard viewStarted else { return }
        
        guard !month.date.contains(where: { calendar.isDate($0, inSameDayAs: selectedDate)}) else {
            scrolledFromCurrentMonth = false
            return
        }
        
        scrolledFromCurrentMonth = true
        
        if let first = month.date.first, first > selectedDate {
            imageForScrollBackButton = "chevron.up"
        } else {
            imageForScrollBackButton = "chevron.down"
        }
    }
    
    func jumpToSelectedMonth() {
        scrollID = allMonths.first { $0.date.contains { calendar.isDate($0, inSameDayAs: selectedDate) }}?.id
    }
    
    //MARK: Telemtry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
