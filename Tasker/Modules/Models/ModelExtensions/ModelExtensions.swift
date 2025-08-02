//
//  Extensions.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 6/13/25.
//

import Foundation
import BlockSet
import SwiftUI

//MARK: - Check for visible
public extension TaskModel {
    
    func determinateID() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        
        do {
            let data = try encoder.encode(self)
            return data.base32()
        } catch {
            print("Couldn't create hash for task")
            return UUID().uuidString
        }
    }
    ///Function for check schedule task
    func isScheduledForDate(_ date: Double, calendar: Calendar = Calendar.current) -> Bool {
        let taskNotificationDate = self.notificationDate
        
        let dateAsDate = Date(timeIntervalSince1970: date)
        let taskNotificationDateAsDate = Date(timeIntervalSince1970: taskNotificationDate)
        
        guard dateAsDate >= calendar.startOfDay(for: taskNotificationDateAsDate) else {
            return false
        }
        
        if let endDate = self.endDate {
            let taskEndDate = Date(timeIntervalSince1970: endDate)
            guard dateAsDate <= taskEndDate else {
                return false
            }
        }
        
        switch self.repeatTask {
        case .never:
            return taskNotificationDate >= date &&
            taskNotificationDate < date + 86400
            
        case .daily:
            return true
            
        case .weekly:
            let taskWeekday = calendar.component(.weekday, from: taskNotificationDateAsDate)
            let selectedWeekday = calendar.component(.weekday, from: dateAsDate)
            return taskWeekday == selectedWeekday
            
        case .monthly:
            let taskDay = calendar.component(.day, from: taskNotificationDateAsDate)
            let selectedDay = calendar.component(.day, from: dateAsDate)
            return taskDay == selectedDay
            
        case .yearly:
            let taskMonth = calendar.component(.month, from: taskNotificationDateAsDate)
            let taskDay = calendar.component(.day, from: taskNotificationDateAsDate)
            let selectedMonth = calendar.component(.month, from: dateAsDate)
            let selectedDay = calendar.component(.day, from: dateAsDate)
            return taskMonth == selectedMonth && taskDay == selectedDay
            
        case .dayOfWeek:
            let selectedWeekday = calendar.component(.weekday, from: dateAsDate)
            
            var orderedDayOfWeek = self.dayOfWeek
            let actualDays = orderedDayOfWeek.actualyDayOFWeek(calendar)
            
            let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let selectedDayName = dayNames[selectedWeekday - 1]
            
            guard let dayOfWeek = actualDays.first(where: { $0.name == selectedDayName }) else {
                return false
            }
            
            return dayOfWeek.value
        }
    }
    
    
    func hexToCGColor(hex: String) -> CGColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        
        guard hexSanitized.count == 6 || hexSanitized.count == 8 else { return CGColor.init(gray: 0, alpha: 0) }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        let alpha: CGFloat = hexSanitized.count == 8 ? CGFloat((rgb >> 24) & 0xFF) / 255.0 : 1.0
        
        return CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

//MARK: Only for mock in TaskModel init
extension Array where Element == DayOfWeek {
    public static let `default` = [
        DayOfWeek(name: "Sun", value: false),
        DayOfWeek(name: "Mon", value: false),
        DayOfWeek(name: "Tue", value: false),
        DayOfWeek(name: "Wed", value: false),
        DayOfWeek(name: "Thu", value: false),
        DayOfWeek(name: "Fri", value: false),
        DayOfWeek(name: "Sat", value: false)
    ]
}

//MARK: - Converte String to Color
public extension String {
    func hexColor() -> Color {
        let hex = self.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, int >> 24)
        default:
            return .black
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
