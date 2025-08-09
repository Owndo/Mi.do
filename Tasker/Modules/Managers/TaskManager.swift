import Foundation
import Models

@Observable
final class TaskManager: TaskManagerProtocol {
    @ObservationIgnored
    @Injected(\.casManager) private var casManager
    @ObservationIgnored
    @Injected(\.dateManager) private var dateManager
    @ObservationIgnored
    @Injected(\.notificationManager) var notificationManager
    @ObservationIgnored
    @Injected(\.telemetryManager) private var telemetryManager: TelemetryManagerProtocol
    
    private var weekTasksCache: [Double: [MainModel]] = [:] // key: startOfWeek timestamp
    
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
    
    //MARK: Tasks logic
    var tasks: [MainModel] {
        let models = casManager.models.values.filter { value in
            value.deleted.contains { $0.deletedFor == selectedDate } != true &&
            value.isScheduledForDate(selectedDate, calendar: calendar)
        }
        return sortedTasks(tasks: models)
    }
    
    var completedTasks: [MainModel] {
        tasks.filter {
            $0.done.contains { $0.completedFor == selectedDate }
        }
    }
    
    var activeTasks: [MainModel] {
        tasks.filter {
            $0.done.contains { $0.completedFor == selectedDate } != true
        }
    }
    
    func thisWeekTasks(date: Double) async -> [MainModel] {
        return casManager.models.values
            .filter { task in
                return task.deleted.contains { $0.deletedFor == date } != true
            }
    }
    
    func sortedTasks(tasks: [MainModel]) -> [MainModel] {
        tasks.sorted {
            let hour1 = calendar.component(.hour, from: Date(timeIntervalSince1970: $0.notificationDate))
            let hour2 = calendar.component(.hour, from: Date(timeIntervalSince1970: $1.notificationDate))
            
            let minutes1 = calendar.component(.minute, from: Date(timeIntervalSince1970: $0.notificationDate))
            let minutes2 = calendar.component(.minute, from: Date(timeIntervalSince1970: $1.notificationDate))
            
            return hour1 < hour2 || (hour1 == hour2 && minutes1 < minutes2)
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
    
    //MARK: - Prepeare task before save
    //    func preparedTask(task: UITaskModel, date: Date) -> UITaskModel {
    //        let filledTask = task
    //
    //        filledTask.notificationDate = date.timeIntervalSince1970
    //        filledTask.endDate = task.endDate
    //        filledTask.speechDescription = task.speechDescription
    //        filledTask.done = task.done
    //        filledTask.taskColor = task.taskColor
    //        filledTask.repeatTask = task.repeatTask
    //        filledTask.audio = task.audio
    //        filledTask.voiceMode = task.voiceMode
    //        filledTask.deleted = task.deleted
    //        filledTask.markAsDeleted = task.markAsDeleted
    //        filledTask.endDate = task.endDate
    //        filledTask.secondNotificationDate = task.secondNotificationDate
    //
    //        return filledTask
    //    }
    
    // MARK: - Completion Management
    func checkCompletedTaskForToday(task: UITaskModel) -> Bool {
        task.done.contains(where: { $0.completedFor == selectedDate })
    }
    
    func checkMarkTapped(task: UITaskModel) -> UITaskModel {
        let model = task
        model.done = updateExistingTaskCompletion(task: task)
        return model
    }
    
    private func updateExistingTaskCompletion(task: UITaskModel) -> [CompleteRecord] {
        guard !task.done.isEmpty else {
            return [createNewTaskCompletion(task: task)]
        }
        
        if let existingIndex = task.done.firstIndex(where: { $0.completedFor == selectedDate }) {
            var updatedRecords = task.done
            updatedRecords.remove(at: existingIndex)
            // telemetry
            telemetryAction(.taskAction(.uncompleteButtonTapped))
            return updatedRecords
        } else {
            var updatedRecords = task.done
            updatedRecords.append(createNewTaskCompletion(task: task))
            
            // telemetry
            telemetryAction(.taskAction(.completeButtonTapped))
            return updatedRecords
        }
    }
    
    private func createNewTaskCompletion(task: UITaskModel) -> CompleteRecord {
        CompleteRecord(completedFor: selectedDate, timeMark: currentTime)
    }
    
    // MARK: - Deletion
    func deleteTask(task: MainModel, deleteCompletely: Bool = false) {
        guard task.markAsDeleted == false else {
            return
        }
        
        let model = task
        if deleteCompletely {
            model.markAsDeleted = true
            casManager.deleteModel(task)
        } else {
            model.deleted = updateExistingTaskDeleted(task: model)
            casManager.saveModel(model)
        }
    }
    
    func updateExistingTaskDeleted(task: UITaskModel) -> [DeleteRecord] {
        var newDeletedRecords: [DeleteRecord] = task.deleted
        newDeletedRecords.append(DeleteRecord(deletedFor: selectedDate, timeMark: currentTime))
        return newDeletedRecords
    }
    
    //MARK: - Move to next Day
    func updateNotificationTimeForDueDate(task: MainModel) -> MainModel {
        let model = task
        
        model.notificationDate = dateManager.updateNotificationDate(model.notificationDate)
        
        return model
    }
    
    //MARK: Deadline logic
    func dayUntillDeadLine(_ task: MainModel) -> Int? {
        guard task.endDate != nil else {
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
