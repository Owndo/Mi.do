//
//  LaunchViewVM.swift
//  VideoPlayerView
//
//  Created by Rodion Akhmedov on 2/11/26.
//

import Foundation
import SwiftUI

@Observable
final class LaunchViewVM {
    /// Triger only for haptic feedback
    var trigger = 0
    
    var lightColor = Color("F2F5EE")
    var darkColor = Color("202020")
    
    func urlToVideo(colorScheme: ColorScheme) -> URL {
        if let url = Bundle.module.url(forResource: colorScheme == .dark ? "Mido_Dark" : "Mido_Light", withExtension: "mp4") {
            return url
        }
        
        return URL(string: "")!
    }
    
    //MARK: - Haptic feedback
    
    func feedback() -> SensoryFeedback {
        switch trigger {
        case 0, 1:
            return .warning
        case 2:
            return .levelChange
        default:
            return .start
        }
    }
}
