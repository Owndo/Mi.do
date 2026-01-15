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

public protocol CASManagerProtocol: Actor {
    func fetchModels<T: Codable & Sendable>(_ model: T.Type) async -> [Model<T>]
    func saveModel<T: Codable>(_ model: Model<T>) async throws
    func storeAudio(_ audio: Data) async throws -> String? 
    func storeImage(_ photo: Data) async throws -> String?
//    func pathToFile(_ hash: String) async throws -> URL
    func retrieve(_ hash: String) async throws -> Data? 
    func deleteModel<T: Codable>(_ model: Model<T>) async throws
    func syncCases() async throws
}
