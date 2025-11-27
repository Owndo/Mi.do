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
public final class PlayerManager: PlayerManagerProtocol, @unchecked Sendable {
    
    var storageManager: StorageManagerProtocol
    
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
    
    private init(storageManager: StorageManagerProtocol) {
        self.storageManager = storageManager
    }
    
    //MARK: - Manager creator
    
    public static func createPlayerManager(storageManager: StorageManagerProtocol) -> PlayerManagerProtocol {
        return PlayerManager(storageManager: storageManager)
    }
    
    //MARK: - Mock manager
    
    public static func createMockPlayerManager() -> PlayerManagerProtocol {
        let mockCasManager = MockCas.createCASManager()
        let storageManager = StorageManager.createStorageManager(casManager: mockCasManager)
        
        return PlayerManager(storageManager: storageManager)
    }
    
    // MARK: - Playback
    
    public func playAudioFromData(task: UITaskModel) async {
        self.task = task
        
        do {
            try configureAudioSession()
            
            guard let audio = task.audio else {
                return
            }
            
            let audioURL = await getOrCreateTempAudioFile(audioHash: audio)
            
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
    
    public func seekAudio(_ time: TimeInterval) {
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
    
    //MARK: - Return Total Time
    
    public func returnTotalTime(task: UITaskModel) async -> Double {
        
        guard let audio = task.audio else { return 0 }
        
        let audioURL = await getOrCreateTempAudioFile(audioHash: audio)
        
        do {
            let tempPlayer = try AVAudioPlayer(contentsOf: audioURL)
            return tempPlayer.duration
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
    
    private func getOrCreateTempAudioFile(audioHash: String) async -> URL {
        await storageManager.createFileInSoundsDirectory(hash: audioHash)!
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
