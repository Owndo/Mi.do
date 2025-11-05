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
public extension UITaskModel {
    
    //    func determinateID() -> String {
    //        let encoder = JSONEncoder()
    //        encoder.outputFormatting = [.sortedKeys]
    //
    //        do {
    //            let data = try encoder.encode(self)
    //            return data.base32()
    //        } catch {
    //            print("Couldn't create hash for task")
    //            return UUID().uuidString
    //        }
    //    }
    ///Function for check schedule task
    func isScheduledForDate(_ date: Double, calendar: Calendar = Calendar.current) -> Bool {
        // ✅ СРАЗУ нормализуем даты до startOfDay
        let selectedDay = calendar.startOfDay(for: Date(timeIntervalSince1970: date)).timeIntervalSince1970
        let taskDay = calendar.startOfDay(for: Date(timeIntervalSince1970: self.notificationDate)).timeIntervalSince1970
        
        // Проверка на удаление
        guard !self.deleteRecords.contains(where: { $0.deletedFor == selectedDay }) else {
            return false
        }
        
        // Для разовых задач - просто сравниваем дни
        if self.repeatTask == .never {
            return taskDay == selectedDay  // ✅ Сравниваем startOfDay
        }
        
        // Задача не может показаться ДО даты создания
        guard selectedDay >= taskDay else {
            return false
        }
        
        // Проверка deadline
        if let deadline = self.deadline {
            let endDay = calendar.startOfDay(for: Date(timeIntervalSince1970: deadline)).timeIntervalSince1970
            guard selectedDay <= endDay else { return false }
        }
        
        // Для повторяющихся задач используем Date для component()
        let selectedDate = Date(timeIntervalSince1970: selectedDay)
        let taskDate = Date(timeIntervalSince1970: taskDay)
        
        switch self.repeatTask {
        case .never:
            return true  // Уже проверили выше
            
        case .daily:
            return true
            
        case .weekly:
            let taskWeekday = calendar.component(.weekday, from: taskDate)
            let selectedWeekday = calendar.component(.weekday, from: selectedDate)
            return taskWeekday == selectedWeekday
            
        case .monthly:
            let taskDayOfMonth = calendar.component(.day, from: taskDate)
            let selectedDayOfMonth = calendar.component(.day, from: selectedDate)
            return taskDayOfMonth == selectedDayOfMonth
            
        case .yearly:
            let taskMonth = calendar.component(.month, from: taskDate)
            let taskDayOfMonth = calendar.component(.day, from: taskDate)
            let selectedMonth = calendar.component(.month, from: selectedDate)
            let selectedDayOfMonth = calendar.component(.day, from: selectedDate)
            return taskMonth == selectedMonth && taskDayOfMonth == selectedDayOfMonth
            
        case .dayOfWeek:
            let selectedWeekday = calendar.component(.weekday, from: selectedDate)
            let actualDays = self.dayOfWeek.actualyDayOFWeek(calendar)
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
