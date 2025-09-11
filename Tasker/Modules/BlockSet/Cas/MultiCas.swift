//
//  MultiCas.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/6/25.
//

import Foundation

public class MultiCas: Cas {
    private var local: Cas
    private var remote: Cas
    
    public init(local: Cas, remote: Cas) {
        self.local = local
        self.remote = remote
    }
    
    public func id(_ data: Data) -> String {
        local.id(data)
    }
    
    public func add(_ data: Data) throws -> String {
        let id = try local.add(data)
        
        do {
            try remote.add(data)
        } catch {
            print("Couldn't remote add")
        }
        return id
    }
    
    public func get(_ id: String) throws -> Data? {
        if let data = try local.get(id) {
            return data
        }
        
        do {
            if let data = try remote.get(id) {
                try local.add(data)
                return data
            }
        } catch {
            
        }
        return nil
    }
    
    public func path(_ id: String) -> URL {
        local.path(id)
    }
    
    public func list() throws -> [String] {
        try local.list()
    }
    
    //MARK: - Remote CAS
    public func listOfRemoteCAS() throws -> [String] {
        try remote.list()
    }
    
    public func syncRemote() throws {
        try local.sync(remote)
    }
}
