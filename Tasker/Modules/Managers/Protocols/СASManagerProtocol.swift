//
//  СASManagerProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/6/25.
//

import Foundation
import Models

public protocol CASManagerProtocol {
    var models: [String: MainModel] { get }
    var profileModel: ProfileData { get }
    
    var casHasBeenUpdated: ((Bool) -> Void)? { get set }
    
    var taskUpdateTrigger: Bool { get }
    var profileUpdateTriger: Bool { get }
    
    func saveModel(_ task: MainModel)
    func saveProfileData(_ data: ProfileData)
    func saveAudio(url: URL) -> String?
    func saveImage(_ photo: Data) -> String?
    func pathToAudio(_ hash: String) -> URL
    func fetchModels()
    func getData(_ hash: String) -> Data?
    func deleteModel(_ model: MainModel)
    func syncCases() async throws
    func updateCASAfterWork()
    func completedTaskCount() -> Int 
}
