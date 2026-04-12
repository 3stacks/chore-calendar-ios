import SwiftUI

struct ListFormSheet: View {
    @Bindable var store: ShoppingStore
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var selectedColor = ListFormSheet.presetColors[0]
    @State private var isCreating = false

    static let presetColors: [String] = [
        "#4F46E5", // Indigo
        "#2563EB", // Blue
        "#0891B2", // Cyan
        "#059669", // Emerald
        "#16A34A", // Green
        "#CA8A04", // Yellow
        "#EA580C", // Orange
        "#DC2626", // Red
        "#DB2777", // Pink
        "#9333EA", // Purple
        "#6D28D9", // Violet
        "#475569", // Slate
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        NavigationStack {
            Form {
                Section("List Name") {
                    TextField("e.g. Weekly Groceries", text: $name)
                        .submitLabel(.done)
                }

                Section("Color") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Self.presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if selectedColor == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = hex
                                    HapticManager.selection()
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createList()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func createList() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isCreating = true
        Task {
            let result = await store.createList(name: trimmed, color: selectedColor)
            isCreating = false
            if result != nil {
                HapticManager.success()
                isPresented = false
            } else {
                HapticManager.error()
            }
        }
    }
}

#Preview {
    ListFormSheet(store: ShoppingStore(), isPresented: .constant(true))
}
