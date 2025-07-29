//
//  ModelsFactory.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/7/25.
//

import Foundation
import Models
import SwiftUICore

final class ModelsFactory {
    var calendar = Calendar.current
    var now = Date.now
    
    private var selectedDate: Double {
        calendar.startOfDay(for: now).timeIntervalSince1970
    }
    
    func create(_ model: Models) -> MainModel {
        switch model {
        case .drinkWater:
            MainModel.initial(
                TaskModel(
                    title: "💧 Drink Water",
                    info: "You’re not a cactus. Hydrate or evaporate.",
                    createDate: Date.now.timeIntervalSince1970,
                    notificationDate: Double(calendar.date(bySetting: .hour, value: 9, of: now)!.timeIntervalSince1970),
                    voiceMode: false,
                    repeatTask: .daily,
                    dayOfWeek: DayOfWeekEnum.dayOfWeekArray(for: calendar),
                    done: [],
                    deleted: [],
                    taskColor: .blue,
                )
            )
        case .clearMind:
            MainModel.initial(
                TaskModel(
                    title: "🧹 Clear Your Mind",
                    info: "Close your mental tabs. Breathe. Meditate or journal, or just stare into the void.",
                    createDate: Date.now.timeIntervalSince1970,
                    notificationDate: Double(calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now)!.timeIntervalSince1970),
                    voiceMode: false,
                    repeatTask: .daily,
                    dayOfWeek: DayOfWeekEnum.dayOfWeekArray(for: calendar),
                    done: [],
                    deleted: [],
                    taskColor: .lime
                )
            )
        case .bestApp:
            MainModel.initial(
                TaskModel(
                    title: "📱 Install the Best App",
                    info: "Mega task. Install the one app to rule them all. So... you did it",
                    createDate: Date.now.timeIntervalSince1970,
                    notificationDate: Date.now.timeIntervalSince1970,
                    voiceMode: false,
                    dayOfWeek: DayOfWeekEnum.dayOfWeekArray(for: calendar),
                    done: [CompleteRecord(completedFor: selectedDate, timeMark: Date.now.timeIntervalSince1970)],
                    deleted: [],
                    taskColor: .purple
                )
            )
        case .planForTommorow:
            MainModel.initial(
                TaskModel(
                    title: "🗓️ Plan Tomorrow",
                    info: "Maybe you'll save the world tomorrow. Might wanna write that down.",
                    createDate: Date.now.timeIntervalSince1970,
                    notificationDate: Double(calendar.date(bySettingHour: 20, minute: 30, second: 0, of: now)!.timeIntervalSince1970),
                    voiceMode: false,
                    repeatTask: .daily,
                    dayOfWeek: DayOfWeekEnum.dayOfWeekArray(for: calendar),
                    done: [],
                    deleted: [],
                    taskColor: .mint
                )
            )
        case .withoutPhone:
            MainModel.initial(
                TaskModel(
                    title: "📵 10 Minutes Without Phone",
                    info: "Put the glowing rectangle down. The world can wait. Breathe...",
                    createDate: Date.now.timeIntervalSince1970,
                    notificationDate: Double(calendar.date(bySetting: .hour, value: 14, of: now)!.timeIntervalSince1970),
                    voiceMode: false,
                    repeatTask: .daily,
                    dayOfWeek: DayOfWeekEnum.dayOfWeekArray(for: calendar),
                    done: [],
                    deleted: [],
                    taskColor: .red
                )
            )
            
        case .randomHours:
            MainModel.initial(
                TaskModel(
                    title: "💡 Random Hour",
                    info: "Google something you don’t understand. Quantum foam? Why cats scream at 3 AM? Choose your adventure.",
                    createDate: Date.now.timeIntervalSince1970,
                    notificationDate: Double(calendar.date(bySetting: .hour, value: 19, of: wedensday())!.timeIntervalSince1970),
                    voiceMode: false,
                    repeatTask: .weekly,
                    dayOfWeek: DayOfWeekEnum.dayOfWeekArray(for: calendar),
                    done: [],
                    deleted: [],
                    taskColor: .steelBlue
                )
            )
        case .readSomething:
            MainModel.initial(
                TaskModel(
                    title: "📚 Read Something That’s Not a Screen",
                    info: "A book, a newspaper, a cereal box. Touch paper. Absorb knowledge.",
                    createDate: Date.now.timeIntervalSince1970,
                    notificationDate: Double(calendar.date(bySetting: .hour, value: 19, of: saturday())!.timeIntervalSince1970),
                    voiceMode: false,
                    repeatTask: .weekly,
                    dayOfWeek: DayOfWeekEnum.dayOfWeekArray(for: calendar),
                    done: [],
                    deleted: [],
                    taskColor: .brown
                )
            )
        }
    }
    
    func wedensday() -> Date {
        let weekdayToday = calendar.component(.weekday, from: now)
        
        let daysUntilWednesday = (4 - weekdayToday + 7) % 7
        let targetDate = calendar.date(byAdding: .day, value: daysUntilWednesday, to: now)!
        
        return targetDate
    }
    
    func saturday() -> Date {
        let weekdayToday = calendar.component(.weekday, from: now)
        
        let daysUntilWednesday = (7 - weekdayToday + 7) % 7
        let targetDate = calendar.date(byAdding: .day, value: daysUntilWednesday, to: now)!
        
        return targetDate
    }
    
    
    enum Models {
        case drinkWater
        case clearMind
        case bestApp
        case planForTommorow
        case withoutPhone
        
        /// every wedensday
        case randomHours
        case readSomething
    }
}
