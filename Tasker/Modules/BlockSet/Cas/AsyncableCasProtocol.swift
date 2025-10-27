//
//  AsyncableCasProtocol.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 10/20/25.
//

import Foundation

public protocol AsyncableCasProtocol {
    var decoder: JSONDecoder { get set }
    var encoder: JSONEncoder { get set }
    
    /// Return hash for any data
    func hash(for data: Data) async -> String
    
    /// Add any type of data inside cas
    @discardableResult
    func store(_ data: Data) async throws -> String
    
    /// Use hash for getting any data from cas
    func retriev(_ hash: String) async throws -> Data?
    
    /// Lists all stored identifiers.
    func allIdentifiers() async throws -> [String]
    
    /// Returns the file URL corresponding to a stored block.
    func fileURL(forHash hash: String) async throws -> URL
}

extension AsyncableCasProtocol {
    //MARK: - Save
    
    /// Saves an encodable value as JSON into CAS.
    @discardableResult
    public func saveJSON<T: Encodable>(_ mutable: Mutable, _ value: T?) async throws -> String? {
        var data: Data?
        
        if let value = value {
            encoder.outputFormatting = .sortedKeys
            data = try encoder.encode(value)
        }
        
        return try await saveData(mutable, data)
    }
    
    /// Saves a model and its associated value as JSON into CAS.
    @discardableResult
    public func saveJSONModel<T: Encodable>(_ model: Model<T>) async throws -> String? {
        try await saveJSON(model.s.mutable, model.s.value)
    }
    
    /// Saves raw binary data into CAS.
    public func saveData(_ mutable: Mutable, _ data: Data?) async throws -> String? {
        var blobId: String?
        
        if let data {
            blobId = try await self.store(data)
        }
        
        let parent = mutable.parent
        // nothing new
        guard blobId != parent?.blobId else {
            return nil
        }
        
        let commit = Commit(
            parent: parent.map { [$0.commitId] } ?? [],
            blob: blobId
        )
        
        let commitId = try await self.store(encoder.encode(commit))
        mutable.parent = Parent(commitId: commitId, blobId: blobId)
        
        return commitId
    }
    
    /// Loads raw data for the given mutable reference.
    public func loadData(_ mutable: Mutable) async throws -> Data? {
        guard let blobId = mutable.parent?.blobId else {
            return nil
        }
        
        return try await retriev(blobId)
    }
    
    //MARK: - Delete
    //TODO: - Add deleting for any data just with HASH
    /// Creates a record in CAS indicating that the given mutable reference was deleted.
    @discardableResult
    public func deleteMutable(_ mutable: Mutable) async throws -> String? {
        try await saveData(mutable, nil)
    }
    
    /// Deletes the given model by creating a deletion record in CAS.
    @discardableResult
    public func deleteModel<T>(_ model: Model<T>) async throws -> String? {
        try await saveData(model.s.mutable, nil)
    }
    
    // MARK: - Load JSON
    
    /// Loads and decodes a JSON value for the given mutable reference.
    public func loadJSON<T: Decodable>(_ mutable: Mutable) async throws -> T? {
        guard let data = try await loadData(mutable) else {
            return nil
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    /// Loads and decodes a JSON-encoded model for the given mutable reference.
    public func loadJSONModel<T: Decodable>(_ mutable: Mutable) async throws -> Model<T>? {
        guard let value: T = try await loadJSON(mutable) else {
            return nil
        }
        return Model(ModelStruct(mutable: mutable, value: value))
    }
    
    public func loadDeletedJSON<T: Decodable>(_ mutable: Mutable) async throws -> T? {
        guard mutable.parent?.blobId == nil else {
            return nil
        }
        
        var commitId = mutable.parent?.commitId
        
        while let id = commitId,
            let commitData = try await self.retriev(id) {
            let commit = try decoder.decode(Commit.self, from: commitData)
            
            if let blobId = commit.blob,
               let data = try await self.retriev(blobId) {
                return try decoder.decode(T.self, from: data)
            }
            
            commitId = commit.parent.first
        }
        
        return nil
    }
    // MARK: - Commits
    
    /// Loads a commit by its identifier.
    func loadCommit(_ commitId: String) async throws -> Commit? {
        guard
            let commitData = try await self.retriev(commitId)
        else {
            return nil
        }
        return try? JSONDecoder().decode(Commit.self, from: commitData)
    }
    
    // MARK: - Listing
    
    /// Returns a list of all mutable references.
    public func listMutables(onlyDeleted: Bool = false) async throws -> [Mutable] {
        let ids = try await self.allIdentifiers()
        
        let commits = try await withThrowingTaskGroup(of: (String, Commit?).self) { group in
            for id in ids {
                group.addTask {
                    (id, try await self.loadCommit(id))
                }
            }
            
            var result: [String: Commit] = [:]
            for try await (id, commit) in group {
                if let commit = commit {
                    result[id] = commit
                }
            }
            return result
        }
        
        var parents: Set<String> = []
        for commit in commits.values {
            commit.parent.forEach { parents.insert($0) }
        }
        
        return commits
            .filter { id, commit in
                !parents.contains(id) && (onlyDeleted ? commit.blob == nil : true)
            }
            .map { Mutable(Parent(commitId: $0.key, blobId: $0.value.blob)) }
    }
    
    public func listOfDeletedMutables() async throws -> [Mutable] {
        try await listMutables(onlyDeleted: true)
    }
}
