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
    
    var ableToDownloadTasksColors = false
    
    private let telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    var dayVMs: [TimeInterval: DayViewVM] = [:]
    var downloadDay = false
    
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
    var scrolledToTheFuture = false
    var scrolledToThePast = false
    
    var isLoadingTop = false
    var isLoadingBottom = false
    var isResetting: Bool = true
    
    //MARK: - UI State
    
    var viewStarted = false
    
    var currentYear: String?
    var showYear = false
    
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    }
    
    var selectedDate: Date {
        
        return dateManager.selectedDate
    }
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var today: Date = Date()
    
    var allMonths: [Month] = []
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
    }
    
    //MARK: - CreateMonthVM
    
    public static func createMonthVM(
        appearanceManager: AppearanceManagerProtocol,
        dateManager: DateManagerProtocol,
        taskManager: TaskManagerProtocol,
    ) async -> MonthsViewVM {
        let vm = MonthsViewVM(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
        
        return vm
    }
    
    //MARK: - Create previewVm
    
    public static func createPreviewVM() -> MonthsViewVM {
        let appearanceManager = AppearanceManager.createMockAppearanceManager()
        let dateManager = DateManager.createPreviewManager()
        let taskManager = TaskManager.createMockTaskManager()
        
        let vm = MonthsViewVM(
            appearanceManager: appearanceManager,
            dateManager: dateManager,
            taskManager: taskManager,
        )
        
        return vm
    }
    
    //MARK: - Start VM
    
    public func startVM() async {
        allMonths = dateManager.initializeMonth()
    }
    
    func endVM() {
        viewStarted = false
        allMonths.removeAll()
    }
    
    //MARK: - Go to selected date button
    
    func selectedDateChange(_ day: Date) {
        dateManager.selectedDateChange(day)
        dateManager.initializeWeek()
        //
        backToMainView?()
        
        // telemetry
        telemetryAction(.calendarAction(.selectedDateButtonTapped(.calendarView)))
    }
    
    func shiftedWeekdaySymbols() -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let weekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[weekdayIndex...] + symbols[..<weekdayIndex])
    }
    
    // MARK: - Day is today
    
    func isSelectedDay(_ day: Date) -> Bool {
        return calendar.isDate(day, inSameDayAs: selectedDate)
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
    
    @MainActor
    func backToSelectedMonthButtonTapped() async {
        viewStarted = false
        
        defer {
            viewStarted = true
        }
        
        if #available(iOS 18, *) {
            if allMonths.contains(where: { $0.date == dateManager.startOfMonth(for: selectedDate)}) {
                
                //TODO: - Move from id position to y position
                
                if scrolledToThePast {
                    if allMonths.count < 20 {
                        scrollPosition.scrollTo(y: 3000)
                    } else if allMonths.count > 20 {
                        let selectedMonth = dateManager.startOfMonth(for: selectedDate)
                        let isInFirstTen = allMonths.prefix(10).contains { $0.date == selectedMonth }
                        
                        if isInFirstTen {
                            scrollPosition.scrollTo(y: 3000)
                        } else {
                            scrollPosition.scrollTo(y: 8000)
                        }
                    }
                } else if scrolledToTheFuture {
                    scrollPosition.scrollTo(y: 3000)
                }
            } else {
                allMonths = dateManager.initializeMonth()
                await jumpToSelectedMonth18iOS()
            }
        } else {
            await jumpToSelectedMonth()
        }
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
        
        try? await Task.sleep(for: .seconds(0.3))
        viewStarted = true
    }
    
    //MARK: - iOS 18 section
    
    @available(iOS 18.0, *)
    @MainActor
    func jumpToSelectedMonth18iOS() async {
        viewStarted = false
        let position = (CGFloat(allMonths.count / 2) * monthHeight)
        scrollPosition.scrollTo(y: position)
        
        try? await Task.sleep(for: .seconds(0.5))
        viewStarted = true
    }
    
    //MARK: - Back to today 18iOS
    
    @available(iOS 18.0, *)
    @MainActor
    func backToTodayButton18iOS() async {
        viewStarted = false
        
        defer {
            viewStarted = true
        }
        
        dateManager.backToToday()
        
        if let id = allMonths.first(where: { calendar.isDate($0.date, inSameDayAs: dateManager.startOfMonth(for: Date()))})?.id {
            scrollPosition.scrollTo(id: id, anchor: .top)
        } else {
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
    
    //MARK: - HandleSchenePhase
    
    var downloadTask: Task<Void, Never>?
    
    @available(iOS 18.0, *)
    @MainActor
    func handleScrollPhase(_ phase: ScrollPhase) async {
        guard viewStarted else { return }
        
        switch phase {
        case .idle, .animating:
            cancelDownloadTask()
            downloadDay = true
        case .interacting:
            startDelayedDownload()
        default:
            cancelDownloadTask()
            downloadDay = false
        }
    }
    
    @MainActor
    private func startDelayedDownload() {
        guard downloadTask == nil else { return }
        
        downloadTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            
            guard let self, !Task.isCancelled else { return }
            
            self.downloadDay = true
        }
    }
    
    @MainActor
    private func cancelDownloadTask() {
        downloadTask?.cancel()
        downloadTask = nil
    }
    
    //MARK: - Up/Down Button
    
    @MainActor
    func checkIfUserScrolledFromSelectedDate(month: Month) async {
        if month.date > calendar.date(byAdding: .month, value: 2, to: selectedDate)! {
            scrollToTheFuture()
        } else if month.date < calendar.date(byAdding: .month, value: -3, to: selectedDate)! {
            scrollToThePast()
        } else {
            resetScrolledFlags()
        }
        
        await updateCurrentMonth(month: month)
    }
    
    //MARK: - Go UP button show
    
    @MainActor
    func scrollToTheFuture() {
        imageForScrollBackButton = "chevron.up"
        scrolledFromCurrentMonth = true
        scrolledToTheFuture = true
    }
    
    //MARK: - Go DOWN button show
    
    @MainActor
    func scrollToThePast() {
        imageForScrollBackButton = "chevron.down"
        scrolledFromCurrentMonth = true
        scrolledToThePast = true
    }
    
    //MARK: - Reset Scrolled Flag
    
    func resetScrolledFlags() {
        scrolledFromCurrentMonth = false
        self.scrolledToTheFuture = false
        scrolledToThePast = false
    }
    
    // MARK: - Current year text
    func updateCurrentMonth(month: Month) async {
        let currentYear = calendar.component(.year, from: Date())
        let yearFromMonth = calendar.component(.year, from: month.date)
        
        if yearFromMonth != currentYear {
            self.currentYear = "\(yearFromMonth)"
            showYear = true
        } else {
            self.currentYear = nil
            showYear = false
        }
    }
    
    
    //TODO: - Cache
    //    MARK: - Download DaysVM
    //    @MainActor
    //    func downloadDaysVMs() async {
    //        //        await dayVMStore.createMonthVMs()
    //    }
    
    //    @MainActor
    //    func syncDayVM(for day: Day) async {
    //        let key = dateManager.startOfDay(for: day.date).timeIntervalSince1970
    //        if dayVMs[key] != nil {
    //            return
    //        }
    //
    //        if let vm = await dayVMStore.returnDayVM(day) {
    //            dayVMs[key] = vm
    //        }
    //    }
    
    //MARK: - Return DayVM
    
    @MainActor
    func returnDayVM(_ day: Day) -> DayViewVM {
        DayViewVM.createVM(
            dateManager: dateManager,
            taskManager: taskManager,
            appearanceManager: appearanceManager,
            day: day
        )
        
        //        let key = dateManager.startOfDay(for: day.date).timeIntervalSince1970
        //        return dayVMs[key]
    }
    
    //MARK: Telemtry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
