import SwiftUI

struct TasksTab: View {
    @State private var taskStore = TaskStore()
    @State private var userStore = UserStore()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            TaskListView(store: taskStore, userStore: userStore)
                .navigationTitle("Chores")
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
                    TaskFormSheet(store: taskStore, userStore: userStore, isPresented: $showingCreateSheet)
                }
        }
    }
}

#Preview {
    TasksTab()
}
