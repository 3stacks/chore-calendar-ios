import SwiftUI

struct AppliancesTab: View {
    @State private var applianceStore = ApplianceStore()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            ApplianceListView(store: applianceStore)
                .navigationTitle("Appliances")
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
                    ApplianceFormSheet(store: applianceStore, isPresented: $showingCreateSheet)
                }
        }
    }
}

#Preview {
    AppliancesTab()
}
