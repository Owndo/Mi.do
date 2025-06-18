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
    
    func playAudioFromData(_ audio: Data, task: TaskModel) async {
        self.task = task
        
        do {
            try configureAudioSession()
            let audioURL = await getOrCreateTempAudioFile(from: audio, audioHash: task.audio)
            
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
    
    func returnTotalTime(_ audio: Data, task: TaskModel) async -> Double {
        let audioURL = await getOrCreateTempAudioFile(from: audio, audioHash: task.audio)
        
        do {
            let tempPlayer = try AVAudioPlayer(contentsOf: audioURL)
            return tempPlayer.duration
        } catch {
            print("Failed to get duration from temp player: \(error)")
            return 0
        }
    }
    
    // MARK: - Helpers
    
    private func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker, .duckOthers]
        )
        try audioSession.overrideOutputAudioPort(.speaker)
    }
    
    private func getOrCreateTempAudioFile(from data: Data, audioHash: String?) async -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let hash = audioHash ?? UUID().uuidString
        let fileName = "\(hash).wav"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        if let cached = tempAudioCache[hash], FileManager.default.fileExists(atPath: cached.path) {
            return cached
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            tempAudioCache[hash] = fileURL
            print("File already exists: \(fileURL.path)")
            return fileURL
        }
        
        await MainActor.run {
            do {
                try data.write(to: fileURL)
                print("Created temp file: \(fileURL.path)")
                tempAudioCache[hash] = fileURL
            } catch {
                print("Failed to write audio data: \(error)")
            }
        }
        
        return fileURL
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
