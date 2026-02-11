//
//  LaunchViewVM.swift
//  VideoPlayerView
//
//  Created by Rodion Akhmedov on 2/11/26.
//

import AVKit
import Foundation
import SwiftUI
import VideoManager

@Observable
final class LaunchViewVM {
    var manager = VideoManager.createManager()
    
    /// Player for play LaunchVideo
    var player: AVPlayer?
    
    /// Triger only for haptic feedback
    var trigger = 0
    
    func createPlayer(colorScheme: ColorScheme) {
        if let url = Bundle.module.url(forResource: colorScheme == .dark ? "Mido_Dark" : "Mido_Light", withExtension: "mp4") {
            player = manager.createPlayer(with: url)
            player?.play()
        }
    }
    
    func removeManager() {
        manager.removeManager()
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
