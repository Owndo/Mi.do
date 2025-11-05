//
//  PermissionManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import AVFAudio
import Foundation
import Observation
import UIKit
import SwiftUI
import Photos
import Speech

@Observable
public final class PermissionManager: PermissionProtocol {
    @ObservationIgnored
    @AppStorage("recognizePermission") var recognizePermission = 0
    
    private var telemetryManager: TelemetryManagerProtocol
    
    public var allowedMicro = false
    public var allowedNotification = false
    public var allowedSpeechRecognition = false
    
    public var alert: Alert?
    
    public init(telemetryManager: TelemetryManagerProtocol) {
        self.telemetryManager = telemetryManager
    }
    
    //MARK: Function for install session setup
    public func peremissionSessionForRecording() throws {
        
        let permissionSession = AVAudioApplication.shared
        let avAudioSession = AVAudioSession.sharedInstance()
        
        switch permissionSession.recordPermission {
        case .undetermined:
            requestRecordPermission()
            throw MicrophonePermission.silentError
        case .denied:
            telemetryManager.logEvent(.mainViewAction(.recordTaskButtonTapped(.error(.microphoneIsNotAvailable))))
            throw MicrophonePermission.microphoneIsNotAvailable
        case .granted:
            do {
                try avAudioSession.setCategory(.playAndRecord, mode: .default, options: [.allowAirPlay, .allowBluetoothHFP, .allowBluetoothA2DP, .defaultToSpeaker])
                try avAudioSession.setActive(true)
                
                if avAudioSession.isOtherAudioPlaying {
                    throw ErrorRecorder.isBusy
                }
                
            } catch let error as NSError {
                switch error.code {
                case AVAudioSession.ErrorCode.isBusy.rawValue:
                    throw ErrorRecorder.isBusy
                case AVAudioSession.ErrorCode.cannotInterruptOthers.rawValue:
                    throw ErrorRecorder.cannotInterruptOthers
                case AVAudioSession.ErrorCode.siriIsRecording.rawValue:
                    throw ErrorRecorder.siriIsRecordign
                case AVAudioSession.ErrorCode.cannotStartRecording.rawValue:
                    throw ErrorRecorder.cannotStartRecording
                case AVAudioSession.ErrorCode.insufficientPriority.rawValue:
                    throw ErrorRecorder.insufficientPriority
                case AVAudioSession.ErrorCode.none.rawValue:
                    throw ErrorRecorder.none
                default:
                    print(error)
                }
            }
        default:
            fatalError("Couldn't get access to microphone")
        }
    }
    
    //MARK: Function request for use microphone
    public func requestRecordPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            self?.allowedMicro = granted
        }
    }
    
    public func permissionForSpeechRecognition() async throws {
        let status = SFSpeechRecognizer.authorizationStatus()
        
        switch status {
        case .notDetermined:
            let _ = await SFSpeechRecognizer.requestAuthorizationAsync()
            throw MicrophonePermission.silentError
        case .authorized:
            allowedSpeechRecognition = true
        default:
            if recognizePermission < 2 {
                allowedSpeechRecognition = false
                telemetryManager.logEvent(.mainViewAction(.recordTaskButtonTapped(.error(.speechRecognitionIsNotAvailable))))
                recognizePermission += 1
                throw MicrophonePermission.speechRecognitionIsNotAvailable
            }
        }
    }
    
    
    public func permissionForGallery() async -> Bool {
        let readWriteStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch readWriteStatus {
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        case .authorized:
            return true
        case .limited:
            return true
        default:
            alert = GalleryPermissions.galleryIsNotAvailable.showingAlert()
            return false
        }
    }
}

extension SFSpeechRecognizer {
    static func requestAuthorizationAsync() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
