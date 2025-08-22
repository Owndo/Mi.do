//
//  RecordAnimation.swift
//  UIComponents
//
//  Created by Rodion Akhmedov on 8/21/25.
//

import SwiftUI

struct RecordAnimation: View {
    
    @State private var timer: Timer?
    @State private var t: Float = 0.0
    
    private let shaderFunction = ShaderFunction(library: .default, name: "airdrop")
    
    var body: some View {
        VStack {
            Image("mick")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(x: 1.0, y: -1.0)
                .distortionEffect(
                    Shader(function: shaderFunction,
                           arguments: [
                            .float(t),
                            .float2(Float(UIScreen.main.bounds.width),
                                    Float(UIScreen.main.bounds.height))
                           ]), maxSampleOffset: CGSize(width: 800.0, height: 800.0)
                )
        }
        .ignoresSafeArea()
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { _ in
                t = (t + 0.01).truncatingRemainder(dividingBy: 2.0)
            })
        }
    }
}

#Preview {
    RecordAnimation()
}
