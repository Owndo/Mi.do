//
//  VideoManager.swift
//  AppView
//
//  Created by Rodion Akhmedov on 2/8/26.
//

import Foundation
import AVKit

//MARK: - Manager only for launch screen video

public final class VideoManager {
    
    private init() {}
    
    //MARK: - Create Manager
    
    public static func createManager() -> VideoManager {
         VideoManager()
    }
    
    public func createPlayer(with url: URL) -> AVPlayer {
        disableAudioSessionCompletely()
        
        let avPlayer = AVPlayer(url: url)
        return avPlayer
    }
    
    private func disableAudioSessionCompletely() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient)
        } catch {
            print(error)
        }
    }
}
