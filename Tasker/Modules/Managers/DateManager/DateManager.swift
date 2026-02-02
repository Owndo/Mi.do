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
    
    public var indexForWeek = 0
    //    {
    //        didSet {
    //            guard let week = allWeeks.first(where: { $0.id == indexForWeek }) else {
    //                return
    //            }
    //
    //            if let matchingDay = week.date.first(where: { calendar.component(.weekday, from: $0) == calendar.component(.weekday, from: selectedDate)}) {
    //                selectedDateChange(matchingDay)
    //            }
    //
    //            if indexForWeek == allWeeks.first?.id {
    //                appendWeeksBackward()
    //            } else if indexForWeek == allWeeks.count - 1 {
    //                appendWeeksForward()
    //            }
    //        }
    //        willSet {
    //            // telemetry
    //            if newValue > indexForWeek {
    //                telemetryManager.logEvent(.calendarAction(.changeWeekScrolled(.forward)))
    //            } else {
    //                telemetryManager.logEvent(.calendarAction(.changeWeekScrolled(.backward)))
    //            }
    //        }
    //    }
    
    //MARK: - Init
    
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
        
        Task {
            await dateManager.initializeMonth()
        }
        
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
    
    //MARK: - Logic for week
    public func initializeWeek() {
        //        allWeeks.removeAll()
        //
        //        //MARK: Previous 4 weeks
        
        allWeeks = (-4...4).map { i in
            let date = calendar.date(byAdding: .weekOfYear, value: -i, to: selectedDate)!
            return generateWeek(for: date)
            
        }
        //        appendWeeksForward()
        //        appendWeeksBackward()
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
    
    //MARK: - Initialize months
    
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
    
    public func selectedDayIsToday() -> Bool {
        calendar.isDate(selectedDate, inSameDayAs: currentTime)
    }
    
    //MARK: - Append Week Forward
    
    public func appendWeeksForward() {
        //        guard let lastWeekStart = allWeeks.last?.date.first else { return }
        //
        //        for i in 1...24 {
        //            let weekStart = calendar.date(byAdding: .weekOfYear, value: i, to: lastWeekStart)!
        //            let newWeek = generateWeek(for: weekStart)
        //            allWeeks.append(PeriodModel(id: allWeeks.last!.id + 1, date: newWeek))
        //        }
    }
    
    //MARK: - Append Week Backward
    
    public func appendWeeksBackward() {
        //        guard let firstWeekStart = allWeeks.first?.date.first else { return }
        //        for i in (1...24) {
        //            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: firstWeekStart)!
        //            let newWeek = generateWeek(for: weekStart)
        //            allWeeks.insert(PeriodModel(id: allWeeks.first!.id - 1, date: newWeek), at: 0)
        //        }
    }
    
    private func generateWeek(for date: Date) -> Week {
        let startOfWeek = startOfWeek(for: date)
        
        let days: [Day] = (0..<7).compactMap { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            let index = calendar.dateComponents([.day], from: date).day!
            
            return Day(value: index, date: date)
        }
        
        let week = Week(days: days)
        
        return week
    }
    
    //MARK: - Months
    
    public func generatePreviousMonths(for date: Date) -> [Month] {
        return (1...10).map {
            let date = calendar.date(byAdding: .month, value: -$0, to: date)!
            return getOrCreateMonth(for: date)
        }
    }
    
    public func generateFeatureMonths(for date: Date) -> [Month] {
        return (1...10).map {
            let date = calendar.date(byAdding: .month, value: $0, to: date)!
            return getOrCreateMonth(for: date)
        }
    }
    
    public func generatePreviousMonth(for date: Date) -> Month {
        return getOrCreateMonth(for: calendar.date(byAdding: .month, value: -1, to: date)!)
        //        guard let firstDay = allMonths.first!.date.first else { return }
        //        let monthStart = calendar.date(byAdding: .month, value: -1, to: firstDay)!
        //        let newMonth = generateMonth(for: monthStart)
        //        let nameOfMonth = getMonthName(from: monthStart)
        //        let newId = allMonths.first!.id - 1
        
        //        allMonths.insert(PeriodModel(id: newId, date: newMonth, name: nameOfMonth), at: 0)
    }
    
    public func generateFeatureMonth(for date: Date) -> Month {
        return getOrCreateMonth(for: calendar.date(byAdding: .month, value: 1, to: date)!)
        //        guard let lastMonthStart = allMonths.last?.date.first else { return }
        //        let monthStart = calendar.date(byAdding: .month, value: 1, to: lastMonthStart)!
        //        let newMonth = generateMonth(for: monthStart)
        //        let nextID = (allMonths.last?.id ?? 0) + 1
        //
        ////        allMonths.removeFirst()
        //        allMonths.append(PeriodModel(id: nextID, date: newMonth))
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
    
    
    public func appendMonthsBackward() async {
        //        guard let firstMonthStart = allMonths.first?.date.first,
        //              let firstID = allMonths.first?.id else { return }
        //
        //        var newMonths: [PeriodModel] = []
        //
        //        for i in (1...24).reversed() {
        //            let offset = -i
        //            let monthStart = calendar.date(byAdding: .month, value: offset, to: firstMonthStart)!
        //            let newMonth = generateMonth(for: monthStart)
        //            let nameOfMonth = getMonthName(from: monthStart)
        //            let newID = firstID + offset
        //            newMonths.append(PeriodModel(id: newID, date: newMonth, name: nameOfMonth))
        //        }
        //
        //        allMonths.insert(contentsOf: newMonths, at: 0)
    }
    
    //    private func generateMonth(for date: Date) -> [Date] {
    //        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
    //              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
    //            return []
    //        }
    //
    //        return range.map { day in
    //            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
    //        }
    //    }
    
    private func getMonthName(from date: Date) -> String {
        let currentYear = calendar.component(.year, from: Date())
        let yearFromDate = calendar.component(.year, from: date)
        
        if currentYear == yearFromDate {
            return date.formatted(.dateTime.month(.wide))
        } else {
            return date.formatted(.dateTime.month(.wide).year())
        }
    }
    
    //MARK: - Month for name
    
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
        case 9..<18:
            return dateAt(currentTime, hour: hour + 1)
        case 18...21:
            return dateAt(currentTime, hour: 21)
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
    
    //    public func addOneDay() {
    //        let currentDate = selectedDate
    //        let newDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
    //
    //        //check if day last in week
    //        if let lastDate = allWeeks.last?.date.last, newDate > lastDate {
    //            //            appendWeeksForward()
    //        }
    //
    //        selectedDateChange(newDate)
    //
    //        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
    //        let newWeek = calendar.component(.weekOfYear, from: newDate)
    //
    //        if newWeek != currentWeek {
    //            //            updateWeekIndex(for: newDate)
    //        }
    //    }
    
    //    public func subtractOneDay() {
    //        let currentDate = selectedDate
    //        let newDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
    //
    //        if let firstDate = allWeeks.first?.date.first, newDate < firstDate {
    //            appendWeeksBackward()
    //        }
    //
    //        selectedDateChange(newDate)
    //
    //        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
    //        let newWeek = calendar.component(.weekOfYear, from: newDate)
    //
    //        if newWeek != currentWeek {
    //            //                        updateWeekIndex(for: newDate)
    //        }
    //    }
    
    //MARK: - Back to today
    
    public func backToToday() {
        selectedDateChange(currentTime)
        
        initializeWeek()
        indexForWeek = 0
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
