//
//  Tasker.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/10/25.
//

import SwiftUI
import MainView
import Managers
import Paywall

@main
struct Tasker: App {
    @Environment(\.scenePhase) var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var mainVM = MainVM()
    
    @Injected(\.appearanceManager) var appearanceManager
    @Injected(\.subscriptionManager) var subscriptionManager
    
    var body: some Scene {
        WindowGroup {
            MainView(vm: mainVM)
                .preferredColorScheme(appearanceManager.selectedColorScheme)
                .onAppear {
                    if let pendingId = UserDefaults.standard.string(forKey: "pendingTaskID") {
                        mainVM.selectedTask(taskId: pendingId)
                        UserDefaults.standard.removeObject(forKey: "pendingTaskID")
                    }
                    mainVM.mainScreenOpened()
                    Task {
                        await subscriptionManager.loadProducts()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openTaskFromNotification)) { notification in
                    mainVM.selectedTask(by: notification)
                }
                .onChange(of: scenePhase) { newValue, _ in
                    switch newValue {
                    case .background, .inactive:
                        Task {
                            await mainVM.updateNotifications()
                        }
                    default:
                        break
                    }
                }
                .animation(.default, value: appearanceManager.selectedColorScheme)
        }
    }
}
