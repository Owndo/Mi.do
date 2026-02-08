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
    
    //    private var dayVMStore: DayVMStore
    
    private var dayVMs: [TimeInterval: DayViewVM] = [:]
    
    private var asyncStreamTask: Task<Void, Never>?
    
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
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
    }
    
    //MARK: - Create VM
    
    public static func createVM(
        appearanceManager: AppearanceManagerProtocol,
        dateManager: DateManagerProtocol,
        taskManager: TaskManagerProtocol,
    ) async -> WeekVM {
        let vm = WeekVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            taskManager: taskManager
        )
        await vm.updateCache()
        
        return vm
    }
    
    
    //MARK: - Create PreviewVM
    
    public static func createPreviewVM() -> WeekVM {
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let dateManager = DateManager.createPreviewManager()
        let taskManager = TaskManager.createMockTaskManager()
        //        let dayStore = DayVMStore.createPreviewStore(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
        
        let vm = WeekVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            taskManager: taskManager,
        )
        
        return vm
    }
    
    //MARK: - Sync Day VM
    
    @MainActor
    func syncDayVM(for day: Day) async {
        let key = dateManager.startOfDay(for: day.date).timeIntervalSince1970
        
        let vm = DayViewVM.createVM(dateManager: dateManager, taskManager: taskManager, appearanceManager: appearanceManager, day: day)
        dayVMs[key] = vm
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
    
    func dayIsToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: dateManager.currentTime)
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
    
    private func updateCache() async {
        asyncStreamTask = Task { [weak self] in
            guard let self else { return }
            
            async let updateCache: () = await streamListener()
            
            _ = await updateCache
            
        }
    }
    
    //MARK: - Stream listener
    
    func streamListener() async {
        guard let stream = await taskManager.updatedDayStream else { return }
        
        for await _ in stream {
            let week = dateManager.generateWeek(for: selectedDate)
            
            for day in week.days {
                await updateOneDayVM(day.date)
            }
            
            let validKeys = Set(week.days.map { $0.date.timeIntervalSince1970 })
            dayVMs = dayVMs.filter { validKeys.contains($0.key) }
        }
    }
    
    //MARK: - Update one dayVM
    
    private func updateOneDayVM(_ date: Date) async {
        let key = dateManager.startOfDay(for: date).timeIntervalSince1970
        
        guard let day = dayVMs[key] else { return }
        await day.updateTasks(update: true)
    }
}
