import Foundation
import Models

@Observable
final class TaskManager: TaskManagerProtocol {
    @ObservationIgnored
    @Injected(\.casManager) private var casManager
    @ObservationIgnored
    @Injected(\.dateManager) private var dateManager
    
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
    
    private var firstWeekDate: Double? {
        let allDates = dateManager.allWeeks.flatMap { $0.date }
        return allDates.min()?.timeIntervalSince1970
    }
    
    private var lastWeekDate: Double? {
        let allDates = dateManager.allWeeks.flatMap { $0.date }
        return allDates.max()?.timeIntervalSince1970
    }
    
    private var validModels: [MainModel] {
        casManager.models.filter { model in
            let task = model.value
            return task.markAsDeleted == false
        }
    }

    var tasks: [MainModel] {
        validModels
            .filter {
                $0.value.isScheduledForDate(selectedDate, calendar: calendar) &&
                ($0.value.deleted?.contains { $0.deletedFor == selectedDate } != true) &&
                ($0.value.done?.contains { $0.completedFor == selectedDate } != true)
            }
            .sorted { $0.value.notificationDate < $1.value.notificationDate }
    }

    var completedTasks: [MainModel] {
        validModels
            .filter {
                $0.value.isScheduledForDate(selectedDate, calendar: calendar) &&
                ($0.value.done?.contains { $0.completedFor == selectedDate } == true)
            }
            .sorted { $0.value.notificationDate < $1.value.notificationDate }
    }
    
    func thisWeekTasks(date: Double) async -> [MainModel] {
            guard let start = firstWeekDate, let end = lastWeekDate else { return [] }
            
            return validModels
                .filter { task in
                    isTaskInWeeksRange(task.value, startDate: start, endDate: end) &&
                    task.value.isScheduledForDate(date, calendar: calendar) &&
                    (task.value.deleted?.contains { $0.deletedFor == date } != true)
                }
    }
    
    private func isTaskInWeeksRange(_ task: TaskModel, startDate: Double, endDate: Double) -> Bool {
        var currentInterval = startDate
        
        while currentInterval <= endDate {
            if task.isScheduledForDate(currentInterval, calendar: calendar) {
                return true
            }
            
            currentInterval += 86400
        }
        
        return false
    }
    
    func preparedTask(task: TaskModel, date: Date) -> TaskModel {
        var filledTask = TaskModel(id: task.id, title: task.title.isEmpty ? "New Task" : task.title, info: task.info, createDate: task.createDate)
        filledTask.notificationDate = date.timeIntervalSince1970
        filledTask.done = task.done
        filledTask.taskColor = task.taskColor
        filledTask.repeatTask = task.repeatTask
        filledTask.audio = task.audio
        filledTask.voiceMode = task.voiceMode
        filledTask.deleted = task.deleted
        filledTask.markAsDeleted = task.markAsDeleted
        filledTask.endDate = task.endDate
        filledTask.secondNotificationDate = task.secondNotificationDate
        filledTask.dayOfWeek = task.dayOfWeek
        return filledTask
    }
    
    // MARK: - Completion Management
    func checkCompletedTaskForToday(task: TaskModel) -> Bool {
        return task.done?.contains(where: { $0.completedFor == selectedDate }) ?? false
    }
    
    func checkMarkTapped(task: MainModel) -> MainModel {
        let model = task
        model.value.done = updateExistingTaskCompletion(task: model.value)
        return model
    }
    
    private func updateExistingTaskCompletion(task: TaskModel) -> [CompleteRecord] {
        guard let existingRecords = task.done else {
            return [createNewTaskCompletion(task: task)]
        }
        
        if let existingIndex = existingRecords.firstIndex(where: { $0.completedFor == selectedDate }) {
            var updatedRecords = existingRecords
            updatedRecords.remove(at: existingIndex)
            return updatedRecords
        } else {
            var updatedRecords = existingRecords
            updatedRecords.append(createNewTaskCompletion(task: task))
            return updatedRecords
        }
    }
    
    private func createNewTaskCompletion(task: TaskModel) -> CompleteRecord {
        CompleteRecord(completedFor: selectedDate, timeMark: currentTime)
    }
    
    // MARK: - Deletion
    func deleteTask(task: MainModel, deleteCompletely: Bool = false) -> MainModel {
        guard task.value.markAsDeleted == false else {
            return task
        }
        
        let model = task
        if deleteCompletely {
            model.value.markAsDeleted = true
        } else {
            model.value.deleted = updateExistingTaskDeleted(task: model.value)
        }
        
        return model
    }
    
    func updateExistingTaskDeleted(task: TaskModel) -> [DeleteRecord] {
        var newDeletedRecords: [DeleteRecord] = task.deleted ?? []
        newDeletedRecords.append(DeleteRecord(deletedFor: selectedDate, timeMark: currentTime))
        return newDeletedRecords
    }
    
    func updateNotificationTimeForDueDate(task: MainModel) -> MainModel {
        let model = task
        
        model.value.notificationDate = dateManager.updateNotificationDate(model.value.notificationDate)
        
        return model
    }
    
    private func isAfter9PM(_ date: Date) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= 21
    }
}
