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
import TaskView

@Observable
final class ListVM: HashableObject {
    @ObservationIgnored
    @Injected(\.casManager) private var casManager: CASManagerProtocol
    @ObservationIgnored
    @Injected(\.dateManager) private var dateManager: DateManagerProtocol
    @ObservationIgnored
    @Injected(\.playerManager) private var playerManager: PlayerManagerProtocol
    @ObservationIgnored
    @Injected(\.taskManager) private var taskManager: TaskManagerProtocol
    @ObservationIgnored
    @Injected(\.appearanceManager) private var appearanceManager: AppearanceManagerProtocol
    @ObservationIgnored
    @Injected(\.telemetryManager) private var telemetryManager: TelemetryManagerProtocol
    @ObservationIgnored
    @Injected(\.onboardingManager) var onboardingManager: OnboardingManagerProtocol
    
    //MARK: UI State
    var startSwipping = false
    var contentHeight: CGFloat = 0
    
    var selectedTask: TaskVM?
    
    var completedTasksHidden: Bool {
        casManager.profileModel.value.settings.completedTasksHidden
    }
    
    var deleteTip: Bool {
        casManager.profileModel.value.onboarding.deleteTip
    }
    
    var tasks: [TaskRowVM] = []
    
    var completedTasks: [TaskRowVM] = []
    
    var countOfTodayTasks: Int {
        tasks.count + completedTasks.count
    }
    
    private var calendar: Calendar {
        dateManager.calendar
    }
    
    private var selectedDate: Double {
        calendar.startOfDay(for: dateManager.selectedDate).timeIntervalSince1970
    }
    
    init() {
        Task {
            try await Task.sleep(for: .seconds(0.5))
            NotificationCenter.default.addObserver(self, selector: #selector(updateTasksList), name: Notification.Name("updateTasks"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(updateTasksList), name: Notification.Name("selectedDateChange"), object: nil)
        }
    }
    
    @objc func updateTasksList() {
        tasks.removeAll()
        completedTasks.removeAll()
        
        for i in taskManager.activeTasks {
            let taskRowVM = TaskRowVM(task: i)
            
            taskRowVM.selectedTask = { [weak self] task in
                self?.selectedTask = TaskVM(mainModel: task)
            }
            
            tasks.append(taskRowVM)
        }
        
        for i in taskManager.completedTasks {
            let taskRowVM = TaskRowVM(task: i)
            
            taskRowVM.selectedTask = { [weak self] task in
                self?.selectedTask = TaskVM(mainModel: task)
            }
            
            completedTasks.append(taskRowVM)
        }
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
    
    func completedTaskViewChange() {
        let model = casManager.profileModel
        model.value.settings.completedTasksHidden.toggle()
        
        casManager.saveProfileData(model)
        
        // telemetry
        if model.value.settings.completedTasksHidden {
            telemetryAction(.taskAction(.showCompletedButtonTapped))
        } else {
            telemetryAction(.taskAction(.hideCompletedButtonTapped))
        }
    }
    
    //MARK: - Telemetry action
    private func telemetryAction(_ action: EventType) {
        telemetryManager.logEvent(action)
    }
}
