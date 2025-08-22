//
//  WaveAnimation.metal
//  UIComponents
//
//  Created by Rodion Akhmedov on 8/21/25.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] float2 singleWave(float2 position, float time) {
    float screenHeight = 800.0;
    
    
    float waveY = screenHeight - (time * 200.0);
    
    float distanceFromWave = abs(position.y - waveY);
    float waveWidth = 40.0;
    float amplitude = 15.0;
    
    if (distanceFromWave < waveWidth) {
        float strength = (waveWidth - distanceFromWave) / waveWidth;
        strength = smoothstep(0.0, 1.0, strength);
        
        float displacement = amplitude * strength * sin(position.x * 0.01 + time * 3.0);
        position.x += displacement;
    }
    
    return position;
}
