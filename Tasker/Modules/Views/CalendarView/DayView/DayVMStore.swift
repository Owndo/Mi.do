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
    
    var asyncStream: AsyncStream<Void>
    var continuation: AsyncStream<Void>.Continuation
    
    var weeks: [Week] {
        dateManager.allWeeks
    }
    
    var months: [Month] {
        dateManager.allMonths
    }
    
    var selectedDate: Date {
        dateManager.selectedDate
    }
    
    //MARK: - Private init
    
    private init(appearanceManager: AppearanceManagerProtocol, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.dateManager = dateManager
        self.taskManager = taskManager
        
        let (stream, cont) = AsyncStream.makeStream(of: Void.self)
        self.asyncStream = stream
        self.continuation = cont
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
    
    
    //MARK: - Async update
    
    func asyncUpdateDayVM() async {
        asyncStreamTask = Task { [weak self] in
            guard let self else { return }
            
            async let updDayStream: () = listenUpdatedDateStream()
            
            _ = await updDayStream
        }
    }
    
    //MARK: - Async Listener
    
    private func listenUpdatedDateStream() async {
        guard let stream = await taskManager.updatedDayStream else { return }
        
        for await _ in stream {
            let week = dateManager.generateWeek(for: selectedDate)
            
            for day in week.days {
                await updateOneDayVM(day.date)
            }
            
            let validKeys = Set(week.days.map { $0.date.timeIntervalSince1970 })
            dayVMs = dayVMs.filter { validKeys.contains($0.key) }
            
            continuation.yield()
        }
    }
    
    //MARK: - Update one dayVM
    
    private func updateOneDayVM(_ date: Date) async {
        let key = dateManager.startOfDay(for: date).timeIntervalSince1970
        
        guard let day = dayVMs[key] else { return }
        await day.updateTasks(update: true)
    }
    
    func returnDayVM(_ day: Day) -> DayViewVM? {
        let key = dateManager.startOfDay(for: day.date).timeIntervalSince1970
        
        guard dayVMs[key] != nil else {
            let vm = DayViewVM.createVM(dateManager: dateManager, taskManager: taskManager, appearanceManager: appearanceManager, day: day)
            dayVMs[key] = vm
            return vm
        }
        
        return dayVMs[key]
    }
}
