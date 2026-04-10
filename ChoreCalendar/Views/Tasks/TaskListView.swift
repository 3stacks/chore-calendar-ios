import SwiftUI

struct TaskListView: View {
    @Bindable var store: TaskStore
    var userStore: UserStore

    var body: some View {
        Group {
            if store.tasks.isEmpty && !store.isLoading {
                EmptyStateView(
                    icon: "checklist",
                    title: "No chores yet",
                    subtitle: "Add chores to keep your home in order"
                )
            } else {
                List {
                    filterSection

                    ForEach(store.tasksByStatus, id: \.status) { group in
                        Section {
                            ForEach(group.tasks) { task in
                                NavigationLink(value: task) {
                                    TaskRow(task: task, users: userStore.users)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        Task {
                                            await store.completeTask(
                                                id: task.id,
                                                completedBy: userStore.currentUser?.id
                                            )
                                        }
                                    } label: {
                                        Label("Done", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task { await store.deleteTask(id: task.id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(statusColor(group.status))
                                    .frame(width: 8, height: 8)
                                Text("\(group.status.label) (\(group.tasks.count))")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $store.searchQuery, prompt: "Search chores")
        .navigationDestination(for: ChoreTask.self) { task in
            TaskDetailView(store: store, userStore: userStore, task: task)
        }
        .refreshable {
            await store.loadTasks()
        }
        .task {
            if store.tasks.isEmpty {
                await store.loadTasks()
            }
            if userStore.users.isEmpty {
                await userStore.loadUsers()
            }
        }
    }

    // MARK: - Filter Section

    @ViewBuilder
    private var filterSection: some View {
        if !store.areas.isEmpty {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: "All Areas",
                            isSelected: store.filterArea == nil
                        ) {
                            store.filterArea = nil
                        }

                        ForEach(store.areas, id: \.self) { area in
                            FilterChip(
                                label: area,
                                isSelected: store.filterArea == area
                            ) {
                                store.filterArea = area
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: "All Frequencies",
                            isSelected: store.filterFrequency == nil
                        ) {
                            store.filterFrequency = nil
                        }

                        ForEach(TaskFrequency.allCases, id: \.rawValue) { freq in
                            FilterChip(
                                label: freq.label,
                                isSelected: store.filterFrequency == freq.rawValue
                            ) {
                                store.filterFrequency = freq.rawValue
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
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
}

// MARK: - Task Row

private struct TaskRow: View {
    let task: ChoreTask
    let users: [User]

    private var assignedUser: User? {
        guard let assignedTo = task.assignedTo else { return nil }
        return users.first { $0.id == assignedTo }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.name)
                .font(.body.weight(.medium))

            HStack(spacing: 8) {
                Label(task.area, systemImage: "house")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(TaskFrequency(rawValue: task.frequency)?.label ?? task.frequency)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let user = assignedUser {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color(hex: user.color))
                            .frame(width: 8, height: 8)
                        Text(user.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let nextDue = task.nextDue {
                Text("Due: \(formatDate(nextDue))")
                    .font(.caption2)
                    .foregroundStyle(task.status == .overdue ? .red : .secondary)
            }
        }
        .padding(.vertical, 2)
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

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.blue : Color(.systemGray5),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
