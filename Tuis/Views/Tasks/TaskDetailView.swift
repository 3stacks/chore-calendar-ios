import SwiftUI

struct TaskDetailView: View {
    @Bindable var store: TaskStore
    var userStore: UserStore
    let task: ChoreTask

    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showSnoozeMenu = false
    @Environment(\.dismiss) private var dismiss

    private var assignedUser: User? {
        guard let assignedTo = task.assignedTo else { return nil }
        return userStore.users.first { $0.id == assignedTo }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status badge
                HStack {
                    statusBadge(task.status)
                    Spacer()
                }

                // Details
                VStack(alignment: .leading, spacing: 12) {
                    detailRow(icon: "house", label: "Area", value: task.area)
                    detailRow(
                        icon: "repeat",
                        label: "Frequency",
                        value: TaskFrequency(rawValue: task.frequency)?.label ?? task.frequency
                    )

                    if let user = assignedUser {
                        HStack(spacing: 8) {
                            Image(systemName: "person")
                                .frame(width: 20)
                                .foregroundStyle(.secondary)
                            Text("Assigned to")
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: user.color))
                                    .frame(width: 10, height: 10)
                                Text(user.name)
                                    .fontWeight(.medium)
                            }
                        }
                    }

                    if let nextDue = task.nextDue {
                        detailRow(icon: "calendar", label: "Next due", value: formatDate(nextDue))
                    }

                    if let lastCompleted = task.lastCompleted {
                        detailRow(icon: "checkmark.circle", label: "Last completed", value: formatDate(lastCompleted))
                    }

                    if let day = task.assignedDay {
                        detailRow(icon: "calendar.badge.clock", label: "Assigned day", value: day)
                    }

                    if let season = task.season {
                        detailRow(icon: "leaf", label: "Season", value: season)
                    }
                }

                if let notes = task.notes, !notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                if let extendedNotes = task.extendedNotes, !extendedNotes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Details")
                            .font(.headline)
                        Text(extendedNotes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Actions
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await store.completeTask(
                                id: task.id,
                                completedBy: userStore.currentUser?.id
                            )
                            dismiss()
                        }
                    } label: {
                        Label("Mark Complete", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Menu {
                        ForEach(SnoozeDuration.allCases, id: \.rawValue) { duration in
                            Button(duration.label) {
                                Task {
                                    await store.snoozeTask(id: task.id, duration: duration)
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Label("Snooze", systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle(task.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            TaskFormSheet(
                store: store,
                userStore: userStore,
                isPresented: $showEditSheet,
                editingTask: task
            )
        }
        .alert("Delete Chore?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await store.deleteTask(id: task.id)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete \"\(task.name)\" and its completion history.")
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func statusBadge(_ status: TaskStatus) -> some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .overdue: .red
        case .today: .blue
        case .upcoming: .orange
        case .future: .gray
        case .adhoc: .purple
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
