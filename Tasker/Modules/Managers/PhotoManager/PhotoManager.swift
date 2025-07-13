//
//  PhotoManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import Photos
import SwiftUI

final class PhotoManager {
    @Injected(\.permissionManager) var permissionManager
    @Injected(\.casManager) var casManager
    
    var alert: Alert?

}
