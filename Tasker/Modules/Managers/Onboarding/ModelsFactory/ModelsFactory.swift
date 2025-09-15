//
//  ModelsFactory.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/7/25.
//

import Foundation
import Models
import SwiftUICore

@Observable
final class ModelsFactory {
    @ObservationIgnored
    @Injected(\.dateManager) var dateManager
    
    private var calendar: Calendar {
        dateManager.calendar
    }
    private var now: Date {
        dateManager.currentTime
    }
    
    var today = DateComponents()
    
    init() {
        today.year = calendar.component(.year, from: now)
        today.month = calendar.component(.month, from: now)
        today.day = calendar.component(.day, from: now)
    }
    
    private var selectedDate: Double {
        calendar.startOfDay(for: now).timeIntervalSince1970
    }
    
    func create(_ model: Models, repeatTask: RepeatTask? = .never) -> MainModel {
        switch model {
        case .bestApp:
            UITaskModel(
                .initial(
                    TaskModel(
                        title: "📱 Install the Best App",
                        description: "Mega task. Install the one app to rule them all. So... you did it",
                        createDate: Date.now.timeIntervalSince1970,
                        notificationDate: Date.now.timeIntervalSince1970,
                        done: [CompleteRecord(completedFor: selectedDate, timeMark: Date.now.timeIntervalSince1970)],
                        taskColor: .purple
                    )
                )
            )
        case .planForTommorow:
            UITaskModel(
                .initial(
                    TaskModel(
                        title: "🗓️ Plan Tomorrow",
                        description: "Maybe you'll save the world tomorrow. Might wanna write that down.",
                        createDate: Date.now.timeIntervalSince1970,
                        notificationDate: Double(calendar.date(bySettingHour: 20, minute: 30, second: 0, of: repeatTask == .never ? .now : dateManager.sunday())!.timeIntervalSince1970),
                        repeatTask: repeatTask,
                        taskColor: .mint
                    )
                )
            )
        case .randomHours:
            UITaskModel(
                .initial(
                    TaskModel(
                        title: "💡 Random Hour",
                        description: "Google something you don’t understand. Quantum foam? Why cats scream at 3 AM? Choose your adventure.",
                        createDate: Date.now.timeIntervalSince1970,
                        notificationDate: Double(calendar.date(bySetting: .hour, value: 19, of: calendar.date(from: today)!)!.timeIntervalSince1970),
                        repeatTask: .never,
                        taskColor: .steelBlue
                    )
                )
            )
        case .readSomething:
            UITaskModel(
                .initial(
                    TaskModel(
                        title: "📚 Read Something That’s Not a Screen",
                        description: "A book, a newspaper, a cereal box. Touch paper. Absorb knowledge.",
                        createDate: Date.now.timeIntervalSince1970,
                        notificationDate: Double(calendar.date(bySetting: .hour, value: 19, of: dateManager.thursday())!.timeIntervalSince1970),
                        repeatTask: .weekly,
                        taskColor: .brown
                    )
                )
            )
        }
    }
    
    
    
    enum Models {
        case randomHours
        case bestApp
        
        /// Every sunday
        case planForTommorow
        
        /// Every wedensday
        case readSomething
    }
}
