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
    func updateProfileModel() async throws
}
