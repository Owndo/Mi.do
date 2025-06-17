//
//  PermissionProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Foundation

public protocol PermissionProtocol {
    var allowedMicro: Bool { get set }
    
    func peremissionSessionForRecording() throws
    func requestRecordPermission()
}
