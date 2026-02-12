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
            
            if let player = vm.player {
                VideoPlayerView(player: player,backgroundColor: .defaultBackground)
            }
        }
        .animation(.default, value: vm.player)
        .task {
            vm.createPlayer(colorScheme: colorScheme)
        }
        .onDisappear {
            vm.removeManager()
        }
    }
}

#Preview {
    LaunchView()
}
