//
//  ProfileView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/11/25.
//

import SwiftUI
import Models
import UIComponents
import PaywallView
import PhotosUI
import ArticlesView
import AppearanceView
import HistoryView
import SettingsView
import AppearanceManager

//TODO: - Keyboard ignore safe area
public struct ProfileView: View {
    @Environment(\.appearanceManager) private var appearanceManager
    @Environment(\.colorScheme) private var colorScheme
    
    @Bindable var vm: ProfileVM
    
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    
    public init(vm: ProfileVM) {
        self.vm = vm
    }
    
    public var body: some View {
        NavigationStack(path: $vm.path) {
            ZStack {
                appearanceManager.backgroundColor.ignoresSafeArea()
                
                ScrollViewContent()
                    .photosPicker(
                        isPresented: $vm.showLibrary,
                        selection: $vm.selectedItems,
                        maxSelectionCount: 1,
                        matching: .images
                    )
                
                if let vm = vm.paywallVM {
                    PaywallView(vm: vm)
                }
            }
            .navigationDestination(for: ProfileDestination.self) { desctination in
                desctination.destination()
            }
            .alert(item: $vm.alert) { alert in
                alert.alert
            }
            .toolbar {
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            vm.closeButtonTapped()
                        } label: {
                            Text("Close", bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(appearanceManager.accentColor)
                                .opacity(vm.showPaywall ? 0.0 : 1)
                        }
                    }
                    .sharedBackgroundVisibility(vm.showPaywall ? .hidden : .visible)
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            vm.closeButtonTapped()
                        } label: {
                            Text("Close", bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(appearanceManager.accentColor)
                            
                        }
                    }
                }
            }
        }
        .onAppear {
            vm.onAppear()
        }
        .onDisappear {
            vm.onDisappear()
        }
        .onChange(of: vm.path.count) { oldValue, newValue in
            vm.navigationTriger.toggle()
            vm.gearAnimation.toggle()
        }
        .onChange(of: colorScheme) { _, newValue in
            vm.gearAnimation.toggle()
        }
        .toolbarBackground(appearanceManager.backgroundColor, for: .navigationBar)
        .presentationCornerRadius(osVersion.majorVersion >= 26 ? nil : 26)
        .presentationDragIndicator(.visible)
        .animation(.bouncy, value: vm.showPaywall)
        .animation(.bouncy, value: vm.selectedImage)
        .sensoryFeedback(.selection, trigger: vm.navigationTriger)
        .sensoryFeedback(.decrease, trigger: vm.gearAnimation)
    }
    
    //MARK: - Scroll View
    @ViewBuilder
    private func ScrollViewContent() -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    GearSettingsButton()
                    
                    ProfilePhoto()
                        .padding(.bottom, 14)
                    
                }
                .padding(.top, 25)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                TextField(text: $vm.profileModel.name, prompt: Text("Enter your name here", bundle: .module)) {}
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.labelPrimary)
                    .multilineTextAlignment(.center)
                    .tint(appearanceManager.accentColor)
                    .onSubmit {
                        Task {
                            await vm.profileModelSave()
                        }
                    }
                
                TaskStatic()
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                    .ignoresSafeArea(.keyboard)
                
                ButtonsList()
                    .padding(.bottom, 28)
                    .ignoresSafeArea(.keyboard)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .ignoresSafeArea(.keyboard)
        }
        .scrollIndicators(.hidden)
    }
    
    //MARK: - Gear/Settings Button
    @ViewBuilder
    private func GearSettingsButton() -> some View {
        Button {
            vm.goToSettingsButtonTapped()
        } label: {
            if #available(iOS 26.0, *) {
                Image(systemName: "gearshape")
                    .foregroundStyle(appearanceManager.accentColor)
                    .font(.system(size: 30))
                    .rotationEffect(Angle(degrees: vm.gearAnimation ? -360 : 0))
                    .symbolEffect(.bounce, options: .speed(0.6), value: vm.gearAnimation)
                    .padding(5)
                    .glassEffect(.regular.interactive())
                    .disabled(vm.showPaywall ? true : false)
            } else {
                Image(systemName: "gearshape")
                    .foregroundStyle(appearanceManager.accentColor)
                    .font(.system(size: 30))
                    .rotationEffect(Angle(degrees: vm.gearAnimation ? 270 : 0))
                    .symbolEffect(.bounce,options: .speed(0.6), value: vm.gearAnimation)
                    .padding(4)
                    .shadow(color: appearanceManager.accentColor.opacity(0.5), radius: 16, y: 4)
                    .background(
                        Circle()
                            .fill(.backgroundTertiary)
                    )
                    .animation(.spring(duration: 2), value: vm.gearAnimation)
            }
        }
        .animation(.spring(duration: 2), value: vm.gearAnimation)
        .offset(vm.buttonOffset)
    }
    
    //MARK: - Photo
    @ViewBuilder
    private func ProfilePhoto() -> some View {
        ZStack {
            VStack {
                Button {
                    vm.addPhotoButtonTapped()
                } label: {
                    if let image = vm.selectedImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .offset(vm.photoPosition)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        vm.photoPosition = value.translation
                                    }
                                    .onEnded { _ in
                                        vm.savePhotoPosition()
                                    }
                            )
                    } else {
                        EmptyPhoto()
                    }
                }
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(appearanceManager.backgroundColor, lineWidth: 1))
            .shadow(color: appearanceManager.accentColor.opacity(0.7), radius: 15, x: 0, y: 8)
            .frame(width: 148, height: 148)
            
            VStack(spacing: 0) {
                
                Spacer()
                
                HStack(spacing: 0) {
                    
                    Spacer()
                    
                    ContextMenu()
                }
            }
        }
        .frame(width: 148, height: 148)
        .sensoryFeedback(.selection, trigger: vm.showLibrary)
    }
    
    //MARK: - Empty photo
    @ViewBuilder
    private func EmptyPhoto() -> some View {
        Image(systemName: "person.crop.circle.badge.plus")
            .font(.system(size: 28))
            .foregroundStyle(.labelQuaternary)
            .padding(50)
            .background(
                RoundedRectangle(cornerRadius: 1)
                    .fill(.backgroundTertiary)
            )
    }
    
    //MARK: - Context menu
    @ViewBuilder
    private func ContextMenu() -> some View {
        Menu {
            Button {
                vm.addPhotoButtonTapped()
            } label: {
                HStack {
                    Text("Edit avatar", bundle: .module)
                    
                    Image(systemName: "photo.on.rectangle")
                }
            }
            
            Button(role: .destructive) {
                Task {
                    await vm.deletePhotoFromProfile()
                }
            } label: {
                HStack {
                    Text("Delete photo", bundle: .module)
                    
                    Image(systemName: "trash")
                }
            }
        } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundStyle(appearanceManager.accentColor)
                    .font(.system(size: 28))
                    .liquidIfAvailable(glass: .regular, isInteractive: true)
        }
        .padding(2)
        .background(
            Circle()
                .fill(appearanceManager.backgroundColor)
        )
    }
    
    //MARK: Task's static
    @ViewBuilder
    private func TaskStatic() -> some View {
        HStack {
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .today), text: "Today's tasks")
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            CustomDivider()
                .frame(maxWidth: 1, maxHeight: .infinity)
                .ignoresSafeArea()
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .week), text: "Tasks this week")
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            CustomDivider()
                .frame(maxWidth: 1, maxHeight: .infinity)
                .ignoresSafeArea()
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .completed), text: "Completed")
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding(.vertical, 18)
        .frame(maxHeight: 96)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.backgroundTertiary)
        )
    }
    
    //MARK: Static row
    @ViewBuilder
    private func StaticRow(count: String, text: LocalizedStringKey) -> some View {
        VStack {
            Text(count)
                .font(.system(.title, design: .rounded, weight: .regular))
                .foregroundStyle(.labelPrimary)
            
            Text(text, bundle: .module)
                .font(.system(.caption2, design: .rounded, weight: .regular))
                .foregroundStyle(.labelSecondary)
        }
    }
    
    //MARK: - Active buttons
    @ViewBuilder
    private func ButtonsList() -> some View {
        VStack {
            SettingsButtonRow(icon: "text.rectangle.page", title: Text("Articles", bundle: .module)) {
                vm.articlesButtonTapped()
            }
            
            CustomDivider()
                .frame(height: 1)
                .padding(.leading, 38)
            
            SettingsButtonRow(icon: "clock.arrow.circlepath", title: Text("Task history", bundle: .module)) {
                vm.taskHistoryButtonTapped()
            }
            
            if vm.isnotActiveSubscription() {
                CustomDivider()
                    .frame(height: 1)
                    .padding(.leading, 38)
                
                SettingsButtonRow(icon: "crown", title: Text("Purchase a subscription", bundle: .module)) {
                    Task {
                        await vm.subscriptionButtonTapped()
                    }
                }
            }
            
            Spacer()
            
            CreatedDate()
                .padding(.top, 28)
        }
    }
    
    //MARK: - Custom divider
    
    @ViewBuilder
    private func CustomDivider() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.separatorSecondary)
    }
    
    //MARK: - Created Date
    @ViewBuilder
    private func CreatedDate() -> some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelTertiary)
            
            Text("Created:", bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelTertiary)
            
            Text(vm.createdDate.formatted(.dateTime.month().day().hour().minute().year()))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelSecondary)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ProfileView(vm: ProfileVM.createProfilePreviewVM())
}
