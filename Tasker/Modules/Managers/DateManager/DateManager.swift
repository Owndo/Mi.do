//
//  DateManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Foundation
import SwiftUI
import Combine
import Models

@Observable
final class DateManager: DateManagerProtocol {
    ///for the set up first day of week
    @ObservationIgnored
    @Injected(\.casManager) var casManager: CASManagerProtocol
    @ObservationIgnored
    @Injected(\.telemetryManager) var telemetryManager: TelemetryManagerProtocol
    
    var calendar = Calendar.current {
        didSet {
            initializeWeek()
        }
    }
    
    var selectedDate = Date()
    
    var allWeeks: [PeriodModel] = []
    var allMonths: [PeriodModel] = []
    
    var currentTime: Date {
        Date()
    }
    
    var selectedWeekDay: Int {
        calendar.component(.weekday, from: selectedDate)
    }
    
    var indexForWeek = 1 {
        didSet {
            let weeksDate = allWeeks.first(where: { $0.id == indexForWeek})!.date
            if let sameWeekDay = weeksDate.first(where: {
                calendar.component(.weekday, from: $0) == selectedWeekDay
            }) {
                selectedDateChange(sameWeekDay)
            } else {
                selectedDateChange(allWeeks[1].date.first!)
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
    init() {
        calendar.firstWeekday = casManager.profileModel.value.settings.firstDayOfWeek
        
        initializeWeek()
        initializeMonth()
    }
    
    func selectedDateChange( _ day: Date) {
        selectedDate = day
        NotificationCenter.default.post(name: NSNotification.Name("selectedDateChange"), object: nil)
    }
    
    //MARK: - Logic for week
    func initializeWeek() {
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
    }
    
    func initializeMonth() {
        allMonths.removeAll()
        //MARK: Previous 4 weeks
        initPreviousMonths()
        
        let name = getMonthName(from: selectedDate)
        allMonths.append(PeriodModel(id: 1, date: generateMonth(for: selectedDate), name: name))
        
        var idNumber = 2
        
        for i in 1...4 {
            let month = calendar.date(byAdding: .month, value: i, to: selectedDate)!
            let newMonth = generateMonth(for: month)
            let name = getMonthName(from: month)
            allMonths.append(PeriodModel(id: idNumber, date: newMonth, name: name))
            idNumber += 1
        }
    }
    
    func initPreviousMonths() {
        for i in (1...60).reversed() {
            let month = calendar.date(byAdding: .month, value: -i, to: selectedDate)!
            let newMonth = generateMonth(for: month)
            let name = getMonthName(from: month)
            allMonths.append(PeriodModel(id: -i, date: newMonth, name: name))
        }
    }
    
    
    func startOfWeek(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
    }
    
    func changeIndexForWeek(_ index: Int) {
        indexForWeek = index
    }
    
    func selectedDayIsToday() -> Bool {
        !calendar.isDate(selectedDate, inSameDayAs: currentTime)
    }
    
    private func generateWeek(for date: Date) -> [Date] {
        let startOfWeek = startOfWeek(for: date)
        return (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
        }
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
    
    
    func appendWeeksForward() {
        guard let lastWeekStart = allWeeks.last?.date.first else { return }
        for i in 1...24 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: i, to: lastWeekStart)!
            let newWeek = generateWeek(for: weekStart)
            allWeeks.append(PeriodModel(id: allWeeks.last!.id + 1, date: newWeek))
        }
    }
    
    func prependWeeksBackward() {
        guard let firstWeekStart = allWeeks.first?.date.first else { return }
        for i in (1...24) {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: firstWeekStart)!
            let newWeek = generateWeek(for: weekStart)
            allWeeks.insert(PeriodModel(id: allWeeks.first!.id - 1, date: newWeek), at: 0)
        }
    }
    
    func appendMonthsBackward() {
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
    
    
    func appendMonthsForward() {
        guard let lastMonthStart = allMonths.last?.date.first else { return }
        for i in 1...24 {
            let monthStart = calendar.date(byAdding: .month, value: i, to: lastMonthStart)!
            let newMonth = generateMonth(for: monthStart)
            let nameOfMonth = getMonthName(from: monthStart)
            let nextID = (allMonths.last?.id ?? 0) + 1
            allMonths.append(PeriodModel(id: nextID, date: newMonth, name: nameOfMonth))
        }
    }
    
    func dateToString(for date: Date, format: String?, useForWeekView: Bool = false) -> LocalizedStringKey {
        if useForWeekView {
            return formatterDate(date: date, format: format)
        } else {
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInTomorrow(date) {
                return "Tomorrow"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                return formatterDate(date: date, format: format)
            }
        }
    }
    
    private func formatterDate(date: Date, format: String?) -> LocalizedStringKey {
        if let format = format {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale.current
            return LocalizedStringKey(formatter.string(from: date))
        }
        
        let weekday = selectedDate.formatted(.dateTime.weekday(.wide).locale(Locale.current))
        let dateString = selectedDate.formatted(.dateTime.day().month(.wide).year().locale(Locale.current))
        
        return LocalizedStringKey("\(weekday.capitalized) - \(dateString)")
    }
    
    func combineDateAndTime(timeComponents: DateComponents) -> Date {
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
    
    func createdtaskDate(task: TaskModel) -> Date {
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let componentsFromTask = calendar.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: task.notificationDate))
        
        dateComponents.hour = componentsFromTask.hour
        dateComponents.minute = componentsFromTask.minute
        
        return calendar.date(from: dateComponents)!
    }
    
    
    func getDefaultNotificationTime() -> Date {
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
    
    func updateNotificationDate(_ date: Double) -> Double {
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
    
    func addOneDay() {
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
    
    func subtractOneDay() {
        let currentDate = selectedDate
        let newDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        
        if let firstDate = allWeeks.first?.date.first, newDate < firstDate {
            prependWeeksBackward()
        }
        
        selectedDateChange(newDate)
        
        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
        let newWeek = calendar.component(.weekOfYear, from: newDate)
        
        if newWeek != currentWeek {
            updateWeekIndex(for: newDate)
        }
    }
    
    func backToToday() {
        initializeWeek()
        selectedDate = currentTime
        initializeWeek()
        indexForWeek = 1
    }
    
    
    private func updateWeekIndex(for date: Date) {
        let newWeekStart = startOfWeek(for: date)
        
        if let newWeek = allWeeks.first(where: { startOfWeek(for: $0.date.first!) == newWeekStart }) {
            indexForWeek = newWeek.id
        } else {
            appendWeeksForward()
            prependWeeksBackward()
            
            if let refreshedWeek = allWeeks.first(where: { startOfWeek(for: $0.date.first!) == newWeekStart }) {
                indexForWeek = refreshedWeek.id
            }
        }
    }
}
