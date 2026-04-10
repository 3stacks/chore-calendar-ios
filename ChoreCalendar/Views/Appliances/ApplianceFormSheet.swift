import SwiftUI

struct ApplianceFormSheet: View {
    @Bindable var store: ApplianceStore
    @Binding var isPresented: Bool
    var editingAppliance: ApplianceDetail?

    @State private var name = ""
    @State private var location = ""
    @State private var brand = ""
    @State private var model = ""
    @State private var purchaseDate = Date()
    @State private var hasPurchaseDate = false
    @State private var warrantyExpiry = Date()
    @State private var hasWarrantyExpiry = false
    @State private var manualUrl = ""
    @State private var warrantyDocUrl = ""
    @State private var notes = ""
    @State private var isSaving = false

    private var isEditing: Bool { editingAppliance != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appliance") {
                    TextField("Name", text: $name)
                }

                Section("Details") {
                    TextField("Brand (optional)", text: $brand)
                    TextField("Model (optional)", text: $model)
                    TextField("Location (optional)", text: $location)
                }

                Section("Dates") {
                    Toggle("Purchase date", isOn: $hasPurchaseDate)
                    if hasPurchaseDate {
                        DatePicker("Purchased", selection: $purchaseDate, displayedComponents: .date)
                    }

                    Toggle("Warranty expiry", isOn: $hasWarrantyExpiry)
                    if hasWarrantyExpiry {
                        DatePicker("Expires", selection: $warrantyExpiry, displayedComponents: .date)
                    }
                }

                Section("Documents") {
                    TextField("Manual URL (optional)", text: $manualUrl)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                    TextField("Warranty doc URL (optional)", text: $warrantyDocUrl)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Appliance" : "New Appliance")
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
                if let appliance = editingAppliance {
                    name = appliance.name
                    location = appliance.location ?? ""
                    brand = appliance.brand ?? ""
                    model = appliance.model ?? ""
                    manualUrl = appliance.manualUrl ?? ""
                    warrantyDocUrl = appliance.warrantyDocUrl ?? ""
                    notes = appliance.notes ?? ""

                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.locale = Locale(identifier: "en_US_POSIX")

                    if let pd = appliance.purchaseDate, let date = formatter.date(from: pd) {
                        purchaseDate = date
                        hasPurchaseDate = true
                    }
                    if let we = appliance.warrantyExpiry, let date = formatter.date(from: we) {
                        warrantyExpiry = date
                        hasWarrantyExpiry = true
                    }
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

        var body: [String: Any] = ["name": trimmed]
        if !location.isEmpty { body["location"] = location }
        if !brand.isEmpty { body["brand"] = brand }
        if !model.isEmpty { body["model"] = model }
        if hasPurchaseDate { body["purchaseDate"] = formatter.string(from: purchaseDate) }
        if hasWarrantyExpiry { body["warrantyExpiry"] = formatter.string(from: warrantyExpiry) }
        if !manualUrl.isEmpty { body["manualUrl"] = manualUrl }
        if !warrantyDocUrl.isEmpty { body["warrantyDocUrl"] = warrantyDocUrl }
        if !notes.isEmpty { body["notes"] = notes }

        Task {
            if let appliance = editingAppliance {
                let success = await store.updateAppliance(id: appliance.id, body: body)
                isSaving = false
                if success {
                    HapticManager.success()
                    isPresented = false
                } else {
                    HapticManager.error()
                }
            } else {
                let result = await store.createAppliance(body: body)
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
