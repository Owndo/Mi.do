//
//  OnboardingProtocol.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/25/25.
//

import Foundation

public protocol OnboardingManagerProtocol {
    var onboardingComplete: Bool { get set }
    var dayTip: Bool { get set }
    var calendarTip: Bool { get set }
    var profileTip: Bool { get set }
    var notesTip: Bool { get set }
    var deleteTip: Bool { get set }
    var listSwipeTip: Bool { get set }
    var createButtonTip: Bool { get set }
    
    func onboardingStart() async
}
