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
    var task: UITaskModel? { get set }
    var currentTime: TimeInterval { get set }
    var totalTime: TimeInterval { get set }
    
    func playAudioFromData(task: UITaskModel) async
    func pauseAudio()
    func stopToPlay()
    func seekAudio()
    func returnTotalTime(task: UITaskModel) async -> Double
    func setUpTotalTime(task: UITaskModel) async
    func resetAudioProgress()
}
