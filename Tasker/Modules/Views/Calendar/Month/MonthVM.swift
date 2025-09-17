//
//  MonthVM.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/9/25.
//

import Foundation
import Models
import Managers
import SwiftUI

@Observable
final class MonthVM {
    @ObservationIgnored
    @Injected(\.dateManager) var dateManager
    @ObservationIgnored
    @Injected(\.appearanceManager) var appearanceManager
    @ObservationIgnored
    @Injected(\.telemetryManager) var telemetryManager
    @ObservationIgnored
    @Injected(\.subscriptionManager) var subscriptionManager
    @ObservationIgnored
    @Injected(\.onboardingManager) var onboardingManager
    
    var showPaywall: Bool {
        subscriptionManager.showPaywall
    }
    
    var scrollID: Int?
    
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
    
    var allMonths: [PeriodModel] {
        dateManager.allMonths
    }
    
    func selectedDateChange(_ day: Date) {
        dateManager.selectedDateChange(day)
        dateManager.initializeWeek()
        
        // telemetry
        telemetryAction(.calendarAction(.selectedDateButtonTapped(.calendarView)))
    }
    
    func onAppear() async {
        scrollID = 1
        
        try? await Task.sleep(for: .seconds(0.5))
        
//        guard checkSubscription() else {
//            return
//        }
        
        telemetryAction(.openView(.calendar(.open)))
    }
    
    func checkSubscription() -> Bool {
        return subscriptionManager.hasSubscription()
    }
    
    func onDissapear() {
        subscriptionManager.showPaywall = false
        telemetryAction(.openView(.calendar(.close)))
    }
    
    func calculateEmptyDay(for month: PeriodModel) -> Int {
        guard let firstDate = month.date.first else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDate)
        
        let shift = (weekday - calendar.firstWeekday + 7) % 7
        return shift
    }
    
    func shiftedWeekdaySymbols() -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let weekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[weekdayIndex...] + symbols[..<weekdayIndex])
    }
    
    func isSameDay(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: today)
    }
    
    func isSelectedDay(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: selectedDate)
    }
    
    func selectedDayIsToday() -> Bool {
        !dateManager.selectedDayIsToday()
    }
    
    func backToTodayButtonTapped() {
        dateManager.backToToday()
        scrollID = 1
        dateManager.initializeMonth()
        
        // telemetry
        telemetryAction(.calendarAction(.backToTodayButtonTapped(.calendarView)))
    }
    
    func currentYear(_ month: PeriodModel) -> String? {
        let day = month.date.first!
        let year = calendar.component(.year, from: day)
        
        if year == calendar.component(.year, from: today) {
            return nil
        } else {
            return String(year)
        }
    }
    
    func closeScreenButtonTapped(path: inout NavigationPath, mainViewIsOpen: inout Bool) {
        path.removeLast()
        mainViewIsOpen = true
        
        // telemetry
        telemetryAction(.calendarAction(.backToSelectedDateButtonTapped(.calendarView)))
    }
    
    func automaticlyClossScreen(path: inout NavigationPath, mainViewIsOpen: inout Bool) {
        if showPaywall == false && !checkSubscription() {
            subscriptionManager.closePaywall()
            
            path.removeLast()
            mainViewIsOpen = true
            
            // telemetry
            telemetryAction(.calendarAction(.backToSelectedDateButtonTapped(.calendarView)))
        }
    }
    
    func handleMonthAppeared(_ month: PeriodModel) {
        if let last = allMonths.last, month.id >= last.id - 5 {
            dateManager.appendMonthsForward()
        }
    }
    
    //MARK: Telemtry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
