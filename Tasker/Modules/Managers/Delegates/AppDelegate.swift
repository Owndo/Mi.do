//
//  AppDelegate.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/1/25.
//

import Foundation
import UserNotifications
import UIKit

public class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    public static var pendingTaskId: String? = nil
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        
        if let response = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
           let taskId = response["taskID"] as? String {
            AppDelegate.pendingTaskId = taskId
        }
        
        return true
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let taskId = userInfo["taskID"] as? String {
            UserDefaults.standard.set(taskId, forKey: "pendingTaskID")
        }
        
        completionHandler()
    }
}

public extension Notification.Name {
    static let openTaskFromNotification = Notification.Name("openTaskFromNotification")
}
