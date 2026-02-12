//
//  AppView.swift
//  AppDelegate
//
//  Created by Rodion Akhmedov on 1/15/26.
//

import SwiftUI
import MainView
import AVKit
import LaunchView

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
                LaunchView()
                    .task {
                        await vm.startVM()
                    }
            }
        }
        .animation(.default, value: vm.mainViewVM)
        .task(id: colorScheme) {
            vm.mainViewVM?.appearanceManager.updateColors()
        }
    }
}

#Preview {
    AppView()
}
