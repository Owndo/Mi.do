//
//  Tasker.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/10/25.
//

import SwiftUI
//import MainView
//import Managers
import PaywallView
import SubscriptionManager

@main
struct Tasker: App {
    @State private var paywallVM: PaywallVM? = nil
    //    @Environment(\.scenePhase) var scenePhase
    //    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    //
    //    @State private var mainVM = MainVM()
    //
    //    @Injected(\.appearanceManager) var appearanceManager
    //    @Injected(\.subscriptionManager) var subscriptionManager
    //    @Injected(\.telemetryManager) var telemetryManager
    //
    //    init() {
    //        Task {
    //            await DependencyContext.initialize()
    //        }
    //    }
    
    var body: some Scene {
        WindowGroup {
            if self.paywallVM != nil {
                PaywallView(vm: paywallVM!)
            } else {
                ProgressView()
                    .task {
                        let subscription = await SubscriptionManager.createSubscriptionManager()
                        self.paywallVM = await PaywallVM.createPaywallVM(subscription)
                    }
            }
            //            MainView(vm: mainVM)
            //                .preferredColorScheme(appearanceManager.selectedColorScheme)
            //                .onAppear {
            //                    if let pendingId = UserDefaults.standard.string(forKey: "pendingTaskID") {
            //                        mainVM.selectedTask(taskId: pendingId)
            //                        UserDefaults.standard.removeObject(forKey: "pendingTaskID")
            //                    }
            //                    mainVM.mainScreenOpened()
            //                    Task {
            //                        await subscriptionManager.loadProducts()
            //                        telemetryManager.pageView()
            //                    }
            //                }
            //                .onReceive(NotificationCenter.default.publisher(for: .openTaskFromNotification)) { notification in
            //                    mainVM.selectedTask(by: notification)
            //                }
            //                .onChange(of: scenePhase) { oldValue, newValue in
            //                    switch newValue {
            //                    case .background, .inactive:
            //                        Task {
            //                            await mainVM.closeApp()
            //                        }
            //                    default:
            //                        break
            //                    }
            //                }
            //                .task {
            //                    await subscriptionManager.updatePurchase()
            //                }
            //                .sensoryFeedback(.error, trigger: subscriptionManager.showPaywall)
            //                .animation(.default, value: appearanceManager.selectedColorScheme)
            //                .animation(.bouncy, value: subscriptionManager.showPaywall)
        }
        //        .backgroundTask(.appRefresh("mido.robocode.updateNotificationsAndSync")) {
        //            await mainVM.backgroundUpdate()
        //        }
    }
}
