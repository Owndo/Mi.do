//
//  ButtonRow.swift
//  Profile
//
//  Created by Rodion Akhmedov on 7/28/25.
//

import SwiftUI

public struct SettingsButtonRow: View {
    @Environment(\.appearanceManager) var appearanceManager
    
    public var icon: String
    public var title: LocalizedStringKey
    public var actionIcon: String = "chevron.right"
    public var action: () -> Void
    
    public init(icon: String, title: LocalizedStringKey, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(appearanceManager.accentColor)
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
    SettingsButtonRow(icon: "", title: "", action: {})
}
