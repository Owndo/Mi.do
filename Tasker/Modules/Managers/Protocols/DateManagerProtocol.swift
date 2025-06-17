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
    var calendar: Calendar { get }
    var currentTime: Date { get set }
    var selectedDate: Date { get set }
    var indexForWeek: Int { get set }
    var allWeeks: [PeriodModel] { get set }
    var allMonths: [PeriodModel] { get set }
    
    func initializeWeek()
    func startOfWeek(for date: Date) -> Date
    func selectedDateChange(_ day: Date)
    func appendWeeksForward()
    func prependWeeksBackward()
    /// Converte date to string
    func dateToString(for date: Date, format: String?, useForWeekView: Bool) -> String
    /// Combine date from selected date and notification date
    func combineDateAndTime(timeComponents: DateComponents) -> Date
    func getDefaultNotificationTime() -> Date
    /// Reset selected day to current current
    func backToToday()
    /// Next day after swipe to left
    func addOneDay()
    /// Previous day after swip to right
    func subtractOneDay()
}
