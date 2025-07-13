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
            colorScheme.backgroundColor.hexColor()
                .ignoresSafeArea()
            VStack {
                Text("Coming soon...")
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
                            
                            Text("Profile")
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .tint(colorScheme.elementColor.hexColor())
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .navigationTitle("Articles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ArticlesView(path: .constant(NavigationPath()))
}
