import SwiftUI

struct VendorListView: View {
    @Bindable var store: VendorStore

    var body: some View {
        Group {
            if store.vendors.isEmpty && !store.isLoading {
                EmptyStateView(
                    icon: "person.crop.rectangle.stack",
                    title: "No vendors yet",
                    subtitle: "Keep track of your service providers"
                )
            } else {
                List {
                    if !store.vendors.isEmpty {
                        categoryFilterSection
                    }

                    ForEach(store.filteredVendors) { vendor in
                        NavigationLink(value: vendor) {
                            VendorRow(vendor: vendor)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await store.deleteVendor(id: vendor.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $store.searchQuery, prompt: "Search vendors")
        .navigationDestination(for: Vendor.self) { vendor in
            VendorDetailView(store: store, vendorId: vendor.id)
        }
        .refreshable {
            await store.loadVendors()
        }
        .task {
            if store.vendors.isEmpty {
                await store.loadVendors()
            }
        }
    }

    @ViewBuilder
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChipView(
                    label: "All",
                    isSelected: store.filterCategory == nil
                ) {
                    store.filterCategory = nil
                }

                ForEach(VendorCategory.allCases, id: \.rawValue) { cat in
                    FilterChipView(
                        label: cat.rawValue,
                        isSelected: store.filterCategory == cat.rawValue
                    ) {
                        store.filterCategory = cat.rawValue
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
    }
}

// MARK: - Vendor Row

private struct VendorRow: View {
    let vendor: Vendor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vendor.name)
                .font(.body.weight(.medium))

            HStack(spacing: 8) {
                if let category = vendor.category {
                    Label(category, systemImage: categoryIcon(category))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let rating = vendor.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                if let phone = vendor.phone {
                    Label(phone, systemImage: "phone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
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
}

// MARK: - Filter Chip (local, matches TaskListView pattern)

private struct FilterChipView: View {
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
