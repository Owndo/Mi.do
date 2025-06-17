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
    case microphoneIsNotAvalible
    
    
    public func showingAlert(action: @escaping () -> Void) -> Alert {
        switch self {
        case .microphoneIsNotAvalible:
            Alert(title: Text("Microphone access denied"), message: Text("To record audio, please enable Microphone access in Settings."), primaryButton: .default(Text("Settings"), action: openSetting), secondaryButton: .cancel(action))
        case .silentError: fatalError()
        }
    }
    
    private func openSetting() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
