//
//  СASManagerProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/6/25.
//

import BlockSet
import Combine
import Foundation
import Models

public protocol CASManagerProtocol {
//    var modelPublisher: AnyPublisher<[String: UITaskModel], Never> { get }
//    var models: [String: MainModel] { get set }
//    var profileModel: ProfileData { get set }
    
    func fetchModels<T: Codable>(_ model: T.Type) async -> [T] 
    func saveModel<T: Codable>(_ model: Model<T>) async throws
    func storeAudio(url: URL) async throws -> String? 
    func storeImage(_ photo: Data) async throws -> String?
    func pathToFile(_ hash: String) async throws -> URL
    func retrieve(_ hash: String) async throws -> Data? 
    func deleteModel<T: Codable>(_ model: Model<T>) async throws
    func syncCases() async throws
}
