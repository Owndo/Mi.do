//
//  VideoPlayerVM.swift
//  VideoPlayerView
//
//  Created by Rodion Akhmedov on 2/11/26.
//

import AVKit
import Foundation
import VideoManager
import SwiftUI

@Observable
public final class VideoPlayerVM {
    // Manager for play launch video
    var videoManager = VideoManager.createManager()
    
    /// Player for start video
    var player: AVPlayer?
    
    //MARK: - Create player
    
    func createPlayer(path: URL) {
        player = videoManager.createPlayer(with: path)
    }
    
    public func removePlayer() {
        player = nil
    }
    
    public func playVideo() {
        player?.play()
    }
    
    func pauseVideo() {
        player?.pause()
    }
    
    
}
