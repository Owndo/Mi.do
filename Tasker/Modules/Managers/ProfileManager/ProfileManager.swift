//
//  ProfileManager.swift
//  Managers
//
//  Created by Rodion Akhmedov on 10/28/25.
//

import Foundation
import Models
import CASManager

public final class ProfileManager: ProfileManagerProtocol {
    
    private let casManager: CASManagerProtocol
    
    public var profileModel: UIProfileModel
    
    //MARK: - Init
    
    private init(casManager: CASManagerProtocol, profileModel: UIProfileModel) {
        self.casManager = casManager
        self.profileModel = profileModel
    }
    
    //MARK: - Create manager
    
    public static func createProfileManager(casManager: CASManagerProtocol) async -> ProfileManagerProtocol {
        let model = await casManager.fetchModels(ProfileModel.self).map { UIProfileModel(.initial($0)) }.first ?? mockProfileData()
        
        let manager = ProfileManager(casManager: casManager, profileModel: model)
        
        return manager
    }
    
    public static func createMockProfileManager() -> ProfileManagerProtocol {
        let model = mockProfileData().model.value
        let manager = ProfileManager(casManager: MockCas.createCASManager(), profileModel: UIProfileModel(.initial(model)))
        
        return manager
    }
    
    public func updateProfileModel() async throws {
        try await saveProfile()
    }
    //MARK: - Update Photo
    
    public func updatePhoto(_ data: Data) async throws {
        guard let hash = try await casManager.storeImage(data) else {
            throw ProfileError.photoSaveFailed
        }
        
        profileModel.photo = hash
        try await saveProfile()
    }
    
    public func deletePhoto() async throws {
        profileModel.photo = ""
        try await saveProfile()
    }
    
    public func getPhoto() async throws -> Data? {
        try await casManager.retrieve(profileModel.photo)
    }
    
    //MARK: - Save Profile
    
    private func saveProfile() async throws {
        try await casManager.saveModel(profileModel.model)
    }
}

public enum ProfileError: Error {
    case photoSaveFailed
}
