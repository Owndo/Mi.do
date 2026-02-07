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
    
    var dayVMs: [TimeInterval: DayViewVM] = [:]
    
    private var asyncStreamTask: Task<Void, Never>?
    
    var weeks: [Week] {
        dateManager.allWeeks
    }
    
    var months: [Month] {
        dateManager.allMonths
    }
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
    }
    
    func asyncUpdateDayVM() async {
        asyncStreamTask = Task { [weak self] in
            guard let self else { return }
            
            async let updDayStream: () = listenUpdatedDateStream()
            
            _ = await updDayStream
        }
    }
    
    private func listenUpdatedDateStream() async {
        guard let stream = await taskManager.updatedDayStream else { return }
        
        for await i in stream {
            await updateOneDayVM(i)
        }
    }
    
    private func updateOneDayVM(_ date: Date) async {
        let key = dateManager.startOfDay(for: date).timeIntervalSince1970
        
        guard let day = dayVMs[key] else { return }
        await day.updateTasks()
        print("udate for \(day.day.date)")
    }
    
    //MARK: - Create Store
    
    public static func createStore(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) async -> DayVMStore {
        let vm = DayVMStore(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
        await vm.asyncUpdateDayVM()
        
        return vm
    }
    
    //MARK: - Create PreviewStore
    
    public static func createPreviewStore(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) -> DayVMStore {
        let vm = DayVMStore(appearanceManager: appearanceManager, dateManager: dateManager, taskManager: taskManager)
        
        return vm
    }
    
    func createWeekDayVMs() {
        let weekMap = Dictionary(uniqueKeysWithValues: weeks.map { ($0.index!, $0.days) })
        
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
            let key = dateManager.startOfDay(for: day.date).timeIntervalSince1970
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
    
//    func createMonthDayVMs() {
//        let weekMap = Dictionary(uniqueKeysWithValues: months.map { ($0, $0.date) })
//        
//        let days = [
//            weekMap[dateManager.indexForWeek - 2],
//            weekMap[dateManager.indexForWeek - 1],
//            weekMap[dateManager.indexForWeek],
//            weekMap[dateManager.indexForWeek + 1],
//            weekMap[dateManager.indexForWeek + 2]
//        ]
//            .compactMap { $0 }
//            .flatMap { $0 }
//        
//        for day in days {
//            let key = dateManager.startOfDay(for: day.date).timeIntervalSince1970
//            guard dayVMs[key] == nil else { continue }
//            
//            let vm = DayViewVM.createVM(
//                dateManager: dateManager,
//                taskManager: taskManager,
//                appearanceManager: appearanceManager,
//                day: day
//            )
//            
//            dayVMs[key] = vm
//        }
//    }
    
    func returnDayVM(_ day: Day) -> DayViewVM? {
        let key = dateManager.startOfDay(for: day.date).timeIntervalSince1970
        
        guard dayVMs[key] != nil else {
            return DayViewVM.createVM(dateManager: dateManager, taskManager: taskManager, appearanceManager: appearanceManager, day: day)
        }
        
        return dayVMs[key]
    }
}
