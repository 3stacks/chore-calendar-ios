import SwiftUI

struct WeekView: View {
    @Bindable var mealStore: MealPlanStore
    var recipeStore: RecipeStore

    @State private var pickerDate: Date?
    @State private var selectedMealDate: Date?

    var body: some View {
        VStack(spacing: 0) {
            weekNavigationHeader
                .padding(.horizontal)
                .padding(.vertical, 8)

            if mealStore.isLoading && mealStore.entries.isEmpty {
                Spacer()
                ProgressView("Loading meals...")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(mealStore.weekDates, id: \.self) { date in
                            MealDayCard(
                                date: date,
                                entry: mealStore.entry(for: date),
                                onAddMeal: {
                                    pickerDate = date
                                },
                                onTap: {
                                    if mealStore.entry(for: date) != nil {
                                        selectedMealDate = date
                                    }
                                },
                                onDelete: {
                                    let dateStr = DateHelpers.dateString(from: date)
                                    Task { await mealStore.deleteMeal(date: dateStr) }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await mealStore.loadCurrentWeek()
                }
            }
        }
        .navigationDestination(item: $selectedMealDate) { date in
            MealDetailView(
                date: date,
                entry: mealStore.entry(for: date),
                mealStore: mealStore
            )
        }
        .sheet(item: $pickerDate) { date in
            RecipePickerView(
                date: date,
                recipeStore: recipeStore,
                onSelect: { recipeId, multiplier in
                    let dateStr = DateHelpers.dateString(from: date)
                    Task {
                        await mealStore.upsertMeal(
                            date: dateStr,
                            recipeId: recipeId,
                            multiplier: multiplier
                        )
                    }
                    pickerDate = nil
                },
                onCustomMeal: { name, notes in
                    let dateStr = DateHelpers.dateString(from: date)
                    Task {
                        await mealStore.upsertMeal(
                            date: dateStr,
                            customMeal: name,
                            notes: notes
                        )
                    }
                    pickerDate = nil
                },
                onDismiss: { pickerDate = nil }
            )
        }
        .task {
            await mealStore.loadCurrentWeek()
        }
        .onChange(of: mealStore.weekStart) {
            Task { await mealStore.loadCurrentWeek() }
        }
        .animation(.easeInOut(duration: 0.2), value: mealStore.weekStart)
    }

    // MARK: - Week Navigation

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                HapticManager.light()
                mealStore.previousWeek()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(mealStore.weekLabel)
                    .font(.headline)

                if !mealStore.isCurrentWeek {
                    Button("Today") {
                        HapticManager.light()
                        mealStore.goToToday()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
                }
            }

            Spacer()

            Button {
                HapticManager.light()
                mealStore.nextWeek()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
            }
        }
    }
}

// MARK: - Make Date identifiable for sheet/navigationDestination

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
