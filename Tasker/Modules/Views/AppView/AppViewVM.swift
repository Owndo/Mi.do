//
//  AppViewVM.swift
//  AppView
//
//  Created by Rodion Akhmedov on 2/8/26.
//

import AVKit
import Foundation
import MainView
import SwiftUI
import VideoManager

@Observable
final class AppViewVM {
    /// Main view model for the whole app logic
    var mainViewVM: MainVM?
    
    //MARK: - Start VM
    
    func startVM() async {
        async let mainVM = MainVM.createVM()
        async let delay: () = Task.sleep(for: .seconds(1.5))
        
        let (vm, _) = await (mainVM, try? delay)
        
        self.mainViewVM = vm
    }
}
