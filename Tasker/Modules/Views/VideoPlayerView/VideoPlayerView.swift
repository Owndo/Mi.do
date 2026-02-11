//
//  VideoPlayerView.swift
//  VideoPlayerView
//
//  Created by Rodion Akhmedov on 2/11/26.
//

import SwiftUI
import AVKit

public struct VideoPlayerView: View {
    var vm: VideoPlayerVM
    var url: URL
    
    var backgroundColor: Color = .black
    
    public init(vm: VideoPlayerVM, url: URL) {
        self.vm = vm
        self.url = url
    }
    
    public var body: some View {
        ZStack {
            if let player = vm.player {
                PlayerView(player: player, color: backgroundColor)
                    .allowsHitTesting(false)
            }
        }
        .animation(.default, value: vm.player)
        .task {
            vm.createPlayer(path: url)
        }
    }
}

#Preview {
    VideoPlayerView(vm: VideoPlayerVM(), url: URL(string: "")!)
}

class PlayerUIView: UIView {
    
    // MARK: Properties
    
    let playerLayer = AVPlayerLayer()
    var color: UIColor
    
    // MARK: Init
    
    override init(frame: CGRect) {
        self.color = .clear
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        self.color = .clear
        super.init(coder: coder)
    }
    
    init(player: AVPlayer, color: Color) {
        self.color = UIColor(color)
        super.init(frame: .zero)
        playerSetup(player: player)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Life-Cycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    // MARK: Private
    
    private func playerSetup(player: AVPlayer) {
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        player.actionAtItemEnd = .none
        layer.addSublayer(playerLayer)
        playerLayer.backgroundColor = color.cgColor
    }
}

struct PlayerView: UIViewRepresentable {
    
    var player: AVPlayer
    
    var color: Color
    
    func makeUIView(context: Context) -> PlayerUIView {
        return PlayerUIView(player: player, color: color)
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: UIViewRepresentableContext<PlayerView>) {
        uiView.playerLayer.player = player
    }
}
