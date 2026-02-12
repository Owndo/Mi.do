//
//  ProfileManagerProtocol.swift
//  Managers
//
//  Created by Rodion Akhmedov on 10/28/25.
//

import Foundation
import Models

public protocol ProfileManagerProtocol {
    var profileModel: UIProfileModel { get set }
    
    func updatePhoto(_ data: Data) async throws
    func deletePhoto() async throws
    func getPhoto() async throws -> Data?
    func updateProfileModel() async throws
    func updateVersion(to version: String) async throws
}
