//
//  Microphone.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import SwiftUI
import Foundation

public enum MicrophonePermission: Error {
    case silentError
    case microphoneIsNotAvailable
    
    public func showingAlert(action: @escaping () -> Void) -> Alert {
        switch self {
        case .microphoneIsNotAvailable:
            return Alert(
                title: Text("Can't hear you 😢"),
                message: Text("I'd love to hear your voice... but the microphone is off. You can fix it in Settings!"),
                primaryButton: .default(Text("Maybe later"), action: action),
                secondaryButton: .default(Text("Go to Settings"), action: openSettings)
            )
            
        case .silentError:
            fatalError("Silent error occurred")
        }
    }
}

func openSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
