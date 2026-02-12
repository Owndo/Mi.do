//
//  ArticlesView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import SwiftUI
import UIComponents

public struct ArticlesView: View {
    @Environment(\.appearanceManager) private var appearanceManager
    @Environment(\.dismiss) var dismissButton
    
    public init() {}
    
    public var body: some View {
        ZStack {
            appearanceManager.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 12) {
                Text("Coming soon...", bundle: .module)
                    .font(.system(.title2, design: .rounded, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.labelQuaternary)
                
                Text("but for now - look at the wonderful world within and around you...", bundle: .module)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.labelQuaternary)
            }
            .padding(.horizontal, 45)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismissButton()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17))
                                .foregroundStyle(appearanceManager.accentColor)
                            
                            Text("Profile", bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(appearanceManager.accentColor)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .navigationTitle(Text("Articles", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ArticlesView()
}
