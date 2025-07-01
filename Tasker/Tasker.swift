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
    
    @State private var mainVM = MainVM()
    
    var body: some Scene {
        WindowGroup {
            MainView(vm: mainVM)
                .onAppear {
                    if let pendingId = UserDefaults.standard.string(forKey: "pendingTaskID") {
                        mainVM.selectedTask(taskId: pendingId)
                        UserDefaults.standard.removeObject(forKey: "pendingTaskID")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openTaskFromNotification)) { notification in
                    mainVM.selectedTask(by: notification)
                }
        }
    }
}
