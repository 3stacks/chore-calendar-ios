import SwiftUI

struct VendorDetailView: View {
    @Bindable var store: VendorStore
    let vendorId: Int

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    private var detail: VendorDetail? { store.currentDetail }

    var body: some View {
        Group {
            if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Info
                        VStack(alignment: .leading, spacing: 12) {
                            if let category = detail.category {
                                detailRow(icon: categoryIcon(category), label: "Category", value: category)
                            }

                            if let rating = detail.rating {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .frame(width: 20)
                                        .foregroundStyle(.secondary)
                                    Text("Rating")
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 2) {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= rating ? "star.fill" : "star")
                                                .font(.body)
                                                .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
                                        }
                                    }
                                }
                            }
                        }

                        // Contact
                        if detail.phone != nil || detail.email != nil || detail.website != nil {
                            Divider()
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Contact")
                                    .font(.headline)

                                if let phone = detail.phone, let url = URL(string: "tel:\(phone)") {
                                    Link(destination: url) {
                                        Label(phone, systemImage: "phone")
                                    }
                                }

                                if let email = detail.email, let url = URL(string: "mailto:\(email)") {
                                    Link(destination: url) {
                                        Label(email, systemImage: "envelope")
                                    }
                                }

                                if let website = detail.website, let url = URL(string: website) {
                                    Link(destination: url) {
                                        Label("Website", systemImage: "globe")
                                    }
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

                        // Job history
                        if let history = detail.jobHistory, !history.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Job History")
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
                EmptyStateView(icon: "person.crop.rectangle.stack", title: "Vendor not found")
            }
        }
        .navigationTitle(detail?.name ?? "Vendor")
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
                VendorFormSheet(store: store, isPresented: $showEditSheet, editingVendor: detail)
            }
        }
        .alert("Delete Vendor?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await store.deleteVendor(id: vendorId)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this vendor.")
        }
        .refreshable {
            await store.loadDetail(id: vendorId)
        }
        .task {
            await store.loadDetail(id: vendorId)
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

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Plumber": "wrench.and.screwdriver"
        case "Electrician": "bolt"
        case "HVAC": "thermometer"
        case "Appliance Repair": "washer"
        case "Landscaping": "leaf"
        case "Cleaning": "sparkles"
        default: "person.crop.rectangle"
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: dateString) else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            guard let date = formatter.date(from: dateString) else { return dateString }
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: date)
        }
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
