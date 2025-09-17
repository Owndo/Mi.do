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
final class MockCas: CASManagerProtocol {
    
    let cas: MultiCas
    
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
        let localDirectory = MockCas.createLocalDirectory()!
        let remoteDirectory = MockCas.createiCloudDirectory() ?? localDirectory
        
        let localCas = FileCas(localDirectory)
        let iCas = FileCas(remoteDirectory)
        
        cas = MultiCas(local: localCas, remote: iCas)
        
        profileModel = fetchProfileData()
        
//        Task {
////            await syncCases()
//        }
        
        fetchModels()
    }
    
    //MARK: Actions for work with CAS
    func saveModel(_ task: MainModel) {
        do {
            try cas.saveJsonModel(task.model)
            models[task.id] = task
            taskUpdateTrigger.toggle()
        } catch {
            print("Couldn't save daat inside CAS")
        }
    }
    
    func saveProfileData(_ data: ProfileData) {
        do {
            try cas.saveJsonModel(data.model)
            profileUpdateTriger.toggle()
        } catch {
            print("Couldn't save profile data inside CAS")
        }
    }
    
    func saveAudio(url: URL) -> String? {
        
        do {
            let data = try Data(contentsOf: url)
            let audioHash = try cas.add(data)
            
            return audioHash
        } catch {
            return nil
        }
    }
    
    func saveImage(_ photo: Data) -> String? {
        do {
            let imageHash = try cas.add(photo)
            
            return imageHash
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
        let list = try? cas.listMutable()
        
        if let list = list {
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
        }
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
    func fetchProfileData() -> ProfileData {
        let list = try? cas.listMutable()
        
        if let list = list {
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
        
        return mockProfileData()
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
    
    //MARK: - Sync with iCloud
    func syncCases() async throws {
        guard profileModel.settings.iCloudSyncEnabled else {
            print("Couldn't sync")
            return
        }
        
//        do {
//            let status = try cas.listOfRemoteCAS()
//            print("here")
//            if !status.isEmpty {
//                for i in status {
//                    print(i)
//                }
//            }
//            print("remote cas is empty - \(status.isEmpty)")
//        } catch {
//            print("Error with remote cas \(error.localizedDescription)")
//        }
        
//        print("start sync")
//        do {
//            try cas.syncRemote()
//            print("Sync completed")
//        } catch {
//            print("Sync error: \(error.localizedDescription)")
//        }
//        
//        print("end sync")
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
            
            print(sourceDirectory)
            return sourceDirectory
        } catch {
            print("\(error.localizedDescription)")
            return nil
        }
        
    }
    
    //MARK: Predicate
    private func indexForDelete(_ task: MainModel) {
        models.removeValue(forKey: task.id)
    }
    
    public func completedTaskCount() -> Int {
        var allCompletedTasksCount = 0
        
        for task in models.values {
            guard !task.completeRecords.isEmpty else {
                continue
            }
            
            for _ in task.completeRecords {
                allCompletedTasksCount += 1
            }
        }
        
        return allCompletedTasksCount
    }
}
