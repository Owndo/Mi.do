//
//  MultiCas.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/6/25.
//

import Foundation

public class MultiCas: AsyncableCasProtocol {
    public var decoder = JSONDecoder()
    public var encoder = JSONEncoder()
    
    private var local: AsyncableCasProtocol
    private var remote: AsyncableCasProtocol
    
    public init(local: AsyncableCasProtocol, remote: AsyncableCasProtocol) {
        self.local = local
        self.remote = remote
    }
    
    public func hash(for data: Data) async -> String {
        await local.hash(for: data)
    }
    
    public func store(_ data: Data) async throws -> String {
        let id = try await local.store(data)
        
        do {
            try await remote.store(data)
        } catch {
            print("Couldn't remote add")
        }
        return id
    }
    
    public func retrieve(_ id: String) async throws -> Data? {
        if let data = try await local.retrieve(id) {
            return data
        }
        
        do {
            if let data = try await remote.retrieve(id) {
                try await local.store(data)
                return data
            }
        } catch {
            
        }
        return nil
    }
    
    public func allIdentifiers() async throws -> [String] {
        try await local.allIdentifiers()
    }
    
    public func fileURL(forHash hash: String) async throws -> URL {
        try await local.fileURL(forHash: hash)
    }
    
    //MARK: - Remote CAS
    public func listOfRemoteCAS() async throws -> [String] {
        try await remote.allIdentifiers()
    }
    
    public func syncRemote() throws {
//        try local.sync(remote)
    }
}
