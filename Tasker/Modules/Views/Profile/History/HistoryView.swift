//
//  HistoryView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import SwiftUI
import UIComponents

struct HistoryView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var path: NavigationPath
    
    var body: some View {
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
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            path.removeLast()
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
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            path.removeLast()
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
            }
            .toolbarBackground(osVersion.majorVersion >= 26 ? .clear : colorScheme.backgroundColor(), for: .navigationBar)
            .navigationBarBackButtonHidden()
            .navigationTitle(Text("Task history", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HistoryView(path: .constant(NavigationPath()))
}
