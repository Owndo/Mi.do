//
//  HistoryView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import SwiftUI
import UIComponents

public struct HistoryView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissButton
    
    public init() {}
    
    public var body: some View {
        ZStack {
            colorScheme.backgroundColor()
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Coming soon...", bundle: .module)
                    .font(.system(.title2, design: .rounded, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.labelQuaternary)
                
                Text("one day, your steps will be here… but for now your story is just beginning.", bundle: .module)
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
                                .foregroundStyle(colorScheme.accentColor())
                            
                            Text("Profile", bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(colorScheme.accentColor())
                        }
                    }
                }
            }
            .toolbarBackground(osVersion.majorVersion >= 26 ? .clear : colorScheme.backgroundColor(), for: .navigationBar)
            .navigationBarBackButtonHidden()
            .navigationTitle(Text("Task history", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HistoryView()
}
