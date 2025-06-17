//
//  RecorderManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/10/25.
//

import AVFoundation
import Foundation

@Observable
final class RecorderManager: RecorderManagerProtocol, @unchecked Sendable {
    
    private var avAudioRecorder: AVAudioRecorder?
    
    var timer: Timer?
    var currentlyTime = 0.0
    var progress = 0.00
    var maxDuration = 15.00
    var decibelLevel: Float = 0.0
    var isRecording = false
    
    private var previousDecibelLevel: Float = 0.0
    
    let setting: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]
    
    var fileName: URL?
    
    
    //MARK: Start recording
    func startRecording() async {
        let fileName = baseDirectoryURL.appending(path: "\(UUID().uuidString).wav")
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            avAudioRecorder = try AVAudioRecorder(url: fileName, settings: setting)
            avAudioRecorder?.prepareToRecord()
            avAudioRecorder?.isMeteringEnabled = true
            avAudioRecorder?.record()
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            isRecording = avAudioRecorder?.isRecording ?? false
            
            await updateTime()
            self.fileName = fileName
            
        } catch {
            print("Couldn't create AVAudioRecorder: \(error)")
        }
    }
    
    var baseDirectoryURL: URL {
        FileManager.default.temporaryDirectory
    }
    
    func clearFileFromDirectory() {
        guard let file = fileName else {
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Error while clearing temporary directory: \(error)")
        }
    }
    
    //MARK: Stop recording
    func stopRecording() -> URL? {
        timer?.invalidate()
        timer = nil
        avAudioRecorder?.stop()
        avAudioRecorder?.isMeteringEnabled = false
        
        avAudioRecorder = nil
        
        progress = 0.0
        currentlyTime = 0.0
        isRecording = avAudioRecorder?.isRecording ?? false
        
        if let fileName = fileName {
            return fileName
        } else {
            return nil
        }
    }
    
    //MARK: Check and update recording time
    private func updateTime() async {
        Task { @MainActor in
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.currentlyTime = self.avAudioRecorder?.currentTime ?? 00
                self.progress = (self.currentlyTime / self.maxDuration)
                self.updateDecibelLvl()
            }
        }
    }
    
    //MARK: Functions for get and showing decibel LVL
    private func updateDecibelLvl() {
        guard let recorder = avAudioRecorder else {
            return
        }
        
        recorder.updateMeters()
        let decibelLevel = recorder.averagePower(forChannel: 0)
        
        let mappedValue = mapDecibelLessNoiseSensitive(dB: decibelLevel)
        
        let inertiaFactor: Float = 0.5
        let smoothedValue = previousDecibelLevel * inertiaFactor + mappedValue * (1 - inertiaFactor)
        
        self.decibelLevel = smoothedValue
        self.previousDecibelLevel = smoothedValue
    }
    
    private func mapDecibelLessNoiseSensitive(dB: Float, minDcb: Float = -80, maxDcb: Float = 0, minRange: Float = 0.0, maxRange: Float = 1.5) -> Float {
        let clampedDB = max(min(dB, maxDcb), minDcb)
        
        let normalizedDB = (clampedDB - minDcb) / (maxDcb - minDcb)
        
        let power: Float = 1.5
        let correctedValue = pow(normalizedDB, power)
        
        let noiseThreshold: Float = 0.1
        let noiseSuppressedValue = correctedValue < noiseThreshold ? 0 : correctedValue
        
        let result = minRange + noiseSuppressedValue * (maxRange - minRange)
        return result
    }
}
