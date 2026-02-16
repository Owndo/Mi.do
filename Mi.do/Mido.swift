//
//  Mido.swift
//  Mido
//
//  Created by Rodion Akhmedov on 4/10/25.
//

import SwiftUI
import AppView

@main
struct Mido: App {
    
    var body: some Scene {
        WindowGroup {
            AppView()
        }
        //        .backgroundTask(.appRefresh("mido.robocode.updateNotificationsAndSync")) {
        //            await mainVM.backgroundUpdate()
        //        }
    }
}
