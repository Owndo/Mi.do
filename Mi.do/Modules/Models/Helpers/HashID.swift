//
//  WrapModel.swift
//  Models
//
//  Created by Rodion Akhmedov on 9/12/25.
//

import Foundation

public func hashID<T: Encodable>(_ value: T) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    
    if let data = try? encoder.encode(value) {
        return data.sha256Id()
    } else {
        return UUID().uuidString
    }
}
