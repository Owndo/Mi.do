//
//  Tasker.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/10/25.
//

import SwiftUI
import MainView
import Managers

@main
struct Tasker: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private static let mainVM = MainVM()
    
    var body: some Scene {
        WindowGroup {
            MainView(vm: Self.mainVM)
                .onAppear {
                    if let pendingId = UserDefaults.standard.string(forKey: "pendingTaskID") {
                        Self.mainVM.selectedTask(taskId: pendingId)
                        UserDefaults.standard.removeObject(forKey: "pendingTaskID")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openTaskFromNotification)) { notification in
                    Self.mainVM.selectedTask(by: notification)
                }
        }
    }
}
