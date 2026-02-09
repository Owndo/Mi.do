//
//  AppViewVM.swift
//  AppView
//
//  Created by Rodion Akhmedov on 2/8/26.
//

import AVKit
import Foundation
import MainView
import SwiftUI
import VideoManager

@Observable
final class AppViewVM {
    /// Main view model for the whole app logic
    var mainViewVM: MainVM?
    
    // Manager for play launch video
    var videoManager = VideoManager.createManager()
    
    /// Player for start video
    var player: AVPlayer?
    
    /// Triger only for haptic feedback
    var trigger = 0
    
    //MARK: - Start VM
    
    func startVM() async {
        async let mainVM = MainVM.createVM()
        async let delay: () = Task.sleep(for: .seconds(2))
        
        let (vm, _) = await (mainVM, try? delay)
        
        self.mainViewVM = vm
        player = nil
    }
    
    //MARK: - Start LaunchScreen
    
    func startLaunchScreen(colorScheme: ColorScheme) async {
        
        if let url = Bundle.module.url(forResource: colorScheme == .dark ? "Mido_Dark" : "Mido_Light", withExtension: "mp4") {
            player = videoManager.createPlayer(with: url)
            player?.play()
        }
        
        while trigger < 3 {
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                trigger += 1
            }
        }
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
