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
    
    private let _dateChangeContinuation: AsyncStream<Date>.Continuation
    public let dateChanges: AsyncStream<Date>
    
    public var calendar = Calendar.current
    
    public var selectedDate = Date() {
        didSet {
            guard selectedDate != oldValue else { return }
            _dateChangeContinuation.yield(selectedDate)
        }
    }
    
    public var currentTime: Date = Date.now
    
    public var allWeeks: [PeriodModel] = []
    public var allMonths: [PeriodModel] = []
    
    public var selectedWeekDay: Int {
        calendar.component(.weekday, from: selectedDate)
    }
    
    public var indexForWeek = 1 {
        didSet {
            let weeksDate = allWeeks.first(where: { $0.id == indexForWeek})!.date
            if let sameWeekDay = weeksDate.first(where: {
                calendar.component(.weekday, from: $0) == selectedWeekDay
            }) {
                selectedDateChange(sameWeekDay)
            } else {
                selectedDateChange(allWeeks[1].date.first!)
            }
            
            if indexForWeek == allWeeks.last?.id {
                appendWeeksForward()
            } else if indexForWeek == allWeeks.first?.id {
                appendWeeksBackward()
            }
        }
        willSet {
            // telemetry
            if newValue > indexForWeek {
                telemetryManager.logEvent(.calendarAction(.changeWeekScrolled(.forward)))
            } else {
                telemetryManager.logEvent(.calendarAction(.changeWeekScrolled(.backward)))
            }
        }
    }
    
    //MARK: - Init
    
    private init(telemetryManager: TelemetryManagerProtocol) {
        self.telemetryManager = telemetryManager
        
        (self.dateChanges, self._dateChangeContinuation) = AsyncStream.makeStream()
    }
    
    deinit {
        _dateChangeContinuation.finish()
    }
    
    public static func createDateManager(profileManager: ProfileManagerProtocol) async -> DateManagerProtocol {
        let telemetryManager = TelemetryManager.createTelemetryManager()
        let manager = DateManager(telemetryManager: telemetryManager)
        
        manager.calendar.firstWeekday = profileManager.profileModel.settings.firstDayOfWeek
        manager.initializeWeek()
        await manager.initializeMonth()
        
        return manager
    }
    
    public static func createMockDateManager() -> DateManagerProtocol {
        let dateManager = DateManager(telemetryManager: TelemetryManager.createTelemetryManager(mock: true))
        dateManager.initializeWeek()
        Task {
            await dateManager.initializeMonth()
        }
        
        return dateManager
    }
    
    //MARK: - Selected date change
    
    public func selectedDateChange(_ day: Date) {
        selectedDate = day
    }
    
    //MARK: - Logic for week
    public func initializeWeek() {
        allWeeks.removeAll()
        //MARK: Previous 4 weeks
        for i in (1...4).reversed() {
            let week = calendar.date(byAdding: .weekOfYear, value: -i, to: startOfWeek(for: selectedDate))!
            let newWeek = generateWeek(for: week)
            allWeeks.append(PeriodModel(id: -i, date: newWeek))
        }
        
        let currentWeekStart = startOfWeek(for: selectedDate)
        allWeeks.append(PeriodModel(id: 1, date: generateWeek(for: currentWeekStart)))
        
        var idNumber = 2
        for i in 1...4 {
            let week = calendar.date(byAdding: .weekOfYear, value: i, to: startOfWeek(for: selectedDate))!
            let newWeek = generateWeek(for: week)
            allWeeks.append(PeriodModel(id: idNumber, date: newWeek))
            idNumber += 1
        }
        
        appendWeeksForward()
        appendWeeksBackward()
    }
    
    //MARK: - Initialize months
    
    public func initializeMonth() async {
        allMonths = []
        
        await withTaskGroup(of: PeriodModel.self) { group in
            for id in 0...19 {
                group.addTask {
                    let offset = id - 10
                    
                    let monthDate = self.calendar.date(
                        byAdding: .month,
                        value: offset,
                        to: self.selectedDate
                    )!
                    
                    let newMonth = self.generateMonth(for: monthDate)
                    let name = self.getMonthName(from: monthDate)
                    
                    return PeriodModel(id: id, date: newMonth, name: name)
                }
            }
            
            for await month in group {
                allMonths.append(month)
            }
        }
        
        allMonths.sort { $0.id < $1.id }
    }
    
    public func startOfWeek(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
    }
    
    public func changeIndexForWeek(_ index: Int) {
        indexForWeek = index
    }
    
    public func selectedDayIsToday() -> Bool {
        calendar.isDate(selectedDate, inSameDayAs: currentTime)
    }
    
    //MARK: - Weeks
    public func appendWeeksForward() {
        guard let lastWeekStart = allWeeks.last?.date.first else { return }
        for i in 1...24 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: i, to: lastWeekStart)!
            let newWeek = generateWeek(for: weekStart)
            allWeeks.append(PeriodModel(id: allWeeks.last!.id + 1, date: newWeek))
        }
    }
    
    public func appendWeeksBackward() {
        guard let firstWeekStart = allWeeks.first?.date.first else { return }
        for i in (1...24) {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: firstWeekStart)!
            let newWeek = generateWeek(for: weekStart)
            allWeeks.insert(PeriodModel(id: allWeeks.first!.id - 1, date: newWeek), at: 0)
        }
    }
    
    private func generateWeek(for date: Date) -> [Date] {
        let startOfWeek = startOfWeek(for: date)
        return (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
        }
    }
    
    //MARK: - Months
    
    public func generatePreviousMonth() async {
        guard let firstDay = allMonths.first!.date.first else { return }
        let monthStart = calendar.date(byAdding: .month, value: -1, to: firstDay)!
        let newMonth = generateMonth(for: monthStart)
        let nameOfMonth = getMonthName(from: monthStart)
        let newId = allMonths.first!.id - 1
        
//        allMonths.removeLast()
        allMonths.insert(PeriodModel(id: newId, date: newMonth, name: nameOfMonth), at: 0)
    }
    
    public func generateFeatureMonth() async {
        guard let lastMonthStart = allMonths.last?.date.first else { return }
        let monthStart = calendar.date(byAdding: .month, value: 1, to: lastMonthStart)!
        let newMonth = generateMonth(for: monthStart)
        let nameOfMonth = getMonthName(from: monthStart)
        let nextID = (allMonths.last?.id ?? 0) + 1
        allMonths.append(PeriodModel(id: nextID, date: newMonth, name: nameOfMonth))
    }
    
    public func appendMonthsBackward() async {
        guard let firstMonthStart = allMonths.first?.date.first,
              let firstID = allMonths.first?.id else { return }
        
        var newMonths: [PeriodModel] = []
        
        for i in (1...24).reversed() {
            let offset = -i
            let monthStart = calendar.date(byAdding: .month, value: offset, to: firstMonthStart)!
            let newMonth = generateMonth(for: monthStart)
            let nameOfMonth = getMonthName(from: monthStart)
            let newID = firstID + offset
            newMonths.append(PeriodModel(id: newID, date: newMonth, name: nameOfMonth))
        }
        
        allMonths.insert(contentsOf: newMonths, at: 0)
    }
    
    private func generateMonth(for date: Date) -> [Date] {
        var dates: [Date] = []
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(dayDate)
            }
        }
        
        return dates
    }
    
    private func getMonthName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = calendar
        formatter.dateFormat = "LLLL"
        return formatter.string(from: date).capitalized
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
    
    public func addOneDay() {
        let currentDate = selectedDate
        let newDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        
        //check if day last in week
        if let lastDate = allWeeks.last?.date.last, newDate > lastDate {
            appendWeeksForward()
        }
        
        selectedDateChange(newDate)
        
        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
        let newWeek = calendar.component(.weekOfYear, from: newDate)
        
        if newWeek != currentWeek {
            updateWeekIndex(for: newDate)
        }
    }
    
    public func subtractOneDay() {
        let currentDate = selectedDate
        let newDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        
        if let firstDate = allWeeks.first?.date.first, newDate < firstDate {
            appendWeeksBackward()
        }
        
        selectedDateChange(newDate)
        
        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
        let newWeek = calendar.component(.weekOfYear, from: newDate)
        
        if newWeek != currentWeek {
            updateWeekIndex(for: newDate)
        }
    }
    
    public func backToToday() {
        selectedDateChange(currentTime)
        indexForWeek = 1
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
    
    
    private func updateWeekIndex(for date: Date) {
        let newWeekStart = startOfWeek(for: date)
        
        if let newWeek = allWeeks.first(where: { startOfWeek(for: $0.date.first!) == newWeekStart }) {
            indexForWeek = newWeek.id
        } else {
            appendWeeksForward()
            appendWeeksBackward()
            
            if let refreshedWeek = allWeeks.first(where: { startOfWeek(for: $0.date.first!) == newWeekStart }) {
                indexForWeek = refreshedWeek.id
            }
        }
    }
}
