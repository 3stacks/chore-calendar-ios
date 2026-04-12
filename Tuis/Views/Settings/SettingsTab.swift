import SwiftUI

struct SettingsTab: View {
    @State private var userStore = UserStore()
    @State private var showingAddUser = false
    @State private var editingUser: User?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(userStore.users) { user in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: user.color))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Text(String(user.name.prefix(1)).uppercased())
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }

                            Text(user.name)
                                .font(.body)

                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingUser = user
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await userStore.deleteUser(id: user.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    Button {
                        showingAddUser = true
                    } label: {
                        Label("Add Person", systemImage: "plus")
                    }
                } header: {
                    Text("Household Members")
                } footer: {
                    Text("Household members can be assigned to chores and shopping items.")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Server")
                        Spacer()
                        Text(APIConfig.baseURL)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .refreshable {
                await userStore.loadUsers()
            }
            .task {
                if userStore.users.isEmpty {
                    await userStore.loadUsers()
                }
            }
            .sheet(isPresented: $showingAddUser) {
                UserFormSheet(userStore: userStore, isPresented: $showingAddUser)
            }
            .sheet(item: $editingUser) { user in
                UserFormSheet(userStore: userStore, isPresented: .init(
                    get: { editingUser != nil },
                    set: { if !$0 { editingUser = nil } }
                ), editingUser: user)
            }
        }
    }
}

// MARK: - User Form Sheet

private struct UserFormSheet: View {
    var userStore: UserStore
    @Binding var isPresented: Bool
    var editingUser: User?

    @State private var name = ""
    @State private var selectedColor = "#3b82f6"
    @State private var isSaving = false

    private var isEditing: Bool { editingUser != nil }

    static let presetColors: [String] = [
        "#3b82f6", // Blue
        "#ef4444", // Red
        "#22c55e", // Green
        "#f59e0b", // Amber
        "#8b5cf6", // Violet
        "#ec4899", // Pink
        "#06b6d4", // Cyan
        "#f97316", // Orange
        "#14b8a6", // Teal
        "#6366f1", // Indigo
        "#a855f7", // Purple
        "#64748b", // Slate
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Luke", text: $name)
                        .submitLabel(.done)
                }

                Section("Color") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Self.presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if selectedColor == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = hex
                                    HapticManager.selection()
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Edit Person" : "Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let user = editingUser {
                    name = user.name
                    selectedColor = user.color
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        Task {
            if let user = editingUser {
                let success = await userStore.updateUser(id: user.id, name: trimmed, color: selectedColor)
                isSaving = false
                if success {
                    HapticManager.success()
                    isPresented = false
                } else {
                    HapticManager.error()
                }
            } else {
                let result = await userStore.createUser(name: trimmed, color: selectedColor)
                isSaving = false
                if result != nil {
                    HapticManager.success()
                    isPresented = false
                } else {
                    HapticManager.error()
                }
            }
        }
    }
}

#Preview {
    SettingsTab()
}
