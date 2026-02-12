//
//  CalendarAction.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/21/25.
//

import Foundation

// MARK: - Calendar Action Enum
public enum CalendarAction {
    case selectedDateButtonTapped(PlaceForDateChange)
    case changeWeekScrolled(WeekScrollDirection)
    case backToTodayButtonTapped(PlaceForDateChange)
    case backToSelectedDateButtonTapped(PlaceForDateChange)
}

// MARK: - Supporting Enums
public enum PlaceForDateChange {
    case mainView
    case calendarView
}

public enum WeekScrollDirection {
    case forward
    case backward
}

// MARK: - Helper Extensions
extension PlaceForDateChange {
    var displayName: String {
        switch self {
        case .mainView:
            return "Main view"
        case .calendarView:
            return "Calendar view"
        }
    }
}

extension WeekScrollDirection {
    var analyticsValue: String {
        switch self {
        case .forward:
            return "Future"
        case .backward:
            return "Past"
        }
    }
}

extension CalendarAction: AnalyticsTrackable {
    var eventName: String {
        switch self {
        case .selectedDateButtonTapped:
            return "Date change"
        case .changeWeekScrolled:
            return "WeekScroll"
        case .backToTodayButtonTapped:
            return "Back to today"
        case .backToSelectedDateButtonTapped:
            return "Back to selected date"
        }
    }
    
    var properties: [String: Any]? {
        switch self {
        case .selectedDateButtonTapped(let place):
            return ["Change from": place.displayName]
        case .changeWeekScrolled(let direction):
            return ["Direction": direction.analyticsValue]
        case .backToTodayButtonTapped(let place):
            return ["Tapped from": place.displayName]
        case .backToSelectedDateButtonTapped(let place):
            return ["Tapped from": place.displayName]
        }
    }
}

