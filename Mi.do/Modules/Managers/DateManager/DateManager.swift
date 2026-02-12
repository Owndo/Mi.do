//
//  DateManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Foundation
import SwiftUI
import Models
import ProfileManager
import TelemetryManager

@Observable
public final class DateManager: DateManagerProtocol {
    
    ///for the set up first day of week
    private var telemetryManager: TelemetryManagerProtocol
    
    public let dateStream: AsyncStream<Void>
    private let dateChangeContinuation: AsyncStream<Void>.Continuation
    
    public var calendar = Calendar.current
    
    public var selectedDate = Date() {
        didSet {
            guard selectedDate != oldValue else { return }
            dateChangeContinuation.yield()
        }
    }
    
    public var currentTime: Date = Date.now
    
    public var allWeeks: [Week] = []
    public var allMonths: [Month] = []
    private var monthCache: [TimeInterval: Month] = [:]
    private var weekCache: [TimeInterval: Week] = [:]
    
    public var selectedWeekDay: Int {
        calendar.component(.weekday, from: selectedDate)
    }
    
    public var indexForWeek = 0 {
        didSet {
            weekIndexChanged()
        }
    }
    
    private var blockIndexUpdate = false
    
    //MARK: - Private init
    
    private init(telemetryManager: TelemetryManagerProtocol) {
        self.telemetryManager = telemetryManager
        
        let (stream, cont) = AsyncStream<Void>.makeStream()
        self.dateStream = stream
        self.dateChangeContinuation = cont
    }
    
    public static func createDateManager(profileManager: ProfileManagerProtocol) async -> DateManagerProtocol {
        let telemetryManager = TelemetryManager.createTelemetryManager()
        let manager = DateManager(telemetryManager: telemetryManager)
        
        manager.calendar.firstWeekday = profileManager.profileModel.settings.firstDayOfWeek
        manager.initializeWeek()
        
        return manager
    }
    
    //MARK: - Create Preview Manager
    
    public static func createPreviewManager() -> DateManagerProtocol {
        let dateManager = DateManager(telemetryManager: TelemetryManager.createTelemetryManager(mock: true))
        dateManager.initializeWeek()
        
        return dateManager
    }
    
    //MARK: - Create Empty Manager
    
    public static func createEmptyManager() -> DateManagerProtocol {
        let dateManager = DateManager(telemetryManager: TelemetryManager.createTelemetryManager(mock: true))
        
        return dateManager
    }
    
    //MARK: - Selected date change
    
    public func selectedDateChange(_ day: Date) {
        selectedDate = day
    }
    
    //MARK: - Week Index changed
    
    private func weekIndexChanged() {
        guard !blockIndexUpdate else {
            return
        }
        
        guard let week = allWeeks.first(where: { $0.index == indexForWeek }) else { return }
        
        let startOfSelectedWeek = startOfWeek(for: selectedDate)
        let dayOffset = calendar.dateComponents([.day], from: startOfSelectedWeek, to: selectedDate).day ?? 0
        let newDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek(for: week.days.first!.date))!
        
        selectedDateChange(newDate)
        
        if let index = allWeeks.last {
            if indexForWeek == index.index! {
                appendWeeksForward()
            }
        }
        
        if indexForWeek == allWeeks.first!.index! {
            Task {
                try? await Task.sleep(for: .seconds(0.2))
                appendWeeksBackward()
            }
        }
    }
    
    //MARK: - Logic for week
    
    public func initializeWeek() {
        allWeeks = (-8...8).map { i in
            let date = calendar.date(byAdding: .weekOfYear, value: i, to: selectedDate)!
            var week = generateWeek(for: date)
            week.index = i
            
            return week
        }
    }
    
    //MARK: - Append Week Forward
    
    private func appendWeeksForward() {
        guard
            let lastWeek = allWeeks.last,
            let index = lastWeek.index,
            let day = lastWeek.days.first
        else {
            return
        }
        
        let startOfWeek = startOfWeek(for: day.date)
        
        let newWeeks = (1...24).map { offSet in
            let nextWeekDate = calendar.date(byAdding: .weekOfYear, value: offSet, to: startOfWeek)!
            var newWeek = generateWeek(for: nextWeekDate)
            newWeek.index = index + offSet
            
            return newWeek
        }
        
        allWeeks.append(contentsOf: newWeeks)
    }
    
    //MARK: - Append Week Backward
    
    private func appendWeeksBackward() {
        guard
            let firstWeek = allWeeks.first,
            let index = firstWeek.index,
            let day = firstWeek.days.first
        else {
            return
        }
        
        let startOfWeek = startOfWeek(for: day.date)
        
        let newWeeks = (1...24).map { offSet in
            let nextWeekDate = calendar.date(byAdding: .weekOfYear, value: -offSet, to: startOfWeek)!
            var newWeek = generateWeek(for: nextWeekDate)
            newWeek.index = index - offSet
            
            return newWeek
        }.reversed()
        
        allWeeks.insert(contentsOf: newWeeks, at: 0)
    }
    
    //MARK: - Generate week
    
    public func generateWeek(for date: Date) -> Week {
        let startOfWeek = startOfWeek(for: date)
        
        let days: [Day] = (0..<7).compactMap { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            let index = calendar.dateComponents([.day], from: date).day!
            
            return Day(value: index, date: date)
        }
        
        let week = Week(days: days)
        
        return week
    }
    
    
    //MARK: - Week in Month
    
    private func weeksInMonth(for date: Date) -> [Week] {
        let firstWeek = self.firstWeekInMonth(for: date)
        let endOfMonth = self.endOfMonth(for: date)
        
        var weeks = [Week]()
        var currentDate = firstWeek
        
        while currentDate < endOfMonth {
            var days = [Day]()
            
            for _ in 0..<7 {
                if calendar.isDate(currentDate, equalTo: date, toGranularity: .month) {
                    let value = calendar.component(.day, from: firstWeek)
                    let day = Day(value: value, date: currentDate, isPlaceholder: false)
                    days.append(day)
                } else {
                    days.append(.init(date: Date(), isPlaceholder: true))
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            let week = Week(days: days)
            weeks.append(week)
        }
        
        if let lastWeek = weeks.indices.last {
            weeks[lastWeek].isLast = true
        }
        
        return weeks
    }
    
    //MARK: - Logic for months
    
    public func initializeMonth() -> [Month] {
        (-6...6).map { i in
            let monthDate = calendar.date(byAdding: .month, value: i, to: selectedDate)!
            let monthName = self.monthName(for: monthDate)
            let weeks = self.weeksInMonth(for: monthDate)
            let startOfMonth = self.startOfMonth(for: monthDate)
            let month = Month(name: monthName, weeks: weeks, date: startOfMonth)
            
            return month
        }
    }
    
    //MARK: - Selected Day is Today
    
    public func selectedDayIsToday() -> Bool {
        calendar.isDate(selectedDate, inSameDayAs: currentTime)
    }
    
    //MARK: - Generate previous months
    
    public func generatePreviousMonths(for date: Date) -> [Month] {
        return (1...10).map {
            let date = calendar.date(byAdding: .month, value: -$0, to: date)!
            return getOrCreateMonth(for: date)
        }
    }
    
    //MARK: - Generate future months
    
    public func generateFeatureMonths(for date: Date) -> [Month] {
        return (1...10).map {
            let date = calendar.date(byAdding: .month, value: $0, to: date)!
            return getOrCreateMonth(for: date)
        }
    }
    
    //MARK: - Generate previous month
    
    public func generatePreviousMonth(for date: Date) -> Month {
        return getOrCreateMonth(for: calendar.date(byAdding: .month, value: -1, to: date)!)
    }
    
    //MARK: - Generate future months
    
    public func generateFutureMonth(for date: Date) -> Month {
        return getOrCreateMonth(for: calendar.date(byAdding: .month, value: 1, to: date)!)
    }
    
    //MARK: - Get or create for cahce
    
    private func getOrCreateMonth(for date: Date) -> Month {
        let start = startOfMonth(for: date)
        let key = start.timeIntervalSince1970
        
        if let cached = monthCache[key] {
            return cached
        }
        
        let weeks = weeksInMonth(for: start)
        let name = monthName(for: start)
        
        let month = Month(name: name, weeks: weeks, date: start)
        monthCache[key] = month
        return month
    }
    
    //MARK: - Name of month
    
    private func monthName(for date: Date) -> String {
        let currentYear = calendar.component(.year, from: Date())
        let yearFromDate = calendar.component(.year, from: date)
        
        if currentYear == yearFromDate {
            return date.formatted(.dateTime.month(.wide))
        } else {
            return date.formatted(.dateTime.month(.wide).year())
        }
    }
    
    //MARK: - Date to string
    
    public func dateToString(for date: Date, useForWeekView: Bool) -> LocalizedStringKey {
        if useForWeekView {
            return formatterDate(date: date, useForWeek: useForWeekView)
        } else {
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInTomorrow(date) {
                return "Tomorrow"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                return formatterDate(date: date, useForWeek: false)
            }
        }
    }
    
    public func dateForDeadline(for date: Date) -> LocalizedStringKey {
        return formatterDate(date: date, useForDeadline: true)
    }
    
    private func formatterDate(date: Date, useForWeek: Bool = false, useForDeadline: Bool = false) -> LocalizedStringKey {
        guard !useForWeek else {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            
            var dateString = ""
            
            if calendar.dateComponents([.year], from: date).year == calendar.dateComponents([.year], from: Date()).year {
                dateString = date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(formatter.locale))
            } else {
                dateString = date.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(formatter.locale))
            }
            
            return LocalizedStringKey("\(dateString.capitalized)")
        }
        
        guard useForDeadline == false else {
            let dateString = date.formatted(.dateTime.weekday().day().month(.abbreviated).locale(Locale.current))
            return LocalizedStringKey("\(dateString.capitalized)")
        }
        
        let dateString = date.formatted(.dateTime.weekday().day().month(.wide).locale(Locale.current))
        return LocalizedStringKey("\(dateString.capitalized)")
    }
    
    public func combineDateAndTime(timeComponents: DateComponents) -> Date {
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        let now = currentTime
        let isToday = calendar.isDate(selectedDate, inSameDayAs: now)
        let currentHour = calendar.component(.hour, from: now)
        
        if isToday && currentHour >= 22 {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                dateComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
            }
        }
        
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        return calendar.date(from: dateComponents)!
    }
    
    public func createdtaskDate(task: UITaskModel) -> Date {
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let componentsFromTask = calendar.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: task.notificationDate))
        
        dateComponents.hour = componentsFromTask.hour
        dateComponents.minute = componentsFromTask.minute
        
        return calendar.date(from: dateComponents)!
    }
    
    
    public func getDefaultNotificationTime() -> Date {
        func dateAt(_ date: Date, hour: Int, minute: Int = 0, second: Int = 0) -> Date {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            components.minute = minute
            components.second = second
            return calendar.date(from: components)!
        }
        
        if !calendar.isDate(selectedDate, inSameDayAs: currentTime) {
            return dateAt(selectedDate, hour: 9)
        }
        
        let hour = calendar.component(.hour, from: currentTime)
        
        switch hour {
        case 0..<9:
            return dateAt(currentTime, hour: 9)
        case 9...21:
            return dateAt(currentTime, hour: hour + 1)
        default:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentTime)!
            return dateAt(tomorrow, hour: 9)
        }
    }
    
    public func updateNotificationDate(_ date: Double) -> Double {
        let inputDate = Date(timeIntervalSince1970: date)
        let now = currentTime
        
        if inputDate < now {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            let hour = calendar.component(.hour, from: inputDate)
            let minute = calendar.component(.minute, from: inputDate)
            let second = calendar.component(.second, from: inputDate)
            let tomorrowAtSameTime = calendar.date(bySettingHour: hour, minute: minute, second: second, of: tomorrow)!
            return tomorrowAtSameTime.timeIntervalSince1970
        } else {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: inputDate)!
            return nextDay.timeIntervalSince1970
        }
    }
    
    //MARK: - Back to today
    
    public func backToToday() {
        blockIndexUpdate = true
        
        selectedDateChange(currentTime)
        initializeWeek()
        
        DispatchQueue.main.async {
            self.indexForWeek = 0
            self.blockIndexUpdate = false
        }
    }
    
    //MARK: - Days of week
    
    public func thursday() -> Date {
        let weekdayToday = calendar.component(.weekday, from: currentTime)
        
        let daysUntilThursday = (5 - weekdayToday + 7) % 7
        let targetDate = calendar.date(byAdding: .day, value: daysUntilThursday, to: currentTime)!
        
        return targetDate
    }
    
    public func sunday() -> Date {
        let weekdayToday = calendar.component(.weekday, from: currentTime)
        
        let daysUntilWednesday = (1 - weekdayToday + 7) % 7
        let targetDate = calendar.date(byAdding: .day, value: daysUntilWednesday, to: currentTime)!
        
        return targetDate
    }
    
    //MARK: - Start of the day
    
    public func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    //MARK: - Start of the week
    
    /// Find start of week for the date
    public func startOfWeek(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)!.start
    }
    
    //MARK: - End of the week
    
    /// Find end of week (start of next week)
    public func endOfWeek(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)!.end
    }
    
    public func startOfMonth(for date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)!.start
    }
    
    public func endOfMonth(for date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)!.end
    }
    
    /// Return first week from the month from the data
    private func firstWeekInMonth(for date: Date) -> Date {
        let month = calendar.dateInterval(of: .month, for: date)!.start
        let firstWeek = calendar.dateInterval(of: .weekOfYear, for: month)!
        
        return firstWeek.start
    }
}
