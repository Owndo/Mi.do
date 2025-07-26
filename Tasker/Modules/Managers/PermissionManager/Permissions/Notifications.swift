//
//  Notifications.swift
//  Managers
//
//  Created by Rodion Akhmedov on 6/30/25.
//

import Foundation
import SwiftUI


public enum NotificationsAlert {
    case `deinit`
    case notDetermine
    
    public func showingAlert(action: (() -> Void)? = nil) -> Alert? {
        switch self {
        case .deinit:
            return Alert(
                title: Text("Notifications are off 😶‍🌫️"),
                message: Text("Guess we’ll just sit here... quietly."),
                primaryButton: .default(Text("Go to Settings"), action: openSettings),
                secondaryButton: .cancel(Text("OK"), action: action ?? {})
            )
            
        default:
            return nil
        }
    }
}
