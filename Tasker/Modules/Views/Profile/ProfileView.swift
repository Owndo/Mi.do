//
//  ProfileView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/11/25.
//

import SwiftUI
import UIComponents

public struct ProfileView: View {
    @AppStorage("profileName") var profileName = ""
    
    @State private var vm = ProfileVM()
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissButton
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                colorScheme.backgroundColor.hexColor()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    ProfilePhoto()
                        .padding(.bottom, 14)
                    
                    TextField("Enter your name here", text: $profileName)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.labelPrimary)
                        .multilineTextAlignment(.center)
                        .tint(colorScheme.elementColor.hexColor())
                    
                    TaskStatic()
                        .padding(.top, 20)
                    
                    
                    
                    Spacer()
                    
                }
                .padding(.top, 25)
                .padding(.horizontal, 16)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismissButton()
                        } label: {
                            Text("Close")
                                .foregroundStyle(colorScheme.elementColor.hexColor())
                        }
                    }
                }
            }
        }
    }
    
    
    //MARK: - Photo
    @ViewBuilder
    private func ProfilePhoto() -> some View {
        ZStack {
            Image(systemName: "person.crop.circle.badge.plus")
                .foregroundStyle(.labelQuaternary)
                .background(
                    Circle()
                        .fill(
                            .backgroundTertiary
                        )
                        .frame(width: 128, height: 128)
                )
            
            VStack(spacing: 0) {
                
                Spacer()
                
                HStack(spacing: 0) {
                    
                    Spacer()
                    
                    ContextMenu()
                }
            }
        }
        .frame(width: 128, height: 128)
    }
    
    //MARK: - Context menu
    @ViewBuilder
    private func ContextMenu() -> some View {
        Menu {
            
            Button {
                
            } label: {
                HStack {
                    Text("Edit avatar")
                    
                    Image(systemName: "photo.on.rectangle")
                }
            }
            
            Button {
                
            } label: {
                HStack {
                    Text("Log out")
                    
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                }
            }
            
            Button(role: .destructive) {
                
            } label: {
                HStack {
                    Text("Delete profile")
                    
                    Image(systemName: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .foregroundStyle(colorScheme.elementColor.hexColor())
                .font(.system(size: 28))
        }
        .padding(3)
        .background(
            Circle()
                .fill(colorScheme.backgroundColor.hexColor())
        )
    }
    
    //MARK: Task's static
    @ViewBuilder
    private func TaskStatic() -> some View {
        HStack {
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .today), text: "Today's tasks")
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 1)
                .fill(.labelQuaternary)
                .frame(maxWidth: 1, maxHeight: .infinity)
                .ignoresSafeArea()
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .week), text: "Tasks this week")
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 1)
                .fill(.labelQuaternary)
                .frame(maxWidth: 1, maxHeight: .infinity)
                .ignoresSafeArea()
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .completed), text: "Completed")
            
            Spacer()
        }
        .padding(.top, 18)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.backgroundTertiary)
        )
    }
    
    //MARK: Static row
    @ViewBuilder
    private func StaticRow(count: String, text: String) -> some View {
        VStack {
            Text(count)
                .font(.system(.title, design: .rounded, weight: .regular))
                .foregroundStyle(.labelPrimary)
            
            Text(text)
                .font(.system(.caption2, design: .rounded, weight: .regular))
                .foregroundStyle(.labelSecondary)
        }
    }
}

#Preview {
    ProfileView()
}
