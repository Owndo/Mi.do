//
//  StorageManager.swift
//  Managers
//
//  Created by Rodion Akhmedov on 6/30/25.
//

import Foundation
import Models

@Observable
final class StorageManager: StorageManagerProtocol {
    @ObservationIgnored
    @Injected(\.casManager) var casManager
    
    var baseDirectory: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appending(path: "Sounds")
    }
    
    func createFileInSoundsDirectory(hash: String) {
        let soundsDirectory = createSoundsDirectory()
        
        let pathToAudio = casManager.pathToAudio(hash)

        let tempUrl = soundsDirectory.appendingPathComponent(hash + ".wav")
        
        do {
            guard FileManager.default.fileExists(atPath: pathToAudio.path) else {
                return
            }
            
            if FileManager.default.fileExists(atPath: tempUrl.path) {
                try FileManager.default.removeItem(at: tempUrl)
            }
            
            try FileManager.default.copyItem(at: pathToAudio, to: tempUrl)
            
        } catch {
            print("Cannot work with file: \(error.localizedDescription)")
        }
    }
    
    func deleteAudiFromDirectory(hash: String) {
        let soundsDirectory = createSoundsDirectory()
        let newFileURL = soundsDirectory.appendingPathComponent("\(hash).wav")
        
        do {
            try FileManager.default.removeItem(at: newFileURL)
        } catch {
            print("Error while deleting file: \(error)")
        }
    }
    
    private func createSoundsDirectory() -> URL {
        let soundsDirectory = baseDirectory
        
        do {
            try FileManager.default.createDirectory(at: soundsDirectory, withIntermediateDirectories: true)
        } catch {
            print("Couldn't create directory for sounds: \(error.localizedDescription)")
        }
        
        return soundsDirectory
    }
}
