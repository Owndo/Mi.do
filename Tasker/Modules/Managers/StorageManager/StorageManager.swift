//
//  StorageManager.swift
//  Managers
//
//  Created by Rodion Akhmedov on 6/30/25.
//

import Foundation
import Models
import CASManager

public final class StorageManager: StorageManagerProtocol {
    public var casManager: CASManagerProtocol
    
    public var baseDirectory: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appending(path: "Sounds")
    }
    
    private init(casManager: CASManagerProtocol) {
        self.casManager = casManager
    }
    
    //MARK: - Manager creator
    
    public static func createStorageManager() async -> StorageManagerProtocol {
        let casManager = await CASManager.createCASManager()
        return StorageManager(casManager: casManager)
    }
    
    public static func createMockStorageManager() -> StorageManagerProtocol {
        let mockCasManager = MockCas.createCASManager()
        
        return StorageManager(casManager: mockCasManager)
    }
    
    @discardableResult
    public func createFileInSoundsDirectory(hash: String) async -> URL? {
        let soundsDirectory = createSoundsDirectory()
        
        let tempUrl = soundsDirectory.appendingPathComponent(hash + ".wav")
        
        do {
            let pathToAudio = try await casManager.pathToFile(hash)
            
            guard FileManager.default.fileExists(atPath: pathToAudio.path) else {
                return tempUrl
            }
            
            if FileManager.default.fileExists(atPath: tempUrl.path) {
                try FileManager.default.removeItem(at: tempUrl)
            }
            
            try FileManager.default.copyItem(at: pathToAudio, to: tempUrl)
            
            return tempUrl
        } catch {
            return nil
        }
    }
    
    public func deleteAudiFromDirectory(hash: String? = nil) {
        guard let hash = hash else {
            return
        }
        
        let soundsDirectory = createSoundsDirectory()
        let newFileURL = soundsDirectory.appendingPathComponent("\(hash).wav")
        
        guard FileManager.default.fileExists(atPath: newFileURL.path) else {
            return
        }
        
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
