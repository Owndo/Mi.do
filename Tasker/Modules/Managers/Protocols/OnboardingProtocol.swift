//
//  OnboardingProtocol.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/25/25.
//

import Foundation

public protocol OnboardingManagerProtocol {
    var sayHello: Bool { get set }
    var onboardingComplete: Bool { get set }
    
    func firstTimeOpenDone()
}
