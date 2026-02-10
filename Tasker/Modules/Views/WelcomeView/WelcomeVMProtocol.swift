//
//  WelcomeVMProtocol.swift
//  WelcomeView
//
//  Created by Rodion Akhmedov on 2/9/26.
//

import Foundation
import AppearanceManager
import WelcomeManager
import SwiftUI

public protocol WelcomeVMProtocol {
    var appearanceManager: AppearanceManagerProtocol { get }
    var welcomeManager: WelcomeManagerProtocol { get }
    
    var title: String { get }
    var createdDate: Date { get }
    
    var systemImage: String { get }
    var systemImage1: String { get }
    var systemImage2 : String { get }
    
    var description: LocalizedStringKey { get }
    var description1: LocalizedStringKey { get }
    var description2: LocalizedStringKey { get }
    
    func welcomeToMidoClose() async
}
