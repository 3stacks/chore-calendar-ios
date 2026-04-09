import SwiftUI

struct ShoppingTab: View {
    @State private var store = ShoppingStore()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            ShoppingListsView(store: store)
                .navigationTitle("Shopping")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingCreateSheet) {
                    ListFormSheet(store: store, isPresented: $showingCreateSheet)
                }
        }
    }
}

#Preview {
    ShoppingTab()
}
