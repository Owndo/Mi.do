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
    
    private var fileManager = FileManager.default
    public var soundsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appending(path: "Sounds")
    
    private init(casManager: CASManagerProtocol) {
        self.casManager = casManager
    }
    
    //MARK: - Manager creator
    
    public static func createStorageManager(casManager: CASManagerProtocol) -> StorageManagerProtocol {
        return StorageManager(casManager: casManager)
    }
    
    public static func createMockStorageManager() -> StorageManagerProtocol {
        let mockCasManager = MockCas.createMockManager()
        
        return StorageManager(casManager: mockCasManager)
    }
    
    @discardableResult
    public func createFileInSoundsDirectory(hash: String) async -> URL? {
        let soundsDirectory = createSoundsDirectory()
        
        let tempUrl = soundsDirectory.appendingPathComponent(hash)
        
        if fileManager.fileExists(atPath: tempUrl.path) {
            return tempUrl
        }
        
        do {
            let pathToAudio = try await casManager.pathToFile(hash)
            
            try fileManager.copyItem(at: pathToAudio, to: tempUrl)
            
            return tempUrl
        } catch {
            print("error")
            return nil
        }
    }
    
    public func deleteAudiFromDirectory(hash: String? = nil) {
        guard let hash = hash else {
            return
        }
        
        let soundsDirectory = createSoundsDirectory()
        let newFileURL = soundsDirectory.appendingPathComponent("\(hash)")
        
        guard fileManager.fileExists(atPath: newFileURL.path) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(at: newFileURL)
        } catch {
            print("Error while deleting file: \(error)")
        }
    }
    
    //MARK: - Clear Temporary Directory
    
    public func clearFileFromDirectory(url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print("Error while clearing temporary directory: \(error)")
        }
    }
    
    public func clearSoundsDirectory() {
        try? fileManager.removeItem(at: soundsDirectory)
    }
    
    private func createSoundsDirectory() -> URL {
        do {
            try FileManager.default.createDirectory(at: soundsDirectory, withIntermediateDirectories: true)
        } catch {
            print("Couldn't create directory for sounds: \(error.localizedDescription)")
        }
        
        return soundsDirectory
    }
}
