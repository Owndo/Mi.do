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
    
    let notificationContent = UNMutableNotificationContent()
    let notificationCenter = UNUserNotificationCenter.current()
    let authorizationOption: UNAuthorizationOptions = [.alert, .badge, .carPlay, .sound, .providesAppNotificationSettings, .provisional]
    
    let calendar = Calendar.current
    
    var alert: AlertModel?
    
    func notif() async {
        notificationContent.title = "Background push"
        notificationContent.body = "Tasker was updated"
        notificationContent.sound = .default
        
        let triger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: triger)
        do {
            try await notificationCenter.add(request)
        } catch {
            
        }
    }
    
    //MARK: Notification body
    func createNotification(_ task: TaskModel) {
        
        notificationContent.title = task.title
        notificationContent.body = task.info
        notificationContent.userInfo = ["taskID": task.id]
        
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
        print(request)
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
    }
    
    private func deleteNotification(for id: String) async  {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    //MARK: Permission for notification
    func checkPermission() async {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized:
            countOfNotificationDeinid = 0
        case .denied:
            guard countOfNotificationDeinid < 3 else { return }
            
            if let notificationAlert = NotificationsAlert.deinit.showingAlert(action: countOfNotification) {
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
    
    private func countOfNotification() {
        if countOfNotificationDeinid < 3 {
            countOfNotificationDeinid += 1
        }
    }
}

