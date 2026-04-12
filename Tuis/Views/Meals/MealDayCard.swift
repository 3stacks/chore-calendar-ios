import SwiftUI

struct MealDayCard: View {
    let date: Date
    let entry: MealPlanEntry?
    let onAddMeal: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showDeleteButton = false

    private var isToday: Bool { DateHelpers.isToday(date) }
    private var dayName: String { DateHelpers.displayDayString(from: date) }
    private var dateLabel: String { DateHelpers.displayDateString(from: date) }

    var body: some View {
        if let entry {
            filledCard(entry)
        } else {
            emptyCard
        }
    }

    // MARK: - Filled Card

    private func filledCard(_ entry: MealPlanEntry) -> some View {
        ZStack(alignment: .trailing) {
            // Delete background
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        offset = 0
                        showDeleteButton = false
                    }
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 60)
            }
            .frame(maxHeight: .infinity)
            .background(Color.red, in: RoundedRectangle(cornerRadius: 12))
            .opacity(showDeleteButton ? 1 : 0)

            // Main card content
            HStack(spacing: 12) {
                dayColumn

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(entry.displayName)
                            .font(.body.weight(.medium))
                            .lineLimit(1)

                        if let mult = entry.servingsMultiplier, mult != 1.0 {
                            Text(formatMultiplier(mult))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.12), in: Capsule())
                        }
                    }

                    if let totalTime = entry.totalTime {
                        Label("\(totalTime) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToday ? Color.blue : Color(.systemGray4), lineWidth: isToday ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        } else if showDeleteButton {
                            offset = min(0, -60 + value.translation.width)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeOut(duration: 0.2)) {
                            if value.translation.width < -40 {
                                offset = -60
                                showDeleteButton = true
                            } else {
                                offset = 0
                                showDeleteButton = false
                            }
                        }
                    }
            )
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove Meal", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty Card

    private var emptyCard: some View {
        HStack(spacing: 12) {
            dayColumn

            Button {
                HapticManager.light()
                onAddMeal()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.body)
                    Text("Add Meal")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isToday ? Color.blue : Color(.systemGray4),
                    style: StrokeStyle(lineWidth: isToday ? 2 : 1, dash: [6, 4])
                )
        )
    }

    // MARK: - Day Column

    private var dayColumn: some View {
        VStack(spacing: 2) {
            Text(dayName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(dateLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isToday ? .blue : .primary)
        }
        .frame(width: 44)
    }

    // MARK: - Helpers

    private func formatMultiplier(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return "\(Int(value))x"
        }
        return String(format: "%.1fx", value)
    }
}
