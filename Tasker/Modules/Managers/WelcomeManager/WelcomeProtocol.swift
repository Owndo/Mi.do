//
//  WelcomeManagerProtocol.swift
//  OnboardingView
//
//  Created by Rodion Akhmedov on 2/9/26.
//

import Foundation

public protocol WelcomeManagerProtocol {
    func appLaunchState() -> AppLaunchState?
    func firstTimeOpenDone() async throws 
}
