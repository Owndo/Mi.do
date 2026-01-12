//
//  DependencyManagerProtocol.swift
//  DependencyManager
//
//  Created by Rodion Akhmedov on 1/12/26.
//

import Foundation
import AppearanceManager
import CASManager
import DateManager
import NotificationManager
import OnboardingManager
import PermissionManager
import PlayerManager
import ProfileManager
import RecorderManager
import ProfileManager
import StorageManager
import SubscriptionManager
import TaskManager
import TelemetryManager

public protocol DependencyManagerProtocol {
    var casManager: CASManagerProtocol { get }
    var profileManager: ProfileManagerProtocol { get }
    var taskManager: TaskManagerProtocol { get }
    var onboardingManager: OnboardingManagerProtocol { get }
    var playerManager: PlayerManagerProtocol { get }
    var recorderManager: RecorderManagerProtocol { get }
    var dateManager: DateManagerProtocol { get }
    var permissionManager: PermissionProtocol { get }
    var notificationManager: NotificationManagerProtocol { get }
    var storageManager: StorageManagerProtocol { get }
    var appearanceManager: AppearanceManagerProtocol { get }
    var telemetryManager: TelemetryManagerProtocol { get }
    var subscriptionManager: SubscriptionManagerProtocol { get }
}
