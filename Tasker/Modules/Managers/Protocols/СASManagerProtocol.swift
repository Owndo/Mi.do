//
//  СASManagerProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/6/25.
//

import Foundation
import Models

public protocol CASManagerProtocol {
    var models: [MainModel] { get }
    var activeTasks: [MainModel] { get }
    var completedTasks: [MainModel] { get }
    var deletedTasks: [MainModel] { get }
    var taskUpdateTrigger: Bool { get }
    
    func saveModel(_ task: MainModel)
    func saveAudio(url: URL) -> String?
    func pathToAudio(_ hash: String) -> URL
    func fetchModels() -> [MainModel]
    func getData(_ hash: String) -> Data?
    func deleteModel(_ model: MainModel)
}
