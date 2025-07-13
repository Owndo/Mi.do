//
//  AppModel.swift
//  Packages
//
//  Created by Rodion Akhmedov on 7/13/25.
//

import Foundation
import ProjectDescription

public struct App {
    public static let name = "Tasker"
    public static let destinations: ProjectDescription.Destinations = .iOS
    public static let bundleId = "com.kodi.mido"
    public static let teamId = "JMB8Y7C47R"
    public static let deploymentTargets = DeploymentTargets.iOS("17.0")
    public static let version = "0.7.0"
}
