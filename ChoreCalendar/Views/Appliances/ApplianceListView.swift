import SwiftUI

struct ApplianceListView: View {
    @Bindable var store: ApplianceStore

    var body: some View {
        Group {
            if store.appliances.isEmpty && !store.isLoading {
                EmptyStateView(
                    icon: "washer",
                    title: "No appliances yet",
                    subtitle: "Track your appliances and warranties"
                )
            } else {
                List {
                    ForEach(store.filteredAppliances) { appliance in
                        NavigationLink(value: appliance) {
                            ApplianceRow(appliance: appliance)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await store.deleteAppliance(id: appliance.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $store.searchQuery, prompt: "Search appliances")
        .navigationDestination(for: Appliance.self) { appliance in
            ApplianceDetailView(store: store, applianceId: appliance.id)
        }
        .refreshable {
            await store.loadAppliances()
        }
        .task {
            if store.appliances.isEmpty {
                await store.loadAppliances()
            }
        }
    }
}

// MARK: - Appliance Row

private struct ApplianceRow: View {
    let appliance: Appliance

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appliance.name)
                .font(.body.weight(.medium))

            HStack(spacing: 8) {
                if let brand = appliance.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let model = appliance.model {
                    Text(model)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                if let location = appliance.location {
                    Label(location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if appliance.warrantyExpiry != nil {
                    if appliance.isWarrantyActive {
                        Label("Warranty active", systemImage: "shield.checkered")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Label("Warranty expired", systemImage: "shield.slash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}
