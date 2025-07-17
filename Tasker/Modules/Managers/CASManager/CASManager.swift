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
    
    var firstTimeOpened = UserDefaults.standard.bool(forKey: "firstTimeOpened")
    
    let cas: MultiCas
    let remoteDirectory = "iCloud.com.KodiMaberek.Tasker"
    
    var localDirectory: URL
    
    var taskUpdateTrigger = false {
        didSet {
            updateTask()
        }
    }
    
    var profileUpdateTriger = false
    
    var models: [MainModel] = []
    var profileModel: ProfileData?
    
    var activeTasks = [MainModel]()
    
    var completedTasks = [MainModel]()
    
    var deletedTasks: [MainModel] {
        models.filter { $0.value.markAsDeleted == true }
    }
    
    var allCompletedTasks: [MainModel] {
        models.filter { !$0.value.done.isEmpty }
    }
    
    init() {
        let localDirectory = CASManager.createMainDirectory()!
        self.localDirectory = localDirectory
        
        let localCas = FileCas(localDirectory)
        let iCas = FileCas(FileManager.default.url(forUbiquityContainerIdentifier: remoteDirectory) ?? localDirectory)
        
        cas = MultiCas(local: localCas, remote: iCas)
        
        firstTimeOpen()
        
        models = fetchModels()
        profileModel = fetchProfileData()
        
        updateTask()
    }
    
    func updateTask() {
        activeTasks = models.filter { $0.value.markAsDeleted == false }
        completedTasks = models.filter { $0.value.markAsDeleted == false && !$0.value.done.isEmpty }
        NotificationCenter.default.post(name: NSNotification.Name("updateTasks"), object: nil)
    }
    
    //MARK: Actions for work with CAS
    func saveModel(_ task: MainModel) {
        
        do {
            try cas.saveJsonModel(task)
            indexForDelete(task)
            models.append(task)
            taskUpdateTrigger.toggle()
        } catch {
            print("Couldn't save daat inside CAS")
        }
    }
    
    func saveProfileData(_ data: ProfileData) {
        do {
            try cas.saveJsonModel(data)
            profileModel = data
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
            print("Something went wrong while adding audio: \(error)")
            return nil
        }
    }
    
    func saveImage(_ photo: Data) -> String? {
        do {
            return try cas.add(photo)
        } catch {
            print("Couldn't save the photo")
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
            print("error")
            return nil
        }
    }
    
    //MARK: - Task models
    func fetchModels() -> [MainModel] {
        let list = try! cas.listMutable()
        
        return list.compactMap { mutable in
            do {
                return try cas.loadJsonModel(mutable)
            } catch {
                print("Error while loading model: \(error)")
                return nil
            }
        }
    }
    
    //MARK: - Profile data
    func fetchProfileData() -> ProfileData? {
        let list = try! cas.listMutable()
        
        return list.compactMap { mutable in
            do {
                return try cas.loadJsonModel(mutable)
            } catch {
                return nil
            }
        }.first
    }
    
    func pathToAudio(_ hash: String) -> URL {
        let url = cas.path(hash)
        return url
    }
    
    //MARK: Delete model
    func deleteModel(_ task: MainModel) {
        do {
            try cas.deleteModel(task)
            indexForDelete(task)
            taskUpdateTrigger.toggle()
        } catch {
            print("Couldn't delete data: \(error)")
        }
    }
    
    //MARK: Create directory for CAS
    private static func createMainDirectory() -> URL? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first else {
            print("Couldn't get acces to file system")
            return nil
        }
        
        let directoryPath = documentDirectory.appending(path: "Storage", directoryHint: .isDirectory)
        
        do {
            try FileManager.default.createDirectory(atPath: directoryPath.path(), withIntermediateDirectories: true)
            return directoryPath
        } catch {
            print("Couldn't create directory")
            return nil
        }
    }
    
    //MARK: Predicate
    private func indexForDelete(_ task: MainModel) {
        if let index = models.firstIndex(where: { $0.hashValue == task.hashValue }) {
            models.remove(at: index)
        }
    }
    
    private func firstTimeOpen() {
        guard !firstTimeOpened else {
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
        
        UserDefaults.standard.set(true, forKey: "firstTimeOpened")
    }
}
