//
//  ButtonRow.swift
//  Profile
//
//  Created by Rodion Akhmedov on 7/28/25.
//

import SwiftUI
import UIComponents

struct ButtonRow: View {
    @Environment(\.colorScheme) var colorScheme
    
    var icon: String
    var title: LocalizedStringKey
    var actionIcon: String = "chevron.right"
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(colorScheme.accentColor())
                    .frame(width: 32, height: 32)
                
                Text(title, bundle: .module)
                    .font(.system(.callout, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelPrimary)
                    .minimumScaleFactor(0.5)
                
                Spacer()
                
                Image(systemName: actionIcon)
                    .padding(.vertical, 12)
                    .tint(.labelQuaternary)
            }
        }
    }
}

#Preview {
    ButtonRow(icon: "", title: "", action: {})
}
