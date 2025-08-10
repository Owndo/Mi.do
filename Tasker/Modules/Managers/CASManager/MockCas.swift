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
    let remoteDirectory = "iCloud.mido.robocode"
    
    var localDirectory: URL
    
    var taskUpdateTrigger = false {
        didSet {
            updateTask()
        }
    }
    
    var profileUpdateTriger = false
    
    var models: [String: MainModel] = [:]
    var profileModel = mockProfileData()
    
    var activeTasks = [MainModel]()
    
    var completedTasks: [String: MainModel] = [:]
    
    var deletedTasks: [MainModel] {
        models.values.filter { $0.markAsDeleted == true }
    }
    
    var allCompletedTasks: [MainModel] {
        models.values.filter { !$0.done.isEmpty }
    }
    
    var allCompletedTasksCount = Int()
    
    init() {
        let localDirectory = MockCas.createMainDirectory()!
        self.localDirectory = localDirectory
        
        let localCas = FileCas(localDirectory)
        let iCas = FileCas(FileManager.default.url(forUbiquityContainerIdentifier: remoteDirectory) ?? localDirectory)
        
        cas = MultiCas(local: localCas, remote: iCas)
        
        syncCases()
        
        fetchModels()
        profileModel = fetchProfileData()
        
        firstTimeOpen()
        
        updateTask()
        
        //        for i in models {
        //            print("models - \(i.notificationDate)")
        //        }
    }
    
    func updateTask() {
        //        NotificationCenter.default.post(name: NSNotification.Name("updateTasks"), object: nil)
    }
    
    //MARK: Actions for work with CAS
    func saveModel(_ task: MainModel) {
        do {
            try cas.saveJsonModel(task.model)
            indexForDelete(task)
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
                }
                //                return UITaskModel(taskModel)
                
            } catch {
                print("Error while loading model: \(error)")
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
    
    //MARK: - Sync with iCloud
    //TODO: Doesent work
    func syncCases() {
        //        do {
        //            try cas.syncRemote()
        //            print("sync cas")
        //        } catch {
        //            print("Sync error: \(error.localizedDescription)")
        //        }
    }
    
    //MARK: Create directory for CAS
    private static func createMainDirectory() -> URL? {
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
    
    //MARK: Predicate
    private func indexForDelete(_ task: MainModel) {
        models.removeValue(forKey: task.id)
    }
    
    private func completedTaskCount() {
        allCompletedTasksCount = 0
        
        for task in completedTasks {
            guard !task.value.done.isEmpty else {
                continue
            }
            
            for _ in task.value.done {
                allCompletedTasksCount += 1
            }
        }
    }
    
    //MARK: - Onboarding
    private func firstTimeOpen() {
        guard profileModel.onboarding.firstTimeOpen else {
            return
        }
        
        let factory = ModelsFactory()
        
        saveModel(factory.create(.bestApp))
        saveModel(factory.create(.clearMind))
        saveModel(factory.create(.drinkWater))
        saveModel(factory.create(.planForTommorow))
        saveModel(factory.create(.randomHours))
        saveModel(factory.create(.readSomething))
        saveModel(factory.create(.withoutPhone))
        
        profileModel.onboarding.firstTimeOpen = false
        saveProfileData(profileModel)
    }
}
