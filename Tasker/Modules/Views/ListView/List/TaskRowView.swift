//
//  TaskRowView.swift
//  ListView
//
//  Created by Rodion Akhmedov on 1/20/26.
//

import SwiftUI
import Models
import UIComponents
import TaskView

struct TaskRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var task: UITaskModel
    var vm: ListVM
    
    @State var isPressed = false
    
    var body: some View {
        if #available(iOS 26, *) {
            HStack(spacing: 0) {
                HStack(spacing: 12) {
                    TaskCheckMark(complete: vm.checkCompletedTaskForToday(task: task), task: task) {
                        Task {
                            await vm.checkMarkTapped(task: task)
                        }
                    }
                    
                    HStack {
                        Text(LocalizedStringKey(vm.taskTitle(task: task)), bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(colorScheme.invertedPrimaryLabel(task))
                            .font(.callout)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                HStack(spacing: 12) {
                    NotificationDeadlineDate(task: task)
                        .allowsHitTesting(vm.isTaskHasDeadline(task: task))
                        .onTapGesture {
                            vm.showDedalineButtonTapped(task: task)
                        }
                    
                    PlayButton(task: task)
                }
            }
            
            //MARK: - Delete dialog
            
            .taskDeleteDialog(isPresented: vm.dialogBinding(for: task), task: task) { value in
                await vm.deleteButtonTapped(task: task, deleteCompletely: value)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 11)
            .background(
                withAnimation {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            task.taskRowColor(colorScheme: colorScheme)
                        )
                }
            )
            
            //MARK: - Context menu
            
            .contextMenuWithPreview(
                menu: CustomMenu(),
                preview: {
                    TaskViewPreview(listVM: vm, task: task)
                },
                isPressed: $isPressed,
                action: {
                    vm.taskTapped(task)
                })
            .frame(height: 52)
        } else {
            HStack(spacing: 0) {
                HStack(spacing: 12) {
                    TaskCheckMark(complete: vm.checkCompletedTaskForToday(task: task), task: task) {
                        Task {
                            await vm.checkMarkTapped(task: task)
                        }
                    }
                    
                    HStack {
                        Text(LocalizedStringKey(vm.taskTitle(task: task)), bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(colorScheme.invertedPrimaryLabel(task))
                            .font(.callout)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                HStack(spacing: 12) {
                    NotificationDeadlineDate(task: task)
                        .allowsHitTesting(vm.isTaskHasDeadline(task: task))
                        .onTapGesture {
                            vm.showDedalineButtonTapped(task: task)
                        }
                    
                    PlayButton(task: task)
                }
            }
            
            //MARK: - Context menu
            
            .contextMenu {
                ControlGroup {
                    Button {
                        vm.taskTapped(task)
                    } label: {
                        VerticalButtonLabel(text: "Open", systemImage: "arrowshape.up")
                    }
                    
                    Button {
                        Task {
                            await vm.checkMarkTapped(task: task)
                        }
                    } label: {
                        if vm.checkCompletedTaskForToday(task: task) {
                            VerticalButtonLabel(text: "Undo", systemImage: "circle")
                        } else {
                            VerticalButtonLabel(text: "Done", systemImage: "checkmark.circle")
                        }
                    }
                    
                    Button(role: .destructive) {
                        vm.deleteTaskButtonSwiped(task: task)
                    } label: {
                        VerticalButtonLabel(text: "Delete", systemImage: "trash")
                    }
                }
            } preview: {
                TaskViewPreview(listVM: vm, task: task)
            }
            
            //MARK: - Delete dialog
            
            .taskDeleteDialog(isPresented: vm.dialogBinding(for: task), task: task) { value in
                await vm.deleteButtonTapped(task: task, deleteCompletely: value)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 11)
            .background(
                withAnimation {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            task.taskRowColor(colorScheme: colorScheme)
                        )
                }
            )
            .frame(height: 52)
        }
    }
    
    //MARK: - Notification/Deadline date
    
    @ViewBuilder
    private func NotificationDeadlineDate(task: UITaskModel) -> some View {
        if vm.showDeadlinePicker {
            Text(LocalizedStringKey(vm.timeRemainingString(task: task)), bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(vm.isTaskOverdue(task: task) ? .accentRed : colorScheme.invertedTertiaryLabel(task))
                .underline(true, pattern: .dot, color: vm.isTaskOverdue(task: task) ? .accentRed : .labelQuaternary)
        } else {
            Text(Date(timeIntervalSince1970: task.notificationDate), format: .dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(colorScheme.invertedTertiaryLabel(task))
                .underline(vm.isTaskHasDeadline(task: task) ? true : false, pattern: .dot, color: vm.isTaskOverdue(task: task) ? .accentRed : .labelQuaternary)
                .padding(.leading, 6)
                .lineLimit(1)
        }
    }
    
    //MARK: - Play Button
    
    @ViewBuilder
    private func PlayButton(task: UITaskModel) -> some View {
        ZStack {
            Circle()
                .fill(colorScheme.invertedBackgroundTertiary(task))
            
            if task.audio != nil {
                Image(systemName: vm.playButton(task: task) ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
                    .animation(.default, value: vm.playing)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        Task {
                            await vm.playButtonTapped(task: task)
                        }
                    }
            } else {
                Image(systemName: "plus").bold()
                    .foregroundStyle(.white)
                    .animation(.default, value: vm.playing)
            }
        }
        .frame(width: 28, height: 28)
    }
    
    //MARK: - Context Menu
    
    private func CustomMenu() -> UIMenu {
        UIMenu(
            title: "",
            children: [DoneUndoAction(task: task), DeleteAction(task: task)]
        )
    }
    
    //MARK: - Menu Actions
    private func DoneUndoAction(task: UITaskModel) -> UIAction {
        UIAction(
            title: vm.checkCompletedTaskForToday(task: task) ?
            NSLocalizedString("Undo", bundle: .module, comment: "Context menu done/undo button") :
                NSLocalizedString("Done", bundle: .module, comment: "Context menu done/undo button"),
            image: UIImage(systemName: vm.checkCompletedTaskForToday(task: task) ? "circle" : "checkmark.circle"),
            handler: { _ in
                Task {
                    await vm.checkMarkTapped(task: task)
                }
            })
    }
    
    private func DeleteAction(task: UITaskModel) -> UIAction {
        UIAction(
            title: NSLocalizedString("Delete", bundle: .module, comment: "Context menu delete button"),
            image: UIImage(systemName: "trash"),
            attributes: .destructive,
            handler: { _ in
                vm.deleteTaskButtonSwiped(task: task)
            })
    }
    
    //MARK: - Menu Buttons
    
    @ViewBuilder
    private func VerticalButtonLabel(text: LocalizedStringKey, systemImage: String) -> some View {
        VStack {
            Text(text, bundle: .module)
            
            Image(systemName: systemImage)
        }
    }
}

#Preview {
    TaskRowView(task: mockModel(), vm: ListVM.creteMockListVM())
}


//MARK: - Task View Preview

struct TaskViewPreview: View {
    
    var listVM: ListVM
    var task: UITaskModel
    
    var body: some View {
        TaskView(taskVM: listVM.tasksVM.first(where: { $0.task.id == task.id })!, preview: true)
    }
}

extension View {
    func contextMenuWithPreview<Content: View>(menu: UIMenu, @ViewBuilder preview: @escaping () -> Content, isPressed: Binding<Bool>, action: @escaping () -> Void) -> some View {
        self
            .scaleEffect(isPressed.wrappedValue ? 0.95 : 1)
            .opacity(isPressed.wrappedValue ? 0.85 : 1)
            .animation(.easeIn(duration: 0.35), value: isPressed.wrappedValue)
            .overlay(
                InteractionView(
                    preview: preview,
                    menu: menu,
                    isPressed: isPressed,
                    didTapPreview: action
                )
                .ignoresSafeArea(edges: .vertical)
                .padding(.horizontal, 40)
            )
    }
}

//MARK: - UIKit Preview

private struct InteractionView<Content: View>: UIViewRepresentable {
    let preview: () -> Content
    let menu: UIMenu
    let isPressed: Binding<Bool>
    let didTapPreview: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let menuInteraction = UIContextMenuInteraction(delegate: context.coordinator)
        
        view.addInteraction(menuInteraction)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            preview: preview(),
            menu: menu,
            isPressed: isPressed,
            didTapPreview: didTapPreview
        )
    }
    
    class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        let preview: Content
        let menu: UIMenu
        let isPressed: Binding<Bool>
        let didTapPreview: () -> Void
        
        init(
            preview: Content,
            menu: UIMenu,
            isPressed: Binding<Bool>,
            didTapPreview: @escaping () -> Void
        ) {
            self.preview = preview
            self.menu = menu
            self.isPressed = isPressed
            self.didTapPreview = didTapPreview
            
            menu.preferredElementSize = .medium
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            Task {
                self.isPressed.wrappedValue = true
                
                try? await Task.sleep(for: .seconds(0.5))
                
                self.isPressed.wrappedValue = false
            }
            
            return UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: {
                    UIHostingController(rootView: self.preview)
                },
                actionProvider: { _ in
                    self.menu
                }
            )
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
            animator.addCompletion(self.didTapPreview)
        }
    }
}

final class PreviewHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
}
