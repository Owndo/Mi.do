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
    case speechRecognitionIsNotAvailable
    
    var description: String {
        switch self {
        case .silentError:
            return "silent error"
        case .microphoneIsNotAvailable:
            return "Microphone is not avaliable"
        case .speechRecognitionIsNotAvailable:
            return "Speech recognition is not available"
        }
    }
    public func showingAlert(action: @escaping () -> Void) -> Alert {
        switch self {
        case .microphoneIsNotAvailable:
            return Alert(
                title: Text("Can't hear you 😢"),
                message: Text("I'd love to hear your voice... but the microphone is off. You can fix it in Settings!"),
                primaryButton: .default(Text("Maybe later"), action: action),
                secondaryButton: .default(Text("Go to Settings"), action: openSettings)
            )
        case .speechRecognitionIsNotAvailable:
                 return Alert(
                     title: Text("Speech Recognition Unavailable"),
                     message: Text("I can't hear your voice magic... Speech recognition is turned off. Want to enable it in Settings?"),
                     primaryButton: .default(Text("Not now")),
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
