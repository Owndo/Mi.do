//
//  LaunchView.swift
//  LaunchView
//
//  Created by Rodion Akhmedov on 2/11/26.
//

import SwiftUI
import VideoPlayerView
import UIComponents

public struct LaunchView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var vm = LaunchViewVM()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.defaultBackground.ignoresSafeArea()
            
            VideoPlayerView(
                url: vm.urlToVideo(colorScheme: colorScheme),
                backgroundColor: .defaultBackground
            )
        }
    }
}

#Preview {
    LaunchView()
}
