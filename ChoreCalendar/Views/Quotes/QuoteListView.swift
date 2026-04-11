import SwiftUI

struct QuoteListView: View {
    @Bindable var store: QuoteStore
    var vendorStore: VendorStore

    var body: some View {
        Group {
            if store.quotes.isEmpty && !store.isLoading {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No quotes yet",
                    subtitle: "Track vendor quotes for home maintenance"
                )
            } else {
                List {
                    // Budget card
                    if let budget = store.budget, budget.found {
                        BudgetSection(budget: budget, pendingTotal: store.pendingTotal)
                    }

                    // Status filter
                    statusFilterSection

                    // Quotes
                    ForEach(store.filteredQuotes) { quote in
                        NavigationLink(value: quote) {
                            QuoteRow(quote: quote)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await store.deleteQuote(id: quote.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            if quote.status == "pending" {
                                Button {
                                    Task { await store.updateStatus(id: quote.id, status: "accepted") }
                                } label: {
                                    Label("Accept", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationDestination(for: Quote.self) { quote in
            QuoteDetailView(store: store, vendorStore: vendorStore, quote: quote)
        }
        .refreshable {
            await store.loadQuotes()
            await store.loadBudget()
        }
        .task {
            if store.quotes.isEmpty {
                await store.loadQuotes()
            }
            if store.budget == nil {
                await store.loadBudget()
            }
        }
    }

    // MARK: - Status Filter

    @ViewBuilder
    private var statusFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "All", isSelected: store.filterStatus == nil) {
                    store.filterStatus = nil
                }
                ForEach(QuoteStatus.allCases, id: \.rawValue) { status in
                    FilterPill(label: status.label, isSelected: store.filterStatus == status.rawValue) {
                        store.filterStatus = status.rawValue
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
    }
}

// MARK: - Budget Section

private struct BudgetSection: View {
    let budget: BudgetInfo
    let pendingTotal: Double

    private var isOverBudget: Bool { budget.remaining < 0 }
    private var afterQuotes: Double { budget.remaining - pendingTotal }

    var body: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.categoryName ?? "Home Maintenance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(budget.remaining))
                        .font(.title.weight(.bold))
                        .foregroundStyle(isOverBudget ? .red : .green)
                }

                Spacer()

                if pendingTotal > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("After pending")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(afterQuotes))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(afterQuotes < 0 ? .red : .green)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AUD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0"
    }
}

// MARK: - Quote Row

private struct QuoteRow: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(quote.description)
                    .font(.body.weight(.medium))
                Spacer()
                Text(formatCurrency(quote.total))
                    .font(.body.weight(.semibold))
            }

            HStack(spacing: 8) {
                StatusBadge(status: quote.status)

                if let vendor = quote.vendorName {
                    Label(vendor, systemImage: "wrench.and.screwdriver")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let date = quote.receivedDate {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if quote.labour != nil || quote.materials != nil {
                HStack(spacing: 8) {
                    if let labour = quote.labour {
                        Text("L: \(formatCurrency(labour))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let materials = quote.materials {
                        Text("M: \(formatCurrency(materials))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let other = quote.other {
                        Text("O: \(formatCurrency(other))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AUD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status {
        case "pending": .orange
        case "accepted": .green
        case "rejected": .red
        case "archived": .gray
        default: .gray
        }
    }

    var body: some View {
        Text(status.prefix(1).uppercased() + status.dropFirst())
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
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
