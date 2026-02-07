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
    
    private var dayVMStore: DayVMStore
    
    private var dayVMs: [TimeInterval: DayViewVM] = [:]
    
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
    
    var weeks: [Week] {
        dateManager.allWeeks
    }
    
    //MARK: - Private init
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol, dayVMStore: DayVMStore) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
        self.dayVMStore = dayVMStore
    }
    
    //MARK: - Create VM
    
    public static func createVM(
        appearanceManager: AppearanceManagerProtocol,
        dateManager: DateManagerProtocol,
        taskManager: TaskManagerProtocol,
        dayVMStore: DayVMStore
    ) async -> WeekVM {
        let vm = WeekVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            taskManager: taskManager,
            dayVMStore: dayVMStore
        )
        
        return vm
    }
    
    
    //MARK: - Create PreviewVM
    
    public static func createPreviewVM() -> WeekVM {
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let dateManager = DateManager.createPreviewManager()
        let taskManager = TaskManager.createMockTaskManager()
        let dayStore = DayVMStore.createPreviewStore(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
        
        let vm = WeekVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            taskManager: taskManager,
            dayVMStore: dayStore
        )
        
        return vm
    }
    
    // MARK: - Download Day VMs
    
    @MainActor
    func downloadDaysVMs() async {
        await dayVMStore.createWeekDayVMs()
    }
    
    //MARK: - Sync Day VM
    
    @MainActor
    func syncDayVM(for day: Day) async {
        let key = dateManager.startOfDay(for: day.date).timeIntervalSince1970
        if dayVMs[key] != nil { return }

        if let vm = await dayVMStore.returnDayVM(day) {
            dayVMs[key] = vm
        }
    }
    
    //MARK: - Return DayVM

    @MainActor
    func returnDayVM(_ day: Day) -> DayViewVM? {
        let key = dateManager.startOfDay(for: day.date).timeIntervalSince1970
        return dayVMs[key]
    }
    
    func selectedDateButtonTapped(_ day: Day) {
        dateManager.selectedDateChange(day.date)
        
        // telemetry
        telemetryAction(.calendarAction(.selectedDateButtonTapped(.mainView)))
    }
    
    //MARK: - Back to today
    
    func backToTodayButtonTapped() {
        guard !selectedDayIsToday() else {
            trigger.toggle()
            return
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
