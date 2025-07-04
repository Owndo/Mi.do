//
//  NotificationManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/24/25.
//

import Foundation
import UserNotifications
import Models
import SwiftUI

@Observable
final class NotificationManager: NotificationManagerProtocol {
    
    @ObservationIgnored
    @AppStorage("countOfNotificationDeinid") var countOfNotificationDeinid = 0
    
    
    @ObservationIgnored
    @Injected(\.storageManager) private var storageManager
    @ObservationIgnored
    @Injected(\.taskManager) private var taskManager
    @ObservationIgnored
    @Injected(\.dateManager) private var dateManager
    @ObservationIgnored
    @Injected(\.casManager) private var casManager
    
    let notificationContent = UNMutableNotificationContent()
    var notificationCenter = UNUserNotificationCenter.current()
    let authorizationOption: UNAuthorizationOptions = [.alert, .badge, .carPlay, .sound, .providesAppNotificationSettings, .provisional]
    
    var alert: AlertModel?
    
    var uniqueID = [String]()
    private var selectedDay = Date()
    
    var calendar: Calendar {
        dateManager.calendar
    }
    
    var now: Date {
        dateManager.currentTime
    }
    
    //update cash
    func createNotification() {
        removeAllEvents()
        var countOfDay = 0
        
        while permissibleQuantity() && countOfDay < 365 {
            let tasks = tasksForSpecificDay(day: selectedDay)
            
            for task in tasks {
                scheduleNotification(task)
            }
            selectedDay = calendar.date(byAdding: .day, value: 1, to: selectedDay)!
            countOfDay += 1
        }
    }
    
    
    //MARK: - Main function for scheduling notification
    private func scheduleNotification(_ task: TaskModel) {
        guard permissibleQuantity() else {
            return
        }
        
        guard uniqueID.contains(task.id) == false else {
            return
        }
        
        guard task.repeatTask != .never else {
            createSingleNotification(task)
            return
        }
        
        guard hasTaskCompleteOrDeleteMarkersInFuture(task: task) else {
            guard checkTaskInCorrectRange(task: task) else {
                createSpecificSingleNotification(task, date: selectedDay)
                return
                
            }
            createRepeatNotification(task)
            return
        }
        
        guard checkDaysBeforeSkip(task) <= 5 else {
            createRepeatNotification(task)
            return
        }
        
        guard !checkIsTaskActualyForThisDay(task: task) else {
            return
        }
        
        guard task.repeatTask == .dayOfWeek else {
            createSpecificSingleNotification(task, date: selectedDay)
            return
        }
        
        guard checkTaskInCorrectRange(task: task) else {
            createSpecificSingleNotification(task, date: selectedDay)
            return
        }
        
        createRepeatNotification(task)
    }
    
    //MARK: - Single notification
    private func createSingleNotification(_ task: TaskModel) {
        
        notificationContent.title = task.title
        notificationContent.body = task.info
        notificationContent.userInfo = ["taskID": task.id]
        
        uniqueID.append(task.id)
        
        if task.voiceMode == false {
            notificationContent.sound = .default
        } else {
            if let audio = task.audio {
                _ = storageManager.createFileInSoundsDirectory(hash: audio)
                notificationContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(audio).wav"))
            }
        }
        
        let date = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date(timeIntervalSince1970: task.notificationDate))
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id , content: notificationContent, trigger: trigger)
        notificationCenter.add(request)
        //        print(request)
        removeDeliveredNotification()
    }
    
    //MARK: - Create repeat notification
    private func createRepeatNotification(_ task: TaskModel) {
        var uniqueNotificationID = task.id
        
        notificationContent.title = task.title
        notificationContent.body = task.info
        notificationContent.userInfo = ["taskID": task.id]
        
        if task.repeatTask == .dayOfWeek {
            let selectedDays = task.dayOfWeek.filter { $0.value }
            
            for day in selectedDays {
                
                uniqueNotificationID = "\(task.id).\(day.name)"
                
                guard !uniqueID.contains(uniqueNotificationID) else { continue }
                
                uniqueID.append(uniqueNotificationID)
                
                let notificationDate = Date(timeIntervalSince1970: task.notificationDate)
                
                let weekdayValue = getWeekdayValue(for: day.name)
                
                var date = calendar.dateComponents([.hour, .minute], from: notificationDate)
                date.weekday = weekdayValue
                
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
                let request = UNNotificationRequest(identifier: uniqueNotificationID, content: notificationContent, trigger: trigger)
                
                notificationCenter.add(request)
                print(request)
            }
        } else {
            guard !uniqueID.contains(uniqueNotificationID) else { return }
            
            uniqueID.append(uniqueNotificationID)
            
            let notificationDate = Date(timeIntervalSince1970: task.notificationDate)
            var date = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            var trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            
            switch task.repeatTask {
            case .never:
                trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            case .daily:
                date = calendar.dateComponents([.hour, .minute], from: notificationDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            case .weekly:
                date = calendar.dateComponents([.weekday, .hour, .minute], from: notificationDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            case .monthly:
                date = calendar.dateComponents([.day, .hour, .minute], from: notificationDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            case .yearly:
                date = calendar.dateComponents([.month, .day, .hour, .minute], from: notificationDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            case .dayOfWeek:
                break
            }
            
            let request = UNNotificationRequest(identifier: uniqueNotificationID, content: notificationContent, trigger: trigger)
            notificationCenter.add(request)
            print(request)
        }
        
        removeDeliveredNotification()
    }
    
    //MARK: - Specific single notification
    private func createSpecificSingleNotification(_ task: TaskModel, date: Date) {
        var dateComponents = DateComponents()
        dateComponents.year = calendar.component(.year, from: date)
        dateComponents.month = calendar.component(.month, from: date)
        dateComponents.day = calendar.component(.day, from: date)
        dateComponents.hour = calendar.component(.hour, from: Date(timeIntervalSince1970: task.notificationDate))
        dateComponents.minute = calendar.component(.minute, from: Date(timeIntervalSince1970: task.notificationDate))
        
        let dateForNotification = calendar.date(from: dateComponents)!
        
        let updatedID = task.id + ".\(task.createDate)"
        
        notificationContent.title = task.title
        notificationContent.body = task.info
        notificationContent.userInfo = ["taskID": updatedID]
        
        uniqueID.append(updatedID)
        
        if task.voiceMode == false {
            notificationContent.sound = .default
        } else {
            if let audio = task.audio {
                _ = storageManager.createFileInSoundsDirectory(hash: audio)
                notificationContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(audio).wav"))
            }
        }
        
        let date = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dateForNotification)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        
        let request = UNNotificationRequest(identifier: updatedID, content: notificationContent, trigger: trigger)
        notificationCenter.add(request)
        print(request)
        removeDeliveredNotification()
    }
    
    func countOfCurrentNotifications() async -> Int {
        await notificationCenter.pendingNotificationRequests().count
    }
    
    func removeEvent(for task: TaskModel) async {
        await deleteNotification(for: task.id)
    }
    
    func removeEvents(for tasks: [TaskModel]) async {
        for task in tasks {
            await deleteNotification(for: task.id)
        }
    }
    
    func removeAllEvents() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        uniqueID.removeAll()
        selectedDay = Date()
    }
    
    
    private func removeDeliveredNotification() {
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    private func deleteNotification(for id: String) async  {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    //MARK: - Permission for notification
    func checkPermission() async {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized:
            countOfNotificationDeinid = 0
        case .denied:
            guard countOfNotificationDeinid < 3 else { return }
            
            if let notificationAlert = NotificationsAlert.deinit.showingAlert(action: timesOfAskingPermission) {
                alert = AlertModel(id: UUID(), alert: notificationAlert)
            }
        case .notDetermined:
            do {
                try await notificationCenter.requestAuthorization(options: [authorizationOption])
            } catch {
                print("Couldn't ask for notification permission")
            }
        default:
            break
        }
    }
    
    
    
    //MARK: - Logic for actual notifications
    
    //MARK: Check count of notifications
    /// work if count of notification less than 63
    private func permissibleQuantity() -> Bool {
        guard uniqueID.count <= 63 else {
            return false
        }
        return true
    }
    
    private func timesOfAskingPermission() {
        if countOfNotificationDeinid < 3 {
            countOfNotificationDeinid += 1
        }
    }
    
    /// Avalible tasks for day
    private func tasksForSpecificDay(day: Date) -> [TaskModel] {
        casManager.activeTasks
            .filter {
                $0.value
                    .isScheduledForDate(day.timeIntervalSince1970, calendar: calendar) &&
                isTaskTimeAfterCurrent($0.value, for: day) }
            .map { $0.value }
            .sorted { sortedTasksForCurrentTime(task1: $0, task2: $1) }
    }
    
    private func sortedTasksForCurrentTime(task1: TaskModel, task2: TaskModel) -> Bool {
        let taskHour = calendar.component(.hour, from: Date(timeIntervalSince1970: task1.notificationDate))
        let taskMinutes = calendar.component(.minute, from: Date(timeIntervalSince1970: task1.notificationDate))
        
        let taskHour1 = calendar.component(.hour, from: Date(timeIntervalSince1970: task2.notificationDate))
        let taskMinute1 = calendar.component(.minute, from: Date(timeIntervalSince1970: task2.notificationDate))
        
        return taskHour < taskHour1 || (taskHour == taskHour1 && taskMinutes < taskMinute1)
    }
    
    /// Days before task completed or deleted
    private func checkDaysBeforeSkip(_ task: TaskModel) -> Int {
        let datesBeforeSkip = task.done.map { Date(timeIntervalSince1970: $0.completedFor )}
            .filter { $0.timeIntervalSince1970 > now.timeIntervalSince1970 }
            .sorted()
        
        let dateBeforDelete = task.deleted.map { Date(timeIntervalSince1970: $0.deletedFor )}
            .filter { $0.timeIntervalSince1970 > now.timeIntervalSince1970 }
            .sorted()
        
        let dayBeforeSkip = calendar.dateComponents([.day], from: now, to: datesBeforeSkip.first ?? dateBeforDelete.first!).day! + 1
        
        return dayBeforeSkip
    }
    
    /// Check that's task's hours and minutes components more than now for today, not for future
    private func isTaskTimeAfterCurrent(_ task: TaskModel, for day: Date) -> Bool {
        
        if calendar.compare(day, to: now, toGranularity: .day) == .orderedAscending {
            return false
        }
        
        if calendar.compare(day, to: now, toGranularity: .day) == .orderedDescending {
            return true
        }
        
        let taskDate = Date(timeIntervalSince1970: task.notificationDate)
        
        let currentHour = calendar.component(.hour, from: now)
        let currentMinutes = calendar.component(.minute, from: now)
        
        let taskHour = calendar.component(.hour, from: taskDate)
        let taskMinutes = calendar.component(.minute, from: taskDate)
        
        return taskHour > currentHour || (taskHour == currentHour && taskMinutes > currentMinutes)
    }
    
    private func checkIsTaskActualyForThisDay(task: TaskModel) -> Bool {
        task.done.contains(where: { calendar.isDate(Date(timeIntervalSince1970: $0.completedFor), inSameDayAs: selectedDay)}) ||
        task.deleted.contains(where: { calendar.isDate(Date(timeIntervalSince1970: $0.deletedFor), inSameDayAs: selectedDay)})
    }
    
    //MARK: Check  completed or deleted record
    private func hasTaskCompleteOrDeleteMarkersInFuture(task: TaskModel) -> Bool {
        task.done.contains { $0.completedFor > now.timeIntervalSince1970 } ||
        task.deleted.contains { $0.deletedFor > now.timeIntervalSince1970 }
    }
    
    //MARK: Task's in correct range
    private func checkTaskInCorrectRange(task: TaskModel) -> Bool {
        switch task.repeatTask {
        case .never:
            return true
        case .daily:
            if now.timeIntervalSince1970 + 86_400 > task.notificationDate {
                return true
            } else {
                return false
            }
        case .weekly:
            if  now.timeIntervalSince1970 + 604_800 > task.notificationDate {
                return true
            } else {
                return false
            }
        case .monthly:
            if now.timeIntervalSince1970 + 2_592_000 > task.notificationDate {
                return true
            } else {
                return false
            }
        case .yearly:
            if now.timeIntervalSince1970 + 31_536_000 > task.notificationDate {
                return true
            } else {
                return false
            }
        case .dayOfWeek:
            if now.timeIntervalSince1970 + 604_800 > task.notificationDate {
                return true
            } else {
                return false
            }
        }
    }
    
    private func getWeekdayValue(for dayName: String) -> Int {
        switch dayName {
        case "Sun": return 1
        case "Mon": return 2
        case "Tue": return 3
        case "Wed": return 4
        case "Thu": return 5
        case "Fri": return 6
        case "Sat": return 7
        default: return 1
        }
    }
}

