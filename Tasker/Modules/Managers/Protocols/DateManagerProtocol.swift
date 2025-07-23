//
//  DateManagerProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Combine
import Foundation
import Models

public protocol DateManagerProtocol {
    var calendar: Calendar { get set }
    var currentTime: Date { get }
    var selectedDate: Date { get set }
    var indexForWeek: Int { get set }
    var allWeeks: [PeriodModel] { get set }
    var allMonths: [PeriodModel] { get set }
    
    func initializeWeek()
    func initializeMonth()
    func startOfWeek(for date: Date) -> Date
    func selectedDateChange(_ day: Date)
    func appendWeeksForward()
    func prependWeeksBackward()
    func appendMonthsForward()
    func appendMonthsBackward()
    /// Converte date to string
    func dateToString(for date: Date, format: String?, useForWeekView: Bool) -> String
    func createdtaskDate(task: TaskModel) -> Date
    /// Combine date from selected date and notification date
    func combineDateAndTime(timeComponents: DateComponents) -> Date
    /// Defaul time for notification
    func getDefaultNotificationTime() -> Date
    /// Change notification to next dat
    func updateNotificationDate(_ date: Double) -> Double
    /// Reset selected day to current current
    func backToToday()
    func selectedDayIsToday() -> Bool
    /// Next day after swipe to left
    func addOneDay()
    /// Previous day after swip to right
    func subtractOneDay()
}
