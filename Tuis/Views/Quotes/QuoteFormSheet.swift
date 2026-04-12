import SwiftUI

struct QuoteFormSheet: View {
    @Bindable var store: QuoteStore
    var vendorStore: VendorStore
    @Binding var isPresented: Bool
    var editingQuote: Quote?

    @State private var description = ""
    @State private var vendorId: Int?
    @State private var total = ""
    @State private var labour = ""
    @State private var materials = ""
    @State private var other = ""
    @State private var status = "pending"
    @State private var receivedDate = Date()
    @State private var hasReceivedDate = true
    @State private var notes = ""
    @State private var isSaving = false

    private var isEditing: Bool { editingQuote != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quote") {
                    TextField("e.g. Bathroom renovation", text: $description)
                }

                Section("Vendor & Status") {
                    Picker("Vendor", selection: $vendorId) {
                        Text("None").tag(nil as Int?)
                        ForEach(vendorStore.vendors) { vendor in
                            Text(vendor.name).tag(vendor.id as Int?)
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(QuoteStatus.allCases, id: \.rawValue) { s in
                            Text(s.label).tag(s.rawValue)
                        }
                    }
                }

                Section("Amount") {
                    HStack {
                        Text("$")
                        TextField("Total", text: $total)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Cost Breakdown") {
                    HStack {
                        Text("Labour $")
                        TextField("0", text: $labour)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Materials $")
                        TextField("0", text: $materials)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Other $")
                        TextField("0", text: $other)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Date Received") {
                    Toggle("Set date", isOn: $hasReceivedDate)
                    if hasReceivedDate {
                        DatePicker("Received", selection: $receivedDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Quote" : "New Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        save()
                    }
                    .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty || total.isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if vendorStore.vendors.isEmpty {
                    Task { await vendorStore.loadVendors() }
                }
                if let quote = editingQuote {
                    description = quote.description
                    vendorId = quote.vendorId
                    total = String(format: "%g", quote.total)
                    labour = quote.labour.map { String(format: "%g", $0) } ?? ""
                    materials = quote.materials.map { String(format: "%g", $0) } ?? ""
                    other = quote.other.map { String(format: "%g", $0) } ?? ""
                    status = quote.status
                    notes = quote.notes ?? ""
                    if let dateStr = quote.receivedDate {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        if let date = formatter.date(from: dateStr) {
                            receivedDate = date
                            hasReceivedDate = true
                        }
                    }
                }
            }
        }
    }

    private func save() {
        let trimmed = description.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let totalVal = Double(total) else { return }

        isSaving = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        var body: [String: Any] = [
            "description": trimmed,
            "total": totalVal,
            "status": status,
        ]
        if let vendorId { body["vendorId"] = vendorId }
        if let labourVal = Double(labour) { body["labour"] = labourVal }
        if let materialsVal = Double(materials) { body["materials"] = materialsVal }
        if let otherVal = Double(other) { body["other"] = otherVal }
        if hasReceivedDate { body["receivedDate"] = formatter.string(from: receivedDate) }
        if !notes.isEmpty { body["notes"] = notes }

        Task {
            if let quote = editingQuote {
                let success = await store.updateQuote(id: quote.id, body: body)
                isSaving = false
                if success {
                    HapticManager.success()
                    isPresented = false
                } else {
                    HapticManager.error()
                }
            } else {
                let result = await store.createQuote(body: body)
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
