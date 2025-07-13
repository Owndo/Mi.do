//
//  GalleryPermissions.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import SwiftUI

public enum GalleryPermissions {
    case galleryIsNotAvailable
    case silentError

    public func showingAlert() -> Alert {
        switch self {
        case .galleryIsNotAvailable:
            return Alert(
                title: Text("No photos for you 📸😢"),
                message: Text("I’d love to see your masterpieces… but I can’t. Photo access is off. Flip the switch in Settings?"),
                primaryButton: .default(Text("Go to Settings"), action: openSettings),
                secondaryButton: .cancel(Text("Not now"))
            )
            
        case .silentError:
            fatalError("Silent error occurred")
        }
    }
}
