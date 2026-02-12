//
//  StorageManagerProtocols.swift
//  Managers
//
//  Created by Rodion Akhmedov on 6/30/25.
//

import Foundation

public protocol StorageManagerProtocol {
    func createFileInSoundsDirectory(hash: String) async -> URL?
    func deleteAudiFromDirectory(hash: String?)
    func clearFileFromDirectory(url: URL)
    func clearSoundsDirectory()
}
