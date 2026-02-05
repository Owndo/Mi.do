//
//  MonthsViewVM.swift
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
public class MonthsViewVM: HashableNavigation {
    
    var appearanceManager: AppearanceManagerProtocol
    var dateManager: DateManagerProtocol
    var taskManager: TaskManagerProtocol
    
    private var dayVMStore: DayVMStore
    
    var ableToDownloadTasksColors = false
    
    private let telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    var dayVMs: [TimeInterval: DayViewVM] = [:]
    
    public var backToMainView: (() -> Void)?
    
    //MARK: - Scroll
    
    private var _scrollPositionStorage: Any?
    
    @available(iOS 18, *)
    var scrollPosition: ScrollPosition {
        get {
            if let value = _scrollPositionStorage as? ScrollPosition {
                return value
            }
            let initial = ScrollPosition()
            _scrollPositionStorage = initial
            return initial
        }
        set {
            _scrollPositionStorage = newValue
        }
    }
    
    var scrollID: String?
    var scrollAnchor: UnitPoint = .top
    
    var isScrolling = false
    var monthHeight: CGFloat = 500
    
    var imageForScrollBackButton = "chevron.up"
    var scrolledFromCurrentMonth = false
    
    var isLoadingTop = false
    var isLoadingBottom = false
    var isResetting: Bool = true
    
    //MARK: - UI State
    
    var viewStarted = false
    
    var currentYear: String?
    //    var navigationTitle = ""
    //    var navigationSubtitle = ""
    
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
    
    var allMonths: [Month] = []
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol, dayVMStore: DayVMStore) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
        self.dayVMStore = dayVMStore
    }
    
    //MARK: - CreateMonthVM
    
    public static func createMonthVM(
        appearanceManager: AppearanceManagerProtocol,
        dateManager: DateManagerProtocol,
        taskManager: TaskManagerProtocol,
        dayVMStore: DayVMStore
    ) async -> MonthsViewVM {
        let vm = MonthsViewVM(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager, dayVMStore: dayVMStore)
        
        return vm
    }
    
    //MARK: - Create previewVm
    
    public static func createPreviewVM() -> MonthsViewVM {
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let dateManager = DateManager.createPreviewManager()
        let taskManager = TaskManager.createMockTaskManager()
        let dayStore = DayVMStore.createPreviewStore(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
        
        let vm = MonthsViewVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            taskManager: taskManager,
            dayVMStore: dayStore
        )
        
        return vm
    }
    
    //MARK: - Start VM
    
    public func startVM() {
        allMonths = dateManager.initializeMonth()
        //        await downloadDaysVMs()
    }
    
    func endVM() {
        viewStarted = false
        allMonths.removeAll()
    }
    
    //MARK: - Go to selected date button
    
    func selectedDateChange(_ day: Date) {
        dateManager.selectedDateChange(day)
        dateManager.initializeWeek()
        
        backToMainView?()
        
        // telemetry
        telemetryAction(.calendarAction(.selectedDateButtonTapped(.calendarView)))
    }
    
    func shiftedWeekdaySymbols() -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let weekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[weekdayIndex...] + symbols[..<weekdayIndex])
    }
    
    func isSelectedDay(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: selectedDate)
    }
    
    func selectedDayIsToday() -> Bool {
        !dateManager.selectedDayIsToday()
    }
    
    //MARK: - Back to today Button
    
    func backToTodayButtonTapped() async {
        dateManager.backToToday()
        
        await jumpToSelectedMonth()
        
        // telemetry
        telemetryAction(.calendarAction(.backToTodayButtonTapped(.calendarView)))
    }
    
    //MARK: - Text for Back Button
    
    func backToSelectedDayButtonText() -> String {
        let currentYear = calendar.component(.year, from: Date())
        let selectedYear = calendar.component(.year, from: selectedDate)
        
        if selectedYear == currentYear {
            return selectedDate.formatted(.dateTime.month().day())
        } else {
            return selectedDate.formatted(.dateTime.month().day().year())
        }
    }
    
    //MARK: - Back to month
    
    var scrollDisabled = false
    
    func backToSelectedMonthButtonTapped() async {
        scrollDisabled = true
        
        if #available(iOS 18, *) {
            if let id = allMonths.first(where: { calendar.isDate($0.date, inSameDayAs: dateManager.startOfMonth(for: selectedDate))})?.id {
                scrollPosition.scrollTo(id: id, anchor: .top)
                scrolledFromCurrentMonth = false
            } else {
                allMonths = dateManager.initializeMonth()
                await jumpToSelectedMonth18iOS()
                scrolledFromCurrentMonth = false
            }
        } else {
            await jumpToSelectedMonth()
            scrolledFromCurrentMonth = false
        }
        
        scrollDisabled = false
    }
    
    //MARK: - Back to MainView Button
    
    func backToMainViewButtonTapped() {
        self.endVM()
        backToMainView?()
        
        // telemetry
        telemetryAction(.calendarAction(.backToSelectedDateButtonTapped(.calendarView)))
    }
    
    //MARK: - Handle Month
    
    @MainActor
    func handleMonthAppeared(month: Month) {
        guard viewStarted else {
            return
        }
        
        if allMonths[1] == month {
            loadPastMonth()
        } else if allMonths.last == month {
            loadPastMonth()
        }
    }
    
    //MARK: - Load past
    
    func loadPastMonth() {
        isLoadingTop = true
        
        let month = dateManager.generatePreviousMonth(for: allMonths.first!.date)
        allMonths.insert(month, at: 0)
        
        DispatchQueue.main.async {
            self.isLoadingTop = false
        }
    }
    
    //MARK: - Load Future
    
    func loadFutureMonth() {
        isLoadingBottom = true
        
        let month = dateManager.generateFeatureMonths(for: allMonths.last!.date)
        allMonths.append(contentsOf: month)
        
        DispatchQueue.main.async {
            self.isLoadingBottom = false
        }
    }
    
    //MARK: - Jump to selected month
    
    func jumpToSelectedMonth() async {
        viewStarted = false
        scrollID = allMonths.first(where: { $0.date == dateManager.startOfMonth(for: selectedDate) })?.id
        scrollAnchor = .top
        
        try? await Task.sleep(for: .seconds(0.5))
        viewStarted = true
    }
    
    //MARK: - iOS 18 section
    
    @available(iOS 18.0, *)
    func jumpToSelectedMonth18iOS() async {
        scrollPosition.scrollTo(y: 3000)
        
        try? await Task.sleep(for: .seconds(0.1))
        viewStarted = true
    }
    
    @available(iOS 18.0, *)
    func backToTodayButton18iOS() async {
        if let id = allMonths.first(where: { calendar.isDate($0.date, inSameDayAs: dateManager.startOfMonth(for: Date()))})?.id {
            dateManager.backToToday()
            scrollPosition.scrollTo(id: id, anchor: .top)
            scrolledFromCurrentMonth = false
        } else {
            dateManager.backToToday()
            allMonths = dateManager.initializeMonth()
            await jumpToSelectedMonth18iOS()
        }
    }
    
    
    //MARK: - Load past Months
    
    @available(iOS 18.0, *)
    /// Load 10 past months #available only iOS18+
    func loadPastMonths(info: ScrollInfo) {
        isLoadingTop = true
        
        let months = dateManager.generatePreviousMonths(for: allMonths.first!.date).reversed()
        allMonths.insert(contentsOf: months, at: 0)
        
        adjustScrollContentHeight(removesTop: false, info: info)
        
        DispatchQueue.main.async {
            self.isLoadingTop = false
        }
    }
    
    //MARK: - Load future Months
    
    @available(iOS 18.0, *)
    /// Load 10 future months #available only iOS18+
    func loadFutureMonths(info: ScrollInfo) {
        isLoadingBottom = true
        
        let month = dateManager.generateFeatureMonths(for: allMonths.last!.date)
        allMonths.append(contentsOf: month)
        
        if allMonths.count > 30 {
            adjustScrollContentHeight(removesTop: true, info: info)
        }
        
        DispatchQueue.main.async {
            self.isLoadingBottom = false
        }
    }
    
    //MARK: - Adjustment scroll
    
    @available(iOS 18.0, *)
    func adjustScrollContentHeight(removesTop: Bool, info: ScrollInfo) {
        let previousContentHeight = info.contentHeight
        let previousOffset = info.offsetY
        
        let adjustmentHeight: CGFloat = monthHeight * 10
        
        if removesTop {
            allMonths.removeFirst(10)
        } else {
            if allMonths.count > 30 {
                allMonths.removeLast(10)
            }
        }
        
        let newContentHeight = previousContentHeight + (removesTop ? -adjustmentHeight : adjustmentHeight)
        let newContentOffset = previousOffset + (newContentHeight - previousContentHeight)
        
        var transaction = Transaction()
        transaction.scrollPositionUpdatePreservesVelocity = true
        
        withTransaction(transaction) {
            scrollPosition.scrollTo(y: newContentOffset)
        }
    }
    
    //MARK: - Up/Down Button
    
    func checkIfUserScrolledFromSelectedDate(month: Month) {
        if month.date > calendar.date(byAdding: .month, value: 2, to: selectedDate)! {
            imageForScrollBackButton = "chevron.up"
            scrolledFromCurrentMonth = true
        } else if month.date < calendar.date(byAdding: .month, value: -3, to: selectedDate)! {
            imageForScrollBackButton = "chevron.down"
            scrolledFromCurrentMonth = true
        } else {
            scrolledFromCurrentMonth = false
        }
    }
    
    //MARK: - Download DaysVM
    @MainActor
    func downloadDaysVMs() async {
        guard let scrollID else { return }
        //                await dayVMStore.createMonthVMs(scrollID: scrollID)
    }
    
    @MainActor
    func syncDayVM(for day: Date) async {
        let key = dateManager.startOfDay(for: day).timeIntervalSince1970
        if dayVMs[key] != nil { return }
        
        if let vm = await dayVMStore.returnDayVM(day) {
            dayVMs[key] = vm
        }
    }
    
    //MARK: - Return DayVM
    
    @MainActor
    func returnDayVM(_ day: Day) -> DayViewVM {
        let vm = DayViewVM.createVM(
            dateManager: dateManager,
            taskManager: taskManager,
            appearanceManager: appearanceManager,
            day: day
        )
        vm.ableToDownload = ableToDownloadTasksColors
        
        return vm
        
        //        let key = dateManager.startOfDay(for: day).timeIntervalSince1970
        //        return dayVMs[key]
    }
    
    //MARK: Telemtry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
