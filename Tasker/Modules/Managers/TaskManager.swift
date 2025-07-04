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
    
    var tasks: [MainModel] {
        activeTasks
            .filter {
                $0.value.deleted.contains { $0.deletedFor == selectedDate } != true &&
                $0.value.done.contains { $0.completedFor == selectedDate } != true
            }
    }
    
    var completedTasks: [MainModel] {
        activeTasks
            .filter {
                $0.value.deleted.contains { $0.deletedFor == selectedDate } != true &&
                $0.value.done.contains { $0.completedFor == selectedDate } == true
            }
    }
    
    private var activeTasks: [MainModel] {
        let tasks = casManager.activeTasks.filter { $0.value.isScheduledForDate(selectedDate, calendar: calendar) }
        return sortedTasks(tasks: tasks)
    }
    
    private var tasksForProgress: [MainModel] {
        casManager.activeTasks
    }
    
    func thisWeekTasks(date: Double) async -> [MainModel] {
        guard let start = firstWeekDate, let end = lastWeekDate else { return [] }
        
        return tasksForProgress
            .filter { task in
                let taskValue = task.value
                return isTaskInWeeksRange(taskValue, startDate: start, endDate: end) &&
                taskValue.deleted.contains { $0.deletedFor == date } != true
            }
    }
    
    func sortedTasks(tasks: [MainModel]) -> [MainModel] {
        tasks.sorted {
            let hour1 = calendar.component(.hour, from: Date(timeIntervalSince1970: $0.value.notificationDate))
            let hour2 = calendar.component(.hour, from: Date(timeIntervalSince1970: $1.value.notificationDate))
            
            let minutes1 = calendar.component(.minute, from: Date(timeIntervalSince1970: $0.value.notificationDate))
            let minutes2 = calendar.component(.minute, from: Date(timeIntervalSince1970: $1.value.notificationDate))
            
            return hour1 < hour2 || (hour1 == hour2 && minutes1 < minutes2)
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
        var filledTask = TaskModel(
            id: task.id,
            title: task.title.isEmpty ? "New Task" : task.title,
            info: task.info,
            createDate: task.createDate,
            done: [],
            deleted: []
        )
        
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
        task.done.contains(where: { $0.completedFor == selectedDate })
    }
    
    func checkMarkTapped(task: TaskModel) -> TaskModel {
        var model = task
        model.done = updateExistingTaskCompletion(task: task)
        return model
    }
    
    private func updateExistingTaskCompletion(task: TaskModel) -> [CompleteRecord] {
        guard !task.done.isEmpty else {
            return [createNewTaskCompletion(task: task)]
        }
        
        if let existingIndex = task.done.firstIndex(where: { $0.completedFor == selectedDate }) {
            var updatedRecords = task.done
            updatedRecords.remove(at: existingIndex)
            return updatedRecords
        } else {
            var updatedRecords = task.done
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
        var newDeletedRecords: [DeleteRecord] = task.deleted
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
