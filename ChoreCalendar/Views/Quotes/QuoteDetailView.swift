import SwiftUI

struct QuoteDetailView: View {
    @Bindable var store: QuoteStore
    var vendorStore: VendorStore
    let quote: Quote

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status + vendor
                HStack {
                    statusBadge(quote.status)
                    if let vendor = quote.vendorName {
                        Label(vendor, systemImage: "wrench.and.screwdriver")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Total
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(quote.total))
                        .font(.system(size: 36, weight: .bold))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                // Cost breakdown
                if quote.labour != nil || quote.materials != nil || quote.other != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Breakdown")
                            .font(.headline)

                        HStack(spacing: 12) {
                            if let labour = quote.labour {
                                breakdownCard(label: "Labour", amount: labour, color: .blue)
                            }
                            if let materials = quote.materials {
                                breakdownCard(label: "Materials", amount: materials, color: .orange)
                            }
                            if let other = quote.other {
                                breakdownCard(label: "Other", amount: other, color: .gray)
                            }
                        }
                    }
                }

                // Date
                if let date = quote.receivedDate {
                    detailRow(icon: "calendar", label: "Received", value: formatDate(date))
                }

                // Notes
                if let notes = quote.notes, !notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Actions
                if quote.status == "pending" {
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await store.updateStatus(id: quote.id, status: "accepted")
                                dismiss()
                            }
                        } label: {
                            Label("Accept Quote", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button {
                            Task {
                                await store.updateStatus(id: quote.id, status: "rejected")
                                dismiss()
                            }
                        } label: {
                            Label("Reject Quote", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(quote.description)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    if quote.status != "archived" {
                        Button {
                            Task {
                                await store.updateStatus(id: quote.id, status: "archived")
                                dismiss()
                            }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
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
            QuoteFormSheet(
                store: store,
                vendorStore: vendorStore,
                isPresented: $showEditSheet,
                editingQuote: quote
            )
        }
        .alert("Delete Quote?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await store.deleteQuote(id: quote.id)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this quote.")
        }
    }

    // MARK: - Components

    private func breakdownCard(label: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(formatCurrency(amount))
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private func statusBadge(_ status: String) -> some View {
        let color: Color = switch status {
        case "pending": .orange
        case "accepted": .green
        case "rejected": .red
        default: .gray
        }
        return Text(status.prefix(1).uppercased() + status.dropFirst())
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
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
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}
