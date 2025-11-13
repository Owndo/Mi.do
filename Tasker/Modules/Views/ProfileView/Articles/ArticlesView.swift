//
//  ArticlesView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import SwiftUI
import UIComponents

struct ArticlesView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var path: NavigationPath
    
    var body: some View {
        ZStack {
            colorScheme.backgroundColor().ignoresSafeArea()
            
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
            .navigationBarBackButtonHidden()
            .navigationTitle(Text("Articles", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ArticlesView(path: .constant(NavigationPath()))
}
