//
//  PermissionProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Foundation
import SwiftUI

public protocol PermissionProtocol {
    var allowedMicro: Bool { get set }
    var alert: Alert? { get }
    
    func peremissionSessionForRecording() throws
    func requestRecordPermission()
    
    func permissionForGallery() async -> Bool
}
