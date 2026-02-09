//
//  OnboardingVM.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/29/25.
//

import AppearanceManager
import Foundation
import OnboardingManager
import Models
import SwiftUI

@Observable
final class OnboardingVM {
    var appearanceManager: AppearanceManagerProtocol
    var onboardingManager: OnboardingManagerProtocol
    
    //MARK: - Private init
    
    private init(appearanceManager: AppearanceManagerProtocol, onboardingManager: OnboardingManagerProtocol) {
        self.appearanceManager = appearanceManager
        self.onboardingManager = onboardingManager
    }
    
    //MARK: - Create VM
    
    public static func createVM(
        appearacneManager: AppearanceManagerProtocol,
        onboardingManager: OnboardingManagerProtocol
    ) -> OnboardingVM {
        OnboardingVM(
            appearanceManager: appearacneManager,
            onboardingManager: onboardingManager
        )
    }
    
    //MARK: - Create previewVM
    
    static func createPreviewVM() -> OnboardingVM {
        OnboardingVM(
            appearanceManager: AppearanceManager.createEnvironmentManager(),
            onboardingManager: OnboardingManager.createMockManager()
        )
    }
    
    func continueButtontapped() {

    }
}
