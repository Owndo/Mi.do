//
//  VideoManager.swift
//  AppView
//
//  Created by Rodion Akhmedov on 2/8/26.
//

import Foundation
import AVKit

public final class VideoManager {
    
    var avPlayer: AVPlayer?
    
    //MARK: - Create Manager
    
    public static func createManager() -> VideoManager {
        let manager = VideoManager()
        manager.disableAudioSessionCompletely()
        
        return manager
    }
    
    //MARK: - Create player
    
    public func createPlayer(with url: URL) -> AVPlayer {
        disableAudioSessionCompletely()
        
        avPlayer = AVPlayer(url: url)
        return avPlayer!
    }
    
    //MARK: - Invalidete player
    
    public func removeManager() {
        avPlayer = nil
    }
    
    //MARK: - Session setUp
    
    private func disableAudioSessionCompletely() {
        let session = AVAudioSession.sharedInstance()
        do {
            // let to play video without interraption other audio/video affects
            try session.setCategory(.ambient)
        } catch {
            print(error)
        }
    }
}
