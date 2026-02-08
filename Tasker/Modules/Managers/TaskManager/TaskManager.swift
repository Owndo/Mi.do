import Foundation
import Models
import CASManager
import TelemetryManager
import DateManager
import NotificationManager

//TODO: - only tasks

public final actor TaskManager: TaskManagerProtocol {
    
    private var casManager: CASManagerProtocol
    private var dateManager: DateManagerProtocol
    private var notificationManager: NotificationManagerProtocol
    private var telemetryManager: TelemetryManagerProtocol
    
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
    
    //MARK: Tasks properties
    
    public var tasks = [String: UITaskModel]()
    
    //MARK: - Cache
    
    private var activeTasksCache: [TimeInterval: [UITaskModel]] = [:]
    private var completedTasksCache: [TimeInterval: [UITaskModel]] = [:]
    
    private var dayTasksCache: [TimeInterval: [UITaskModel]] = [:]
    private var weekTasksCache: [TimeInterval: [UITaskModel]] = [:]
    //    private var monthTasksCache: [TimeInterval: [UITaskModel]] = [:]
    
    //MARK: - AsyncStream
    
    public var tasksStream: AsyncStream<Void>?
    private var continuation: AsyncStream<Void>.Continuation?
    
    public var updatedDayStream: AsyncStream<UITaskModel>?
    private var updatedDayStreamContinuation: AsyncStream<UITaskModel>.Continuation?
    
    //MARK: - Init
    
    private init(casManager: CASManagerProtocol, dateManager: DateManagerProtocol, notificationManager: NotificationManagerProtocol, telemetryManager: TelemetryManagerProtocol? = nil) {
        self.casManager = casManager
        self.dateManager = dateManager
        self.notificationManager = notificationManager
        self.telemetryManager = telemetryManager ?? TelemetryManager.createTelemetryManager()
    }
    
    //MARK: - Create
    
    public static func createTaskManager(casManager: CASManagerProtocol, dateManager: DateManagerProtocol, notificationManager: NotificationManagerProtocol) async -> TaskManagerProtocol {
        let manager = TaskManager(casManager: casManager, dateManager: dateManager, notificationManager: notificationManager)
        await manager.fetchTasksFromCAS()
        //      await manager.retrieveMonthTasks(for: Date())
        await manager.createStreams()
        
        return manager
    }
    
    //MARK: - Create MockTaskManager
    
    public static func createMockTaskManager() -> TaskManagerProtocol {
        let casManager = MockCas.createManager()
        let manager = TaskManager(casManager: casManager, dateManager: DateManager.createPreviewManager(), notificationManager: MockNotificationManager(), telemetryManager: MockTelemetryManager())
        
        return manager
    }
    
    //MARK: - Create Mock With Models
    
    public static func createMockTaskManagerWithModels() async -> TaskManagerProtocol {
        let casManager = MockCas.createManager()
        let manager = TaskManager(casManager: casManager, dateManager: DateManager.createPreviewManager(), notificationManager: MockNotificationManager(), telemetryManager: MockTelemetryManager())
        await manager.fakeModelForPreview()
        
        return manager
    }
    
    //MARK: - Create Stream
    
    private func createStreams() async {
        let (taskStream, taskCont) = AsyncStream<Void>.makeStream()
        
        self.tasksStream = taskStream
        self.continuation = taskCont
        
        let (updDayStream, updDayCont) = AsyncStream<UITaskModel>.makeStream()
        self.updatedDayStream = updDayStream
        self.updatedDayStreamContinuation = updDayCont
    }
    
    //MARK: - Fake Models For Preview
    
    func fakeModelForPreview() async {
        let task =  UITaskModel(
            .initial(
                TaskModel(
                    title: "New task",
                    notificationDate: Date.now.timeIntervalSince1970
                )
            )
        )
        
        let task1 = UITaskModel(
            .initial(
                TaskModel(
                    title: "New Task1",
                    notificationDate: Date.now.timeIntervalSince1970 + 150
                )
            )
        )
        
        tasks = [task.id: task, task1.id: task1]
    }
    
    func fetchTasksFromCAS() async {
        tasks = await casManager.fetchModels(TaskModel.self).reduce(into: [String: UITaskModel]()) { dict, model in
            let uiModel = UITaskModel(model)
            dict[uiModel.id] = uiModel
        }
        
    }
    
    //MARK: - Active Tasks
    
    public func activeTasks(for date: Date) async -> [UITaskModel] {
        let dayStart = dateManager.startOfDay(for: date).timeIntervalSince1970
        
        if let cached = activeTasksCache[dayStart] {
            return cached
        }
        
        let tasks = await retrieveDayTasks(for: date)
        
        let filteredTasks = tasks.filter { task in
            task.activeTask(calendar: calendar, date: dayStart)
        }
        
        activeTasksCache[dayStart] = filteredTasks
        return filteredTasks
    }
    
    //MARK: - Completed Tasks
    
    public func completedTasks(for date: Date) async -> [UITaskModel] {
        let dayStart = dateManager.startOfDay(for: date).timeIntervalSince1970
        
        if let cached = completedTasksCache[dayStart] {
            return cached
        }
        
        let tasks = await retrieveDayTasks(for: date)
        
        let filteredTasks = tasks.filter { task in
            task.completedTask(calendar: calendar, date: dayStart)
        }
        
        completedTasksCache[dayStart] = filteredTasks
        return filteredTasks
    }
    
    //MARK: - Retrieve Day Tasks
    
    public func retrieveDayTasks(for date: Date) async -> [UITaskModel] {
        let dayStart = dateManager.startOfDay(for: date).timeIntervalSince1970
        let dayKey = dayStart
        
        if let cached = dayTasksCache[dayKey] {
            return cached
        }
        
        await retrieveWeekTasks(for: date)
        
        let weekKey = dateManager.startOfWeek(for: date).timeIntervalSince1970
        let weekTasks = weekTasksCache[weekKey] ?? []
        
        let dayTasks = weekTasks.filter { task in
            task.isScheduledForDate(dayStart, calendar: calendar)
        }
        
        dayTasksCache[dayKey] = dayTasks
        return dayTasks
    }
    
    
    //MARK: - Week Tasks
    
    @discardableResult
    private func retrieveWeekTasks(for date: Date) async -> [UITaskModel]? {
        let startOfWeek = dateManager.startOfWeek(for: date)
        let weekKey = startOfWeek.timeIntervalSince1970
        
        if let cached = weekTasksCache[weekKey] {
            return cached
        }
        
        let tasks = tasks.values.map { $0 }
        
        let days: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
        
        var weekTasksSet = Set<UITaskModel>()
        
        for day in days {
            let dayKey = day.timeIntervalSince1970
            
            let tasksForDay = tasks.filter {
                $0.isScheduledForDate(dayKey, calendar: calendar)
            }
            
            for task in tasksForDay {
                weekTasksSet.insert(task)
            }
        }
        
        let weekTasks = Array(weekTasksSet)
        
        weekTasksCache[weekKey] = weekTasks
        return weekTasks
    }
    
    //    //MARK: - Month Tasks
    //
    //    @discardableResult
    //    private func retrieveMonthTasks(for date: Date) async -> [UITaskModel]? {
    //        let startOfMonth = dateManager.startOfMonth(for: date)
    //        let key = startOfMonth.timeIntervalSince1970
    //
    //        if let cached = monthTasksCache[key] {
    //            return cached
    //        }
    //
    //        return tasks.values.map { $0 }
    //
    //
    ////        for date in dates {
    ////            let tasks = self.tasks.values.filter { $0.isScheduledForDate(key, calendar: calendar) }
    ////
    ////            for task in tasks {
    ////                setOfTasks.insert(task)
    ////            }
    ////        }
    //
    ////        monthTasksCache[key] = Array(setOfTasks)
    ////        return monthTasksCache[key]
    //    }
    
    //MARK: - Invalidate Tasks Cache
    
    private func invalidateTasksCache() {
            activeTasksCache.removeAll()
            completedTasksCache.removeAll()
            dayTasksCache.removeAll()
            weekTasksCache.removeAll()
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
        task.completeRecords = updateExistingTaskCompletion(task: task)
        
        try await saveTask(task)
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
        
        tasks[task.id] = task
        
        invalidateTasksCache()
        
        continuation?.yield()
        updatedDayStreamContinuation?.yield(task)
        
        await updateNotifications()
    }
    
    // MARK: - Delete task
    
    public func deleteTask(task: UITaskModel, deleteCompletely: Bool = false) async throws {
        if deleteCompletely {
            try await casManager.deleteModel(task.model)
            tasks.removeValue(forKey: task.id)
            
            invalidateTasksCache()
            
            continuation?.yield()
            updatedDayStreamContinuation?.yield(task)
        } else {
            task.deleteRecords = updateExistingTaskDeleted(task: task)
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
        await notificationManager.createNotification(tasks: tasks.map { $0.value })
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
