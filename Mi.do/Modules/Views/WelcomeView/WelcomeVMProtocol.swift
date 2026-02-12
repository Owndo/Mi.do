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
    
    var title: LocalizedStringKey { get }
    
    var createdText: LocalizedStringKey { get }
    var createdDate: Date { get }
    
    var imageDescription: String { get }
    var imageDescription1: String { get }
    var imageDescription2: String { get }
    
    var descriptionTitle: LocalizedStringKey { get }
    var descriptionTitle1: LocalizedStringKey { get }
    var descriptionTitle2: LocalizedStringKey { get }
    
    var description: LocalizedStringKey { get }
    var description1: LocalizedStringKey { get }
    var description2: LocalizedStringKey { get }
    
    func welcomeToMidoClose() async
}
