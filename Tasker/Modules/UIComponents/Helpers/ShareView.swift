//
//  ShareView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/25/25.
//

import SwiftUI

public struct ShareView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    public init(activityItems: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.activityItems = activityItems
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<ShareView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareView>) {}
}

#Preview {
    ShareView(activityItems: [Any]())
}

