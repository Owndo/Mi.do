import Foundation
import Models
import CASManager
import TelemetryManager
import DateManager
import NotificationManager

public final actor TaskManager: TaskManagerProtocol {
    
    private var casManager: CASManagerProtocol
    private var dateManager: DateManagerProtocol
    private var notificationManager: NotificationManagerProtocol
    private var telemetryManager: TelemetryManagerProtocol
    
    private var weekTasksCache: [Double: [UITaskModel]] = [:] // key: startOfWeek timestamp
    
    //MARK: Computer properties
    private var calendar: Calendar {
        dateManager.calendar
    }
    
    private var selectedDate: Double {
        calendar.startOfDay(for: Date(timeIntervalSince1970: dateManager.selectedDate.timeIntervalSince1970)).timeIntervalSince1970
    }
    
    private var currentTime: Double {
        dateManager.currentTime.timeIntervalSince1970
    }
    
    private func startOfWeek(for date: Date) -> Double {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start.timeIntervalSince1970 ?? 0
    }
    
    private var firstWeekDate: Double? {
        let allDates = dateManager.allWeeks.flatMap { $0.date }
        return allDates.min()?.timeIntervalSince1970
    }
    
    private var lastWeekDate: Double? {
        let allDates = dateManager.allWeeks.flatMap { $0.date }
        return allDates.max()?.timeIntervalSince1970
    }
    
    //MARK: Tasks properties
    public var tasks = [String: UITaskModel]()
    
    public var activeTasks: [UITaskModel] { returnActiveTasks() }
    public var completedTasks: [UITaskModel] { returnCompletedTasks() }
    
    private var thisWeekCasheTasks: [UITaskModel] = []
    private var cacheWeekStart: Double = 0
    private var cacheWeekEnd: Double = 0
    
    private var dateObserverTask: Task<Void, Never>?
    
    //MARK: - Init
    
    private init(casManager: CASManagerProtocol, dateManager: DateManagerProtocol, notificationManager: NotificationManagerProtocol, telemetryManager: TelemetryManagerProtocol) {
        self.casManager = casManager
        self.dateManager = dateManager
        self.notificationManager = notificationManager
        self.telemetryManager = telemetryManager
    }
    
    //MARK: - Deinit
    
    deinit {
        dateObserverTask?.cancel()
    }
    
    public static func createTaskManager(
        casManager: CASManagerProtocol,
        dateManager: DateManagerProtocol,
        notificationManager: NotificationManagerProtocol,
        telemetryManager: TelemetryManagerProtocol
    ) async -> TaskManagerProtocol {
        let manager = TaskManager(casManager: casManager, dateManager: dateManager, notificationManager: notificationManager, telemetryManager: telemetryManager)
        await manager.setTasks(await manager.updateTasks())
        
        Task { await manager.updateNotifications() }
        
        return manager
    }
    
    public static func createMockTaskManager() -> TaskManagerProtocol {
        TaskManager(casManager: MockCas.createCASManager(), dateManager: DateManager.createMockDateManager(), notificationManager: MockNotificationManager(), telemetryManager: MockTelemetryManager())
    }
    
    //MARK: - Update tasks
    
    private func updateTasks() async -> [String: UITaskModel] {
        dateObserverTask = Task { [weak self] in
            guard let self = self else { return }
            
            for await _ in await self.dateManager.dateChanges {
                guard !Task.isCancelled else { break }
                
                await self.setTasks(await self.updateTasks())
            }
        }
        
        return await casManager.fetchModels(TaskModel.self)
            .reduce(into: [String: UITaskModel]()) { dict, model in
                let uiModel = UITaskModel(.initial(model))
                guard uiModel.isScheduledForDate(selectedDate, calendar: calendar) else { return }
                dict[uiModel.id] = uiModel
            }
    }
    
    private func setTasks(_ tasks: [String: UITaskModel]) {
        self.tasks = tasks
    }
    
    //MARK: Return active tasks
    
    private func returnActiveTasks() -> [UITaskModel] {
        let filtered = tasks.values.filter { value in
            value.completeRecords.contains { $0.completedFor == selectedDate } != true
        }
        
        return sortedTasks(tasks: filtered)
    }
    
    //MARK: Return completed tasks
    
    private func returnCompletedTasks() -> [UITaskModel] {
        let filtered = tasks.values.filter { value in
            value.completeRecords.contains { $0.completedFor == selectedDate }
        }
        
        return sortedTasks(tasks: filtered)
    }
    
    //MARK: - Sorted tasks
    private func sortedTasks(tasks: [UITaskModel]) -> [UITaskModel] {
        tasks.sorted {
            let hour1 = calendar.component(.hour, from: Date(timeIntervalSince1970: $0.notificationDate))
            let hour2 = calendar.component(.hour, from: Date(timeIntervalSince1970: $1.notificationDate))
            
            let minutes1 = calendar.component(.minute, from: Date(timeIntervalSince1970: $0.notificationDate))
            let minutes2 = calendar.component(.minute, from: Date(timeIntervalSince1970: $1.notificationDate))
            
            return (hour1, minutes1, $0.createDate) < (hour2, minutes2, $1.createDate)
        }
    }
    
    //MARK: - Cashe for week
    
    public func thisWeekTasks(date: Double) async -> [UITaskModel] {
        return tasks.values
            .filter { task in
                return task.deleteRecords.contains { $0.deletedFor == date } != true
            }
    }
    
    private func isTaskInWeeksRange(_ task: UITaskModel, startDate: Double, endDate: Double) -> Bool {
        var currentInterval = startDate
        
        while currentInterval <= endDate {
            if task.isScheduledForDate(currentInterval, calendar: calendar) {
                return true
            }
            
            currentInterval += 86400
        }
        
        return false
    }
    
    // MARK: - Completion Management
    
    public func checkCompletedTaskForToday(task: UITaskModel) -> Bool {
        task.completeRecords.contains(where: { $0.completedFor == selectedDate })
    }
    // MARK: - Check mark tapped
    
    public func checkMarkTapped(task: UITaskModel) async throws {
        let model = task
        model.completeRecords = updateExistingTaskCompletion(task: task)
        
        try await saveTask(model)
        
        await updateNotifications()
    }
    
    private func updateExistingTaskCompletion(task: UITaskModel) -> [CompleteRecord] {
        guard !task.completeRecords.isEmpty else {
            return [createNewTaskCompletion(task: task)]
        }
        
        if let existingIndex = task.completeRecords.firstIndex(where: { $0.completedFor == selectedDate }) {
            var updatedRecords = task.completeRecords
            updatedRecords.remove(at: existingIndex)
            // telemetry
            telemetryAction(.taskAction(.uncompleteButtonTapped))
            return updatedRecords
        } else {
            var updatedRecords = task.completeRecords
            updatedRecords.append(createNewTaskCompletion(task: task))
            
            // telemetry
            telemetryAction(.taskAction(.completeButtonTapped))
            return updatedRecords
        }
    }
    
    private func createNewTaskCompletion(task: UITaskModel) -> CompleteRecord {
        CompleteRecord(completedFor: selectedDate, timeMark: currentTime)
    }
    
    //MARK: - Store audio
    
    public func storeAudio(_ audio: Data) async throws -> String? {
        try await casManager.storeAudio(audio)
    }
    
    //MARK: - Save Task
    
    public func saveTask(_ task: UITaskModel) async throws {
        try await casManager.saveModel(task.model)
        
        guard calendar.isDate(Date(timeIntervalSince1970: task.notificationDate), inSameDayAs: dateManager.selectedDate) else {
            return
        }
        
        tasks[task.id] = task
    }
    
    // MARK: - Delete task
    
    public func deleteTask(task: UITaskModel, deleteCompletely: Bool = false) async throws {
        guard task.markAsDeleted == false else {
            return
        }
        
        let model = task
        if deleteCompletely {
            try await casManager.deleteModel(task.model)
            tasks.removeValue(forKey: task.id)
        } else {
            model.deleteRecords = updateExistingTaskDeleted(task: model)
            try await saveTask(task)
        }
        
        await updateNotifications()
        
        if task.repeatTask == .never {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteSingleTask(.taskListView))))
        }
        
        if task.repeatTask != .never && deleteCompletely == true {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteAllTasks(.taskListView))))
        }
        
        if task.repeatTask != .never && deleteCompletely == false {
            telemetryAction(.taskAction(.deleteButtonTapped(.deleteOneOfManyTasks(.taskListView))))
        }
    }
    
    public func updateExistingTaskDeleted(task: UITaskModel) -> [DeleteRecord] {
        var newDeletedRecords: [DeleteRecord] = task.deleteRecords
        newDeletedRecords.append(DeleteRecord(deletedFor: selectedDate, timeMark: currentTime))
        return newDeletedRecords
    }
    
    public func updateNotifications() async {
        await notificationManager.createNotification(tasks: tasks.map{ $0.value })
    }
    
    //MARK: - Move to next Day
    public func updateNotificationTimeForDueDate(task: UITaskModel) -> UITaskModel {
        let model = task
        
        model.notificationDate = dateManager.updateNotificationDate(model.notificationDate)
        
        return model
    }
    
    //MARK: Deadline logic
    public func dayUntillDeadLine(_ task: UITaskModel) -> Int? {
        guard task.deadline != nil else {
            return nil
        }
        
        guard task.repeatTask != .never else {
            return nil
        }
        
        let today = Date(timeIntervalSince1970: currentTime)
        let notificationDate = Date(timeIntervalSince1970: task.notificationDate)
        
        var day: Date
        var lastActualDay: Date
        
        if calendar.isDate(notificationDate, inSameDayAs: today) || notificationDate <= today {
            day = today
            lastActualDay = today
            
            while task.isScheduledForDate(day.timeIntervalSince1970, calendar: calendar) {
                lastActualDay = day
                
                if task.repeatTask == .weekly {
                    day = calendar.date(byAdding: .day, value: 7, to: day)!
                } else if task.repeatTask == .monthly {
                    day = calendar.date(byAdding: .month, value: 1, to: day)!
                } else if task.repeatTask == .yearly {
                    day = calendar.date(byAdding: .year, value: 1, to: day)!
                } else {
                    day = calendar.date(byAdding: .day, value: 1, to: day)!
                }
            }
            
            let difference = calendar.dateComponents([.day], from: today, to: lastActualDay)
            return difference.day ?? 0
            
        } else {
            day = notificationDate
            lastActualDay = notificationDate
            
            while task.isScheduledForDate(day.timeIntervalSince1970, calendar: calendar) {
                lastActualDay = day
                
                if task.repeatTask == .weekly {
                    day = calendar.date(byAdding: .day, value: 7, to: day)!
                } else if task.repeatTask == .monthly {
                    day = calendar.date(byAdding: .month, value: 1, to: day)!
                } else if task.repeatTask == .yearly {
                    day = calendar.date(byAdding: .year, value: 1, to: day)!
                } else {
                    day = calendar.date(byAdding: .day, value: 1, to: day)!
                }
            }
            
            let todayToNotification = calendar.dateComponents([.day], from: today, to: notificationDate)
            let notificationToLast = calendar.dateComponents([.day], from: notificationDate, to: lastActualDay)
            
            return (todayToNotification.day ?? 0) + (notificationToLast.day ?? 0)
        }
    }
    
    private func isAfter9PM(_ date: Date) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= 21
    }
    
    //MARK: Telemetry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
