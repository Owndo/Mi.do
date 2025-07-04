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
    let remoteDirectory = "iCloud.com.KodiMaberek.Tasker"
    
    var localDirectory: URL
    var taskUpdateTrigger = false
    
    var models: [MainModel] = []
    
    var activeTasks: [MainModel] {
        models.filter { $0.value.markAsDeleted == false }
    }
    
    var completedTasks: [MainModel] {
        models.filter { $0.value.markAsDeleted == false && !$0.value.done.isEmpty }
    }
    
    var deletedTasks: [MainModel] {
        models.filter { $0.value.markAsDeleted == true }
    }
    
    init() {
        let localDirectory = CASManager.createMainDirectory()!
        self.localDirectory = localDirectory
        
        let localCas = FileCas(localDirectory)
        let iCas = FileCas(FileManager.default.url(forUbiquityContainerIdentifier: remoteDirectory) ?? localDirectory)
        
        cas = MultiCas(local: localCas, remote: iCas)
        models = fetchModels()
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
    
    func saveAudio(url: URL) -> String? {
        
        do {
            let data = try Data(contentsOf: url)
            return try cas.add(data)
        } catch {
            print("Something went wrong while adding audio: \(error)")
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
    
    func fetchModels() -> [MainModel] {
        let list = try! cas.listMutable()
        
        return list.compactMap { mutable in
            do {
                return try cas.loadJsonModel(mutable)
            } catch {
                print("Error while loading model: \(error)")
                return nil
            }
        }.filter { $0.value.markAsDeleted == false }
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
}



