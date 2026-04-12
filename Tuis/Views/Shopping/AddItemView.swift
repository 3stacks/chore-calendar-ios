import SwiftUI

struct AddItemView: View {
    @Bindable var store: ShoppingStore
    @State private var itemName = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField("Add item...", text: $itemName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit { submitItem() }
                    .onChange(of: itemName) { _, newValue in
                        store.updateSuggestions(query: newValue)
                    }

                Button {
                    submitItem()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Suggestions
            if !store.suggestions.isEmpty && !itemName.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.suggestions, id: \.self) { suggestion in
                            Button {
                                itemName = suggestion
                                submitItem()
                            } label: {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.fill.tertiary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.suggestions)
    }

    private func submitItem() {
        let name = itemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let captured = name
        itemName = ""
        store.clearSuggestions()
        HapticManager.light()

        Task {
            await store.addItem(name: captured)
        }

        // Keep focus for rapid-fire entry
        isFocused = true
    }
}
