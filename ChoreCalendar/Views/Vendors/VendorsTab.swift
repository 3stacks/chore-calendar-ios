import SwiftUI

struct VendorsTab: View {
    @State private var vendorStore = VendorStore()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            VendorListView(store: vendorStore)
                .navigationTitle("Vendors")
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
                    VendorFormSheet(store: vendorStore, isPresented: $showingCreateSheet)
                }
        }
    }
}

#Preview {
    VendorsTab()
}
