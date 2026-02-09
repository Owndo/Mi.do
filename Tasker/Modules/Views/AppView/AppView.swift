//
//  AppView.swift
//  AppDelegate
//
//  Created by Rodion Akhmedov on 1/15/26.
//

import SwiftUI
import MainView
import AVKit

public struct AppView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vm = AppViewVM()
    
    public init() {}
    
    public var body: some View {
        VStack {
            if let mainVM = vm.mainViewVM {
                MainView(vm: mainVM)
                    .preferredColorScheme(mainVM.appearanceManager.colorScheme)
                    .environment(\.appearanceManager, mainVM.appearanceManager)
            } else {
                launchScreen()
                    .task {
                        await vm.startVM()
                    }
            }
        }
        .sensoryFeedback(vm.feedback(), trigger: vm.trigger)
        .animation(.default, value: vm.player)
        .task(id: colorScheme) {
            vm.mainViewVM?.appearanceManager.updateColors()
        }
    }
    
    private func launchScreen() -> some View {
        VStack {
            if let player = vm.player {
                VideoPlayer(player: player)
                    .scaledToFill()
                    .allowsHitTesting(false)
                    .offset(x: -50)
            }
        }
        .ignoresSafeArea()
        .task {
            await vm.startLaunchScreen(colorScheme: colorScheme)
        }
    }
    
    
}

#Preview {
    AppView()
}
