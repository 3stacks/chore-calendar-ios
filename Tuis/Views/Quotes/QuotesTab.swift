import SwiftUI

struct QuotesTab: View {
    @State private var quoteStore = QuoteStore()
    @State private var vendorStore = VendorStore()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            QuoteListView(store: quoteStore, vendorStore: vendorStore)
                .navigationTitle("Quotes")
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
                    QuoteFormSheet(
                        store: quoteStore,
                        vendorStore: vendorStore,
                        isPresented: $showingCreateSheet
                    )
                }
        }
    }
}

#Preview {
    QuotesTab()
}
