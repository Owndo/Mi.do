//
//  OnboardingProtocol.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/25/25.
//

import Foundation

public protocol OnboardingManagerProtocol {
    var showWhatsNew: Bool { get set }
    
    /// First time ever open
    func welcomeToMido() -> String?
    func firstTimeOpenDone() async throws
}
