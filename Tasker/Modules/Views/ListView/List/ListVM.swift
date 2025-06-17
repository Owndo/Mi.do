//
//  ListVM.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/26/25.
//

import Foundation
import SwiftUI
import Models
import Managers

@Observable
final class ListVM {
    @ObservationIgnored
    @Injected(\.dateManager) private var dateManager: DateManagerProtocol
    @ObservationIgnored
    @Injected(\.playerManager) private var playerManager: PlayerManagerProtocol
    @ObservationIgnored
    @Injected(\.taskManager) private var taskManager: TaskManagerProtocol
    
    //MARK: UI State
    var startSwipping = false
    var contentHeight: CGFloat = 0
    
    var tasks: [MainModel] {
        taskManager.tasks
    }
    
    var completedTasks: [MainModel] {
        taskManager.completedTasks
    }
    
    var countOfTodayTasks: Int {
        tasks.count + completedTasks.count
    }
    
    private var calendar: Calendar {
        dateManager.calendar
    }
    
    private var selectedDate: Double {
        calendar.startOfDay(for: dateManager.selectedDate).timeIntervalSince1970
    }
    
    //MARK: - Check for visible
    
    
    func backToTodayButtonTapped() {
        dateManager.backToToday()
    }
    
    func nextDaySwiped() {
        dateManager.addOneDay()
    }
    
    func previousDaySwiped() {
        dateManager.subtractOneDay()
    }
    
    //MARK: - Calculate size for gestureView
    func calculateGestureViewHeight(screenHeight: CGFloat, contentHeight: CGFloat, safeAreaTop: CGFloat, safeAreaBottom: CGFloat) -> CGFloat {
        let availableScreenHeight = screenHeight - safeAreaTop - safeAreaBottom
        let remainingHeight = availableScreenHeight - contentHeight
        
        let minGestureHeight: CGFloat = 50
        var maxGestureHeight: CGFloat = 250
        
        switch countOfTodayTasks {
        case 0: maxGestureHeight = 800
        case 1...2: maxGestureHeight = 500
        case 3: maxGestureHeight = 400
        case 4: maxGestureHeight = 350
        case 5: maxGestureHeight = 300
        default: break
        }
        
        let idealGestureHeight: CGFloat = 150
        
        switch remainingHeight {
        case let height where height >= idealGestureHeight:
            return min(height, maxGestureHeight)
            
        case let height where height >= minGestureHeight:
            return height
            
        default:
            return minGestureHeight
        }
    }
}
