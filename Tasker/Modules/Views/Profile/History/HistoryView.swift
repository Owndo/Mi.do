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
            VStack {
                Text("Coming soon...", bundle: .module)
                    .font(.system(.title2, design: .rounded, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.labelQuaternary)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        path.removeLast()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17))
                            
                            Text("Profile", bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .tint(colorScheme.accentColor())
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .navigationTitle(Text("Task history", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HistoryView(path: .constant(NavigationPath()))
}
