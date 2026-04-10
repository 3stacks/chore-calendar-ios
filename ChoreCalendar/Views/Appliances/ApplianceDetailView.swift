import SwiftUI

struct ApplianceDetailView: View {
    @Bindable var store: ApplianceStore
    let applianceId: Int

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    private var detail: ApplianceDetail? { store.currentDetail }

    var body: some View {
        Group {
            if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Info section
                        VStack(alignment: .leading, spacing: 12) {
                            if let brand = detail.brand {
                                detailRow(icon: "tag", label: "Brand", value: brand)
                            }
                            if let model = detail.model {
                                detailRow(icon: "number", label: "Model", value: model)
                            }
                            if let location = detail.location {
                                detailRow(icon: "mappin", label: "Location", value: location)
                            }
                            if let purchaseDate = detail.purchaseDate {
                                detailRow(icon: "calendar", label: "Purchased", value: formatDate(purchaseDate))
                            }
                            if let warrantyExpiry = detail.warrantyExpiry {
                                let isActive = {
                                    let f = DateFormatter()
                                    f.dateFormat = "yyyy-MM-dd"
                                    f.locale = Locale(identifier: "en_US_POSIX")
                                    return f.date(from: warrantyExpiry).map { $0 > Date() } ?? false
                                }()
                                HStack(spacing: 8) {
                                    Image(systemName: isActive ? "shield.checkered" : "shield.slash")
                                        .frame(width: 20)
                                        .foregroundStyle(isActive ? .green : .red)
                                    Text("Warranty")
                                        .foregroundStyle(.secondary)
                                    Text(isActive ? "Active until \(formatDate(warrantyExpiry))" : "Expired \(formatDate(warrantyExpiry))")
                                        .fontWeight(.medium)
                                        .foregroundStyle(isActive ? .green : .red)
                                }
                            }
                        }

                        if let notes = detail.notes, !notes.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Links
                        if detail.manualUrl != nil || detail.warrantyDocUrl != nil {
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Documents")
                                    .font(.headline)
                                if let manualUrl = detail.manualUrl, let url = URL(string: manualUrl) {
                                    Link(destination: url) {
                                        Label("Product Manual", systemImage: "doc.text")
                                    }
                                }
                                if let warrantyUrl = detail.warrantyDocUrl, let url = URL(string: warrantyUrl) {
                                    Link(destination: url) {
                                        Label("Warranty Document", systemImage: "doc.badge.gearshape")
                                    }
                                }
                            }
                        }

                        // Linked tasks
                        if let tasks = detail.tasks, !tasks.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Linked Chores")
                                    .font(.headline)
                                ForEach(tasks) { task in
                                    HStack {
                                        Image(systemName: "checklist")
                                            .foregroundStyle(.secondary)
                                        Text(task.name)
                                        Spacer()
                                        Text(task.area)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }

                        // Service history
                        if let history = detail.serviceHistory, !history.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Service History")
                                    .font(.headline)
                                ForEach(history) { record in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(record.taskName)
                                                .font(.body.weight(.medium))
                                            Text(formatDate(record.completedAt))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if let cost = record.cost {
                                            Text("$\(cost)")
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else if store.isLoadingDetail {
                ProgressView()
            } else {
                EmptyStateView(icon: "washer", title: "Appliance not found")
            }
        }
        .navigationTitle(detail?.name ?? "Appliance")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if detail != nil {
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
        }
        .sheet(isPresented: $showEditSheet) {
            if let detail {
                ApplianceFormSheet(store: store, isPresented: $showEditSheet, editingAppliance: detail)
            }
        }
        .alert("Delete Appliance?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await store.deleteAppliance(id: applianceId)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this appliance. Linked chores will be kept.")
        }
        .refreshable {
            await store.loadDetail(id: applianceId)
        }
        .task {
            await store.loadDetail(id: applianceId)
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

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: dateString) else {
            // Try ISO 8601 with time
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            guard let date = formatter.date(from: dateString) else { return dateString }
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: date)
        }
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
