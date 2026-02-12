//
//  App.swift
//  Config
//
//  Created by Rodion Akhmedov on 12/3/25.
//

import Foundation
import ProjectDescription

public struct App {
    public static let name = "Mi.do"
    public static let destinations: ProjectDescription.Destinations = .iOS
    public static let bundleId = "mido.robocode"
    public static let teamId = "5M63H38ZMF"
    public static let deploymentTargets = DeploymentTargets.iOS("17.0")
    public static let version = "1.1.3"
}
