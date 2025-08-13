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
    var tasks = [String: MainModel]()
    
    var activeTasks: [MainModel] {
        let filtered = tasks.values.filter {
            $0.done.contains { $0.completedFor == selectedDate } != true
        }
        
        return sortedTasks(tasks: filtered)
    }
    
    var completedTasks: [MainModel] {
        let filtered = tasks.values.filter {
            $0.done.contains { $0.completedFor == selectedDate }
        }
        
        return sortedTasks(tasks: filtered)
    }
    
    private var thisWeekCasheTasks: [MainModel] = []
    private var cacheWeekStart: Double = 0
    private var cacheWeekEnd: Double = 0
    
    init() {
        updateTasks()
        datehasBeenCganged()
    }
    
    func updateTasks() {
        let models = casManager.models.filter { value in
            value.value.isScheduledForDate(selectedDate, calendar: calendar)
        }
        tasks = models
    }
    
    func datehasBeenCganged() {
        dateManager.selectedDateHasBeenChange = { [weak self] _ in
            self?.updateTasks()
        }
    }
    
    func sortedTasks(tasks: [MainModel]) -> [MainModel] {
        tasks.sorted {
            let hour1 = calendar.component(.hour, from: Date(timeIntervalSince1970: $0.notificationDate))
            let hour2 = calendar.component(.hour, from: Date(timeIntervalSince1970: $1.notificationDate))
            
            let minutes1 = calendar.component(.minute, from: Date(timeIntervalSince1970: $0.notificationDate))
            let minutes2 = calendar.component(.minute, from: Date(timeIntervalSince1970: $1.notificationDate))
            
            return (hour1, minutes1, $0.createDate) < (hour2, minutes2, $1.createDate)
        }
    }
    
    func thisWeekTasks(date: Double) async -> [MainModel] {
          return casManager.models.values
              .filter { task in
                  return task.deleted.contains { $0.deletedFor == date } != true
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
    
    func saveTask(_ task: UITaskModel) {
        tasks[task.id] = task
        casManager.saveModel(task)
    }
    
    // MARK: - Deletion
    func deleteTask(task: MainModel, deleteCompletely: Bool = false) {
        guard task.markAsDeleted == false else {
            return
        }
        
        let model = task
        if deleteCompletely {
            tasks.removeValue(forKey: task.id)
            casManager.deleteModel(task)
        } else {
            model.deleted = updateExistingTaskDeleted(task: model)
            tasks.removeValue(forKey: model.id)
            
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
