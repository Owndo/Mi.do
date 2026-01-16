//
//  Mutable.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/6/25.
//

import Foundation

struct Commit: Codable {
    var parent: [String]
    var blob: String?
}

public struct Parent {
    var commitId: String
    var blobId: String?
}

public actor Mutable: Hashable, Sendable {
    var parent: Parent?
    
    // internal:
    internal init(_ parent: Parent?) {
        self.parent = parent
    }
    
    // public:
    public static func initial() -> Mutable {
        Mutable(nil)
    }
    
    public func returnId() -> String? {
        parent?.commitId
    }
    
    public func updateParent(_ parent: Parent)  {
        self.parent = parent
    }
    
    // Hashable:
    public static func == (lhs: Mutable, rhs: Mutable) -> Bool {
        return lhs === rhs
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
