import SwiftUI

struct VendorFormSheet: View {
    @Bindable var store: VendorStore
    @Binding var isPresented: Bool
    var editingVendor: VendorDetail?

    @State private var name = ""
    @State private var category = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var website = ""
    @State private var notes = ""
    @State private var rating: Int = 0
    @State private var isSaving = false

    private var isEditing: Bool { editingVendor != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vendor") {
                    TextField("Name", text: $name)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        Text("None").tag("")
                        ForEach(VendorCategory.allCases, id: \.rawValue) { cat in
                            Text(cat.rawValue).tag(cat.rawValue)
                        }
                    }
                }

                Section("Contact") {
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Website (optional)", text: $website)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                }

                Section("Rating") {
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                rating = rating == star ? 0 : star
                                HapticManager.selection()
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Vendor" : "New Vendor")
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
                if let vendor = editingVendor {
                    name = vendor.name
                    category = vendor.category ?? ""
                    phone = vendor.phone ?? ""
                    email = vendor.email ?? ""
                    website = vendor.website ?? ""
                    notes = vendor.notes ?? ""
                    rating = vendor.rating ?? 0
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSaving = true

        var body: [String: Any] = ["name": trimmed]
        if !category.isEmpty { body["category"] = category }
        if !phone.isEmpty { body["phone"] = phone }
        if !email.isEmpty { body["email"] = email }
        if !website.isEmpty { body["website"] = website }
        if !notes.isEmpty { body["notes"] = notes }
        if rating > 0 { body["rating"] = rating }

        Task {
            if let vendor = editingVendor {
                let success = await store.updateVendor(id: vendor.id, body: body)
                isSaving = false
                if success {
                    HapticManager.success()
                    isPresented = false
                } else {
                    HapticManager.error()
                }
            } else {
                let result = await store.createVendor(body: body)
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
