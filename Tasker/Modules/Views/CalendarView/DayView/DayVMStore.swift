//
//  DayVMStore.swift
//  AppDelegate
//
//  Created by Rodion Akhmedov on 1/23/26.
//

import Foundation
import AppearanceManager
import DateManager
import TaskManager
import Models

public final actor DayVMStore {
    private let appearanceManager: AppearanceManagerProtocol
    private let dateManager: DateManagerProtocol
    private let taskManager: TaskManagerProtocol
    
    private var dayVMs: [TimeInterval: DayViewVM] = [:]
    
    var weeks: [PeriodModel] {
        dateManager.allWeeks
    }
    
    var months: [PeriodModel] {
        dateManager.allMonths
    }
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
    }
    
    //MARK: - Create Store
    
    public static func createStore(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) -> DayVMStore {
        .init(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
    }
    
    func createWeekDayVMs() {
        let weekMap = Dictionary(uniqueKeysWithValues: weeks.map { ($0.id, $0.date) })
        
        let days = [
            weekMap[dateManager.indexForWeek - 2],
            weekMap[dateManager.indexForWeek - 1],
            weekMap[dateManager.indexForWeek],
            weekMap[dateManager.indexForWeek + 1],
            weekMap[dateManager.indexForWeek + 2]
        ]
            .compactMap { $0 }
            .flatMap { $0 }

        for day in days {
            let key = dateManager.startOfDay(for: day).timeIntervalSince1970
            guard dayVMs[key] == nil else { continue }
            
            let vm = DayViewVM.createVM(
                dateManager: dateManager,
                taskManager: taskManager,
                appearanceManager: appearanceManager,
                day: day
            )
            
            dayVMs[key] = vm
        }
    }
    
    func createMonthVMs(scrollID: Int?) {
        guard let scrollID else { return }
        
        let monthMap = Dictionary(uniqueKeysWithValues: months.map { ($0.id, $0.date) })
        
        let days = [
            monthMap[scrollID - 1],
            monthMap[scrollID],
            monthMap[scrollID + 1]
        ]
            .compactMap { $0 }
            .flatMap { $0 }
        
        let newDays = days.filter {
            let key = dateManager.startOfDay(for: $0).timeIntervalSince1970
            return dayVMs[key] == nil
        }
        
        guard !newDays.isEmpty else { return }
        
        let newVMs: [(TimeInterval, DayViewVM)] = newDays.map { day in
            let key = dateManager.startOfDay(for: day).timeIntervalSince1970
            let vm = DayViewVM.createVM(
                dateManager: dateManager,
                taskManager: taskManager,
                appearanceManager: appearanceManager,
                day: day
            )
            return (key, vm)
        }
        
        for (key, vm) in newVMs {
            dayVMs[key] = vm
        }
    }
    
    func returnDayVM(_ day: Date) -> DayViewVM? {
        let key = dateManager.startOfDay(for: day).timeIntervalSince1970
        return dayVMs[key]
    }
}
