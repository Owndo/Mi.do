//
//  AppView.swift
//  AppDelegate
//
//  Created by Rodion Akhmedov on 1/15/26.
//

import SwiftUI
import MainView
import UIComponents

public struct AppView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var vm: MainVM?
    
    public init() {}
    
    public var body: some View {
        VStack {
            if let mainVM = vm {
                MainView(vm: mainVM)
                    .preferredColorScheme(mainVM.appearanceManager.colorScheme)
                    .environment(\.appearanceManager, mainVM.appearanceManager)
            } else {
                ProgressView()
                    .task {
                        vm = await MainVM.createVM()
                    }
            }
        }
        .task(id: colorScheme) {
            vm?.appearanceManager.updateColors()
        }
    }
}

#Preview {
    AppView()
}
