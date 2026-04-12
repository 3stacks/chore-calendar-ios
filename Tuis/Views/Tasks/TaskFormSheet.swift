import SwiftUI

struct TaskFormSheet: View {
    @Bindable var store: TaskStore
    var userStore: UserStore
    @Binding var isPresented: Bool
    var editingTask: ChoreTask?

    @State private var name = ""
    @State private var area = TaskArea.general.rawValue
    @State private var frequency = TaskFrequency.weekly.rawValue
    @State private var assignedTo: Int?
    @State private var notes = ""
    @State private var nextDue = Date()
    @State private var hasNextDue = false
    @State private var isSaving = false

    private var isEditing: Bool { editingTask != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("e.g. Clean kitchen", text: $name)
                        .submitLabel(.done)
                }

                Section("Details") {
                    Picker("Area", selection: $area) {
                        ForEach(TaskArea.allCases, id: \.rawValue) { a in
                            Text(a.rawValue).tag(a.rawValue)
                        }
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(TaskFrequency.allCases, id: \.rawValue) { f in
                            Text(f.label).tag(f.rawValue)
                        }
                    }

                    if !userStore.users.isEmpty {
                        Picker("Assigned To", selection: $assignedTo) {
                            Text("Unassigned").tag(nil as Int?)
                            ForEach(userStore.users) { user in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: user.color))
                                        .frame(width: 8, height: 8)
                                    Text(user.name)
                                }
                                .tag(user.id as Int?)
                            }
                        }
                    }
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasNextDue)
                    if hasNextDue {
                        DatePicker("Next Due", selection: $nextDue, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Chore" : "New Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let task = editingTask {
                    name = task.name
                    area = task.area
                    frequency = task.frequency
                    assignedTo = task.assignedTo
                    notes = task.notes ?? ""
                    if let dueString = task.nextDue {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        if let date = formatter.date(from: dueString) {
                            nextDue = date
                            hasNextDue = true
                        }
                    }
                }
                if userStore.users.isEmpty {
                    Task { await userStore.loadUsers() }
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSaving = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        var body: [String: Any] = [
            "name": trimmed,
            "area": area,
            "frequency": frequency,
        ]
        if let assignedTo { body["assignedTo"] = assignedTo }
        if !notes.isEmpty { body["notes"] = notes }
        if hasNextDue { body["nextDue"] = formatter.string(from: nextDue) }

        Task {
            if let task = editingTask {
                let success = await store.updateTask(id: task.id, body: body)
                isSaving = false
                if success {
                    HapticManager.success()
                    isPresented = false
                } else {
                    HapticManager.error()
                }
            } else {
                let result = await store.createTask(body: body)
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
