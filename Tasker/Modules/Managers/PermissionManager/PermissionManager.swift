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

@Observable
final class PermissionManager: PermissionProtocol {
    var allowedMicro = false
    var allowedNotification = false
    
    var alert: Alert?
    
    //MARK: Function for install session setup
    func peremissionSessionForRecording() throws {
        
        let permissionSession = AVAudioApplication.shared
        let avAudioSession = AVAudioSession.sharedInstance()
        
        switch permissionSession.recordPermission {
        case .undetermined:
            requestRecordPermission()
            throw MicrophonePermission.silentError
        case .denied:
            throw MicrophonePermission.microphoneIsNotAvailable
        case .granted:
            do {
                try avAudioSession.setCategory(.playAndRecord, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
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
    func requestRecordPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            self?.allowedMicro = granted
        }
    }
    
    
    func permissionForGallery() async -> Bool {
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
