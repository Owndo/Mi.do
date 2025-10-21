//
//  AsyncableCas.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 10/20/25.
//

import Foundation

public protocol AsyncableCas: Actor {
    var decoder: JSONDecoder { get set }
    var encoder: JSONEncoder { get set }
    
    /// Add any type of data inside cas
    func addData(_ data: Data) async throws -> String
    
    func getData(_ hash: String) async throws -> Data?
    
    func list() async throws -> [String]
    
    func path(forHash hash: String) async throws -> URL
    
    //MARK: - Add model to cas
    //    func addModel<T: Codable>(_ model: Model<T>) async throws -> String
    
}

extension AsyncableCas {
    //    private func withSet() throws -> CasWithSet {
    //        let list = try self.list()
    //
    //        return CasWithSet(cas: self, set: Set(list))
    //    }
    //
    //    public func sync(_ cas: Cas) throws {
    //        let a = try self.withSet()
    //        let b = try cas.withSet()
    //
    //
    //        try a.fetchFrom(b)
    //        try b.fetchFrom(a)
    //    }
    
    //MARK: - Save
    public func saveJson<T: Encodable>(_ mutable: Mutable, _ value: T?) async throws -> String? {
        var data: Data?
        
        if let value = value {
            encoder.outputFormatting = .sortedKeys
            data = try encoder.encode(value)
        }
        
        return try await saveData(mutable, data)
    }
    
    /// Save data to cas
    public func saveData(_ mutable: Mutable, _ data: Data?) async throws -> String? {
        var blobId: String?
        
        if let data {
            blobId = try await self.addData(data)
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
        
        let commitId = try await self.addData(encoder.encode(commit))
        mutable.parent = Parent(commitId: commitId, blobId: blobId)
        
        return commitId
    }
    
    public func loadData(_ mutable: Mutable) async throws -> Data? {
        guard let blobId = mutable.parent?.blobId else {
            return nil
        }
        
        return try await getData(blobId)
    }
    
    //    public func loadDeleteData(_ mutable: Mutable) async throws -> Data? {
    //        guard let blobId = mutable.parent?.blobId else {
    //
    //        }
    //
    //        return try get(blobId)
    //    }
    
    //MARK: - Delete
    /// Create record about deleting
    public func delete(_ mutable: Mutable) async throws -> String? {
        try await saveData(mutable, nil)
    }
    
    public func totalDelete(mutable: Mutable) async {
        
    }
    
    public func loadJson<T: Decodable>(_ mutable: Mutable) async throws -> T? {
        guard let data = try await loadData(mutable) else {
            return nil
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    public func loadDeletedJson<T: Decodable>(_ mutable: Mutable) async throws -> T? {
        guard let data = try await loadData(mutable) else {
            return nil
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    func loadCommit(_ commitId: String) async throws -> Commit? {
        guard
            let commitData = try await self.getData(commitId)
        else {
            return nil
        }
        return try? JSONDecoder().decode(Commit.self, from: commitData)
    }
    
    public func listMutable() async throws -> [Mutable] {
        var parents: Set<String> = []
        var result: [String: Commit] = [:]
        
        for id in try await self.list() {
            guard let commit: Commit = try await self.loadCommit(id) else { continue }
            // remove and tag parent commits
            for p in commit.parent {
                result[p] = nil
                parents.insert(p)
            }
            if !parents.contains(id) {
                result[id] = commit
            }
        }
        
        return result.map { Mutable(Parent(commitId: $0.key, blobId: $0.value.blob)) }
    }
}

//MARK: - File testCas
actor AsyncFileCas: AsyncableCas {
    var decoder: JSONDecoder = JSONDecoder()
    
    var encoder: JSONEncoder = JSONEncoder()
    
    private let dir: URL
    
    public func path(forHash id: String) -> URL {
        let (a, bc) = id[...].split2()
        let (b, c) = bc.split2()
        return dir.appending(a, true).appending(b, true).appending(c, false)
    }
    
    // public:
    public init(_ dir: URL) {
        self.dir = dir
    }
    
    public func id(_ data: Data) async -> String {
        data.sha256Id()
    }
    
    public func addData(_ data: Data) async throws -> String {
        let id = await id(data)
        let path = path(forHash: id)
        
        try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: path)
        
        return id
    }
    
    public func getData(_ id: String) async -> Data? {
        // TODO: check errors. if the file doesn't exist, return nil
        // otherwise, throw the error
        try? Data(contentsOf: path(forHash: id))
    }
    
    //MARK: - Async lsit
    public func list() async throws -> [String] {
        try await dir.asyncList()
    }
    
}
