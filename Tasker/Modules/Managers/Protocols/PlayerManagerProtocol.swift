//
//  PlayerManagerProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Foundation
import Models

public protocol PlayerManagerProtocol: Sendable {
    var isPlaying: Bool { get set }
    var task: TaskModel? { get set }
    var currentTime: TimeInterval { get set }
    var totalTime: TimeInterval { get set }
    
    func playAudioFromData(task: TaskModel) async
    func pauseAudio()
    func stopToPlay()
    func seekAudio(_ time: TimeInterval)
    func returnTotalTime(task: TaskModel) -> Double
}
