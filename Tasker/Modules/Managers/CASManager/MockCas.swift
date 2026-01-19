//
//  MockCas.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/6/25.
//

import Foundation
import BlockSet
import Models

public final actor MockCas: CASManagerProtocol {
    private let cas: AsyncableCas
    private let models: [UITaskModel]?
    private let allIdentifiers: [Mutable] = [Mutable.initial(), .initial()]
    
    private init(cas: AsyncableCas, models: [UITaskModel]? = nil) {
        self.cas = cas
        self.models = models
    }
    
    //MARK: - Create manager
    
    /// This manager create empty directory with two basic models
    public static func createManager() -> CASManagerProtocol {
        let localDirectory = createEmptyLocalDirectory()!
        
        let cas = AsyncFileCas(localDirectory)
        
        let models = [
            UITaskModel(
                .initial(
                    TaskModel(
                        title: "New task",
                        notificationDate: Date.now.timeIntervalSince1970
                    )
                )
            ),
            UITaskModel(
                .initial(
                    TaskModel(
                        title: "New Task1",
                        notificationDate: Date.now.timeIntervalSince1970 + 150
                    )
                )
            )
        ]
        
        let casManager = MockCas(cas: cas, models: models)
        
        return casManager
    }
    
    //MARK: - Mock Cas
    
    public static func createMockManager() -> CASManagerProtocol {
        let localDirectory = createLocalDirectory()!
        
        let cas = AsyncFileCas(localDirectory)
        
        let casManager = MockCas(cas: cas)
        
        return casManager
    }
    
    //MARK: - Fetch list
    
    static private func fetchList(cas: AsyncableCas) async -> [Mutable] {
        do {
            return try await cas.listOfAllMutables()
        } catch {
            return []
        }
    }
    
    //MARK: - Fetch models
    
    public func fetchModels<T: Codable & Sendable>(_ model: T.Type) async -> [Model<T>] {
        var models = [Model<T>]()
        
        await withTaskGroup(of: Model<T>?.self) { group in
            for i in allIdentifiers {
                group.addTask {
                    return try? await self.cas.loadJSONModel(i)
                }
            }
            
            for await model in group {
                if let model = model {
                    models.append(model)
                }
            }
        }
        
        return models
    }
    
    //MARK: - Retriev data from cas
    
    public func retrieve(_ hash: String) async throws -> Data? {
        try await cas.retrieve(hash)
    }
    
    //MARK: - Save model
    
    public func saveModel<T: Codable>(_ model: Model<T>) async throws {
        try await cas.saveJSONModel(model)
    }
    
    //MARK: - Save audio
    
    public func storeAudio(_ audio: Data) async throws -> String? {
        return try await cas.store(audio)
    }
    
    //MARK: Save image
    
    public func storeImage(_ photo: Data) async throws -> String? {
        return try await cas.store(photo)
    }
    
    //MARK: - Update CAS after work
    
    // Save all models before app will close
    func updateCASAfterWork() async throws {
        //        for model in models {
        //            try await cas.saveJSONModel(model.value.model)
        //        }
    }
    
    //MARK: - Profile data
    //    private func fetchProfileData() async -> ProfileData {
    //        guard let iCloudProfile = loadProfileFromIcloud() else {
    //            return modelFromCas()
    //        }
    //
    //        if iCloudProfile.settings.iCloudSyncEnabled {
    //            await saveProfileData(iCloudProfile)
    //            return iCloudProfile
    //        } else {
    //            return modelFromCas()
    //        }
    //    }
    
    //    private func modelFromCas() -> ProfileData {
    //        let list = try! cas.listMutable()
    //        return list.compactMap { mutable in
    //            do {
    //                guard let profileModel: Model<ProfileModel> = try cas.loadJsonModel(mutable) else {
    //                    return nil
    //                }
    //
    //                return UIProfileModel(profileModel)
    //
    //            } catch {
    //                return nil
    //            }
    //        }.first ?? mockProfileData()
    //    }
    
    //MARK: - Path to file
    
    //    public func pathToFile(_ hash: String) async throws -> URL {
    //        try await cas.fileURL(forHash: hash)
    //    }
    
    //MARK: Delete model
    
    public func deleteModel<T: Codable>(_ model: Model<T>) async throws {
        try await cas.deleteModel(model)
    }
    
    //MARK: - iCloud
    
    func updateCASesWithICloud() async {
        // sync with icloud is turn off
        //        guard profileModel.settings.iCloudSyncEnabled else {
        //            return
        //        }
        
        // create directory for container
        guard let remoteURL = MockCas.createiCloudDirectory() else {
            return
        }
        
        // directory created, sync turn on but directory is empty
        guard hasFiles(at: remoteURL) else {
            return
        }
        
        // sync
        do {
            try await syncCases()
            //            fetchModels()
        } catch {
            print("Couldn't sync")
        }
    }
    
    public func syncCases() async throws {
        //        try cas.syncRemote()
    }
    
    //MARK: - Create directory
    
    private static func createLocalDirectory() -> URL? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first else {
            return nil
        }
        
        let directoryPath = documentDirectory.appending(path: "Storage", directoryHint: .isDirectory)
        
        do {
            try FileManager.default.createDirectory(atPath: directoryPath.path(), withIntermediateDirectories: true)
            return directoryPath
        } catch {
            return nil
        }
    }
    
    //MARK: Create empty directory
    
    ///Total delete storagedirectory before return url
    private static func createEmptyLocalDirectory() -> URL? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first else {
            return nil
        }
        
        let directoryPath = documentDirectory.appending(path: "Storage", directoryHint: .isDirectory)
        
        if FileManager.default.fileExists(atPath: directoryPath.path) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: directoryPath, includingPropertiesForKeys: nil)
                for fileURL in contents {
                    try FileManager.default.removeItem(at: fileURL)
                }
            } catch {
                print("couldn't remove file: \(error.localizedDescription)")
            }
        }
        
        
        do {
            try FileManager.default.createDirectory(atPath: directoryPath.path(), withIntermediateDirectories: true)
            return directoryPath
        } catch {
            return nil
        }
    }
    
    //MARK: - iCloud CAS
    private static func createiCloudDirectory() -> URL? {
        let container = "iCloud.mido.robocode"
        
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: container) else {
            return nil
        }
        
        let documentDirectory = iCloudURL.appendingPathComponent("Documents", isDirectory: true)
        let sourceDirectory = documentDirectory.appendingPathComponent("modi.robocode", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(
                at: sourceDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            return sourceDirectory
        } catch {
            print("iCloud sync copy error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func hasFiles(at url: URL) -> Bool {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            return !contents.isEmpty
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
            return false
        }
    }
    
    private func saveProfileDataToICloud(_ profileData: UIProfileModel) {
        guard profileData.settings.iCloudSyncEnabled else { return }
        
        let store = NSUbiquitousKeyValueStore.default
        if let data = try? JSONEncoder().encode(profileData.model.value) {
            store.set(data, forKey: "profileData")
            store.synchronize()
        }
    }
    
    private func loadProfileFromIcloud() -> UIProfileModel? {
        let store = NSUbiquitousKeyValueStore.default
        
        if let data = store.data(forKey: "profileData") {
            let profileData = try! JSONDecoder().decode(ProfileModel.self, from: data)
            return UIProfileModel(.initial(profileData))
        }
        
        return nil
    }
}
