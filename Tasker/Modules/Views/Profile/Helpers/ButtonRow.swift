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
    
    var button1: (() -> Void)?
    var button2: (() -> Void)?
    
    var firstDayOfWeek: LocalizedStringKey?
    
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
                
                if actionIcon != "chevron.right" {
                    Menu {
                        if let button1 = button1 {
                            Button {
                                button1()
                            } label: {
                                if firstDayOfWeek == "Sunday" {
                                    Image(systemName: "checkmark")
                                }
                                
                                Text("Sunday", bundle: .module)
                            }
                        }
                        
                        if let button2 = button2 {
                            Button {
                                button2()
                            } label: {
                                if firstDayOfWeek == "Monday" {
                                    Image(systemName: "checkmark")
                                }
                                
                                Text("Monday", bundle: .module)
                            }
                        }
                        
                    } label: {
                        HStack {
                            Text(firstDayOfWeek ?? "", bundle: .module)
                                .font(.system(.callout, design: .rounded, weight: .regular))
                            
                            Image(systemName: actionIcon)
                                .padding(.vertical, 12)
                        }
                    }
                    .tint(.labelQuaternary)
                } else {
                    Image(systemName: actionIcon)
                        .padding(.vertical, 12)
                        .tint(.labelQuaternary)
                }
            }
        }
        
    }
}

#Preview {
    ButtonRow(icon: "", title: "", action: {}, button1: {}, button2: {})
}
