//
//  CasManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/6/25.
//

import Foundation
import BlockSet
import Models

@Observable
final class CASManager: CASManagerProtocol {
    
    let cas: MultiCas
    let localDirectory: URL
    let remoteDirectory: URL
    
    var taskUpdateTrigger = false
    var profileUpdateTriger = false
    
    var models: [String: MainModel] = [:]
    var profileModel = mockProfileData()
    var completedTasks: [String: MainModel] = [:]
    
    var activeTasks = [MainModel]()
    
    var deletedTasks: [MainModel] {
        models.values.filter { $0.markAsDeleted == true }
    }
    
    var allCompletedTasks: [MainModel] {
        models.values.filter { !$0.completeRecords.isEmpty }
    }
    
    var allCompletedTasksCount = Int()
    
    init() {
        localDirectory = CASManager.createLocalDirectory()!
        remoteDirectory = CASManager.createiCloudDirectory() ?? localDirectory
        
        let localCas = FileCas(localDirectory)
        let iCas = FileCas(remoteDirectory)
        
        cas = MultiCas(local: localCas, remote: iCas)
        
        profileModel = fetchProfileData()
        
        Task {
            await updateCASesWithICloud()
        }
        
        completedTaskCount()
    }
    
    //MARK: Actions for work with CAS
    func saveModel(_ task: MainModel) {
        
        do {
            try cas.saveJsonModel(task.model)
            models[task.id] = task
            taskUpdateTrigger.toggle()
            completedTaskCount()
        } catch {
            print("Couldn't save daat inside CAS")
        }
    }
    
    func saveProfileData(_ data: ProfileData) {
        do {
            try cas.saveJsonModel(data.model)
            profileUpdateTriger.toggle()
            saveProfileDataToICloud(data)
        } catch {
            print("Couldn't save profile data inside CAS")
        }
    }
    
    func saveAudio(url: URL) -> String? {
        
        do {
            let data = try Data(contentsOf: url)
            return try cas.add(data)
        } catch {
            return nil
        }
    }
    
    func saveImage(_ photo: Data) -> String? {
        do {
            return try cas.add(photo)
        } catch {
            return nil
        }
    }
    
    func getData(_ hash: String) -> Data? {
        do {
            if let data = try cas.get(hash) {
                return data
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    //MARK: - Task models
    func fetchModels() {
        let list = try! cas.listMutable()
        
        models = list.reduce(into: [String : MainModel]()) { result, mutable in
            do {
                if let taskModel: Model<TaskModel> = try cas.loadJsonModel(mutable) {
                    let task = UITaskModel(taskModel)
                    result[task.id] = task
                    
                    if !task.completeRecords.isEmpty {
                        completedTasks[task.id] = task
                    }
                }
                
            } catch {
                print("Error while loading model: \(error)")
            }
        }
        
        taskUpdateTrigger.toggle()
    }
    
    // Save all models before app will close
    func updateCASAfterWork(models: [MainModel]) {
        for model in models {
            do {
                try cas.saveJsonModel(model.model)
            } catch {
                print("Error while saving model after end work: \(error)")
            }
        }
    }
    
    //MARK: - Profile data
    private func fetchProfileData() -> ProfileData {
        guard let iCloudProfile = loadProfileFromIcloud() else {
            return modelFromCas()
        }
        
        if iCloudProfile.settings.iCloudSyncEnabled {
            saveProfileData(iCloudProfile)
            return iCloudProfile
        } else {
            return modelFromCas()
        }
    }
    
    private func modelFromCas() -> ProfileData {
        let list = try! cas.listMutable()
        return list.compactMap { mutable in
            do {
                guard let profileModel: Model<ProfileModel> = try cas.loadJsonModel(mutable) else {
                    return nil
                }
                
                return UIProfileModel(profileModel)
                
            } catch {
                return nil
            }
        }.first ?? mockProfileData()
    }
    
    func pathToAudio(_ hash: String) -> URL {
        let url = cas.path(hash)
        return url
    }
    
    //MARK: Delete model
    func deleteModel(_ task: MainModel) {
        do {
            try cas.deleteModel(task.model)
            indexForDelete(task)
            taskUpdateTrigger.toggle()
        } catch {
            print("Couldn't delete data: \(error)")
        }
    }
    
    //MARK: - iCloud
    func updateCASesWithICloud() async {
        // sync with icloud is turn off
        guard profileModel.settings.iCloudSyncEnabled else {
            fetchModels()
            return
        }
        
        // create directory for container
        guard let remoteURL = CASManager.createiCloudDirectory() else {
            fetchModels()
            return
        }
        
        // directory created, sync turn on but directory is empty
        guard hasFiles(at: remoteURL) else {
            fetchModels()
            return
        }
        
        // sync
        do {
            try await syncCases()
            fetchModels()
        } catch {
            fetchModels()
            print("Couldn't sync")
        }
    }
    
    func syncCases() async throws {
        try cas.syncRemote()
    }
    
    //MARK: Create directory for CAS
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
    
    private func saveProfileDataToICloud(_ profileData: ProfileData) {
        guard profileData.settings.iCloudSyncEnabled else { return }
        
        let store = NSUbiquitousKeyValueStore.default
        if let data = try? JSONEncoder().encode(profileData.model.value) {
            store.set(data, forKey: "profileData")
            store.synchronize()
        }
    }
    
    private func loadProfileFromIcloud() -> ProfileData? {
        let store = NSUbiquitousKeyValueStore.default
        
        if let data = store.data(forKey: "profileData") {
            let profileData = try! JSONDecoder().decode(ProfileModel.self, from: data)
            return ProfileData(.initial(profileData))
        }
        
        return nil
    }
    
    
    //MARK: Predicate
    private func indexForDelete(_ task: MainModel) {
        models.removeValue(forKey: task.id)
    }
    
    private func completedTaskCount() {
        allCompletedTasksCount = 0
        
        for task in models.values {
            guard !task.completeRecords.isEmpty else {
                continue
            }
            
            for _ in task.completeRecords {
                allCompletedTasksCount += 1
            }
        }
    }
}
