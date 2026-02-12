//
//  InfoPlist.swift
//  ProjectDescriptionHelpers
//
//  Created by Rodion Akhmedov on 12/3/25.
//

import Foundation
import ProjectDescription

public extension InfoPlist {
    static func infoPlist() -> Self {
        .extendingDefault(
            with: [
                "UILaunchStoryboardName": "LaunchScreen",
                "CFBundleDisplayName": "$(DISPLAY_NAME)",
                "CFBundleName": "$(DISPLAY_NAME)",
                "CFBundleShortVersionString": "\(App.version)",
                "NSUserNotificationsUsageDescription": "Notifications may include alerts, sounds, or badges. Can be adjusted anytime in Settings.",
                "NSMicrophoneUsageDescription": "Microphone access is needed to record voice.",
                "NSSpeechRecognitionUsageDescription": "Speech recognize access is needed to fill your tasks.",
                "NSPhotoLibraryUsageDescription": "Photo library access allows adding images from the device gallery.",
                // Background mode
                "UIBackgroundModes": ["fetch", "processing", "remote-notification"],
                "BGTaskSchedulerPermittedIdentifiers": [
                    "mido.robocode.updateNotificationsAndSync"
                ],
                // iCloud
                "NSUbiquitousContainers": [
                    "iCloud.com.mido.robocode": [
                        "NSUbiquitousContainerIsDocumentScopePublic": true,
                        "NSUbiquitousContainerSupportedFolderLevels": ["ANY"],
                        "NSUbiquitousContainerName": "Mi.dō",
                        "NSUbiquitousContainerIdentifier": "$(TeamIdentifierPrefix)$(CFBundleIdentifier)"
                    ]
                ],
                "CFBundleLocalizations": [
                    "en",
                    "ru",
                    "fr",
                    "fr-CA",
                    "es",
                    "es-MX",
                    "es-419",
                    "it",
                    "de",
                    "pt",
                    "pt-PT"
                ]
            ]
        )
    }
}
