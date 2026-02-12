//
//  PlayerManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

// PlayerManager.swift
@preconcurrency import AVFoundation
import Foundation
import Models
import CASManager

@Observable
public final class PlayerManager: PlayerManagerProtocol, @unchecked Sendable {
    
    var casManager: CASManagerProtocol
    
    // MARK: - Public properties
    public var isPlaying = false
    public var currentTime: TimeInterval = 0.0
    public var totalTime: TimeInterval = 0.0
    public var task: UITaskModel?
    
    // MARK: - Private properties
    private let audioSession = AVAudioSession.sharedInstance()
    private var player: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var seekTimer: Timer?
    private var pause = false
    
    // Cash: [audioHash: URL]
    private var tempAudioCache: [String: URL] = [:]
    
    private init(casManager: CASManagerProtocol) {
        self.casManager = casManager
    }
    
    //MARK: - Manager creator
    
    public static func createPlayerManager(casManager: CASManagerProtocol) -> PlayerManagerProtocol {
        return PlayerManager(casManager: casManager)
    }
    
    //MARK: - Mock manager
    
    public static func createMockPlayerManager() -> PlayerManagerProtocol {
        let casManager = MockCas.createMockManager()
        
        return PlayerManager(casManager: casManager)
    }
    
    // MARK: - Playback
    
    @MainActor
    public func playAudioFromData(task: UITaskModel) async {
        self.task = task
        
        guard let hash = task.audio else {
            return
        }
        
        do {
            guard let audio = try await casManager.retrieve(hash) else {
                return
            }
            
            try configureAudioSession()
            
            if pause != true {
                player = try AVAudioPlayer(data: audio)
            }
            
            player?.prepareToPlay()
            totalTime = player?.duration ?? 0
            player?.currentTime = currentTime
            player?.play()
            isPlaying = true
            pause = false
            startPlaybackTimer()
        } catch {
            print("Failed to initialize player: \(error)")
        }
    }
    
    public func pauseAudio() {
        player?.pause()
        isPlaying = false
        pause = true
    }
    
    public  func stopToPlay() {
        player?.stop()
        player = nil
        stopPlaybackTimer()
        currentTime = 0
        isPlaying = false
    }
    
    public func seekAudio() {
        guard let player else { return }
        
        seekTimer?.invalidate()
        
        seekTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            guard let self else { return }
            
            let wasPlaying = player.isPlaying
            
            if wasPlaying {
                player.pause()
            }
            
            player.currentTime = currentTime
            
            if wasPlaying {
                player.play()
            }
            
            self.seekTimer = nil
        }
    }
    
    //MARK: - Return Total Time
    
    public func returnTotalTime(task: UITaskModel) async -> Double {
        
        guard let audio = task.audio else { return 0 }
        
        
        do {
            if let data = try await casManager.retrieve(audio) {
                let tempPlayer = try AVAudioPlayer(data: data)
                return tempPlayer.duration
            } else {
                return 0
            }
        } catch {
            return 0
        }
    }
    
    //MARK: - Set Up Total Time
    
    public func setUpTotalTime(task: UITaskModel) async {
        totalTime = await returnTotalTime(task: task)
    }
    
    //MARK: - Reset Audio Progress
    
    public func resetAudioProgress() {
        currentTime = 0.0
        totalTime = 0.0
    }
    
    // MARK: - Helpers
    private func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowAirPlay, .allowBluetoothHFP, .allowBluetoothA2DP, .duckOthers, .defaultToSpeaker]
        )
        try audioSession.setActive(true)
    }
    
    @MainActor
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            guard let self, let player else { return }
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
