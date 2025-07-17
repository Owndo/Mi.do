//
//  PlayerManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

// PlayerManager.swift
import AVFoundation
import Foundation
import Models

@Observable
final class PlayerManager: PlayerManagerProtocol, @unchecked Sendable {
    @ObservationIgnored
    @Injected(\.storageManager) var storageManager
    
    // MARK: - Public properties
    var isPlaying = false
    var currentTime: TimeInterval = 0.0
    var totalTime: TimeInterval = 0.0
    var task: TaskModel?
    
    // MARK: - Private properties
    private let audioSession = AVAudioSession.sharedInstance()
    private var player: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var seekTimer: Timer?
    private var pause = false
    
    // Cash: [audioHash: URL]
    private var tempAudioCache: [String: URL] = [:]
    
    // MARK: - Playback
    
    func playAudioFromData(task: TaskModel) async {
        self.task = task
        
        do {
            try configureAudioSession()
            
            guard let audio = task.audio else {
                return
            }
            
            let audioURL = getOrCreateTempAudioFile(audioHash: audio)
            
            await MainActor.run {
                do {
                    if pause != true {
                        player = try AVAudioPlayer(contentsOf: audioURL)
                    }
                    player?.prepareToPlay()
                    totalTime = player?.duration ?? 0
                    player?.play()
                    isPlaying = true
                    pause = false
                    startPlaybackTimer()
                } catch {
                    print("Failed to initialize player: \(error)")
                }
            }
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    func pauseAudio() {
        player?.pause()
        isPlaying = false
        pause = true
    }
    
    func stopToPlay() {
        player?.stop()
        player = nil
        stopPlaybackTimer()
        currentTime = 0
        isPlaying = false
    }
    
    func seekAudio(_ time: TimeInterval) {
        guard let player else { return }
        
        seekTimer?.invalidate()
        currentTime = time
        
        seekTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            guard let self else { return }
            
            let wasPlaying = player.isPlaying
            if wasPlaying {
                player.pause()
            }
            
            player.currentTime = time
            
            if wasPlaying {
                player.play()
            }
            
            self.seekTimer = nil
        }
    }
    
    func returnTotalTime(task: TaskModel) -> Double {
        
        guard let audio = task.audio else { return 0 }
        
        let audioURL = getOrCreateTempAudioFile(audioHash: audio)
        
        do {
            let tempPlayer = try AVAudioPlayer(contentsOf: audioURL)
            return tempPlayer.duration
        } catch {
            print("Failed to get duration from temp player: \(error)")
            return 0
        }
    }
    
    func setUpTotalTime(task: TaskModel) {
        totalTime = returnTotalTime(task: task)
    }
    
    // MARK: - Helpers
    private func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .duckOthers]
        )
        try audioSession.setActive(true)
    }
    
    private func getOrCreateTempAudioFile(audioHash: String) -> URL {
        storageManager.createFileInSoundsDirectory(hash: audioHash)!
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            
            self.currentTime = player.currentTime
            
            if !player.isPlaying {
                self.isPlaying = false
                self.stopPlaybackTimer()
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}
