import SwiftUI

struct FoodEntryListView: View {
    @Environment(APIClient.self) private var api
    @State private var model: FoodEntryModel?
    @State private var isPresentingAddEntry = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Food")
            .toolbar {
                if !Calendar.current.isDateInToday(selectedDate) {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Today") {
                            selectedDate = Calendar.current.startOfDay(for: Date())
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddEntry) {
                if let model {
                    AddFoodEntryView(model: model, initialDate: dateForNewEntry)
                }
            }
            .task {
                if model == nil {
                    model = FoodEntryModel(api: api)
                }
                await model?.load()
            }
            .refreshable {
                await model?.load()
            }
        }
    }

    /// Backfilling a past day should default the new entry to that day, not "now" —
    /// but keep "now" (down to the minute) when the selected day is today, since that's
    /// almost always what's meant by "log this."
    private var dateForNewEntry: Date {
        if Calendar.current.isDateInToday(selectedDate) {
            return Date()
        }
        return Calendar.current.date(
            bySettingHour: 12, minute: 0, second: 0, of: selectedDate
        ) ?? selectedDate
    }

    @ViewBuilder
    private func content(for model: FoodEntryModel) -> some View {
        if model.isLoading && model.entries.isEmpty {
            ProgressView()
        } else if model.entries.isEmpty {
            ContentUnavailableView {
                Label("No food entries yet", systemImage: "fork.knife")
            } description: {
                Text("Tap + to log something you ate.")
            }
        } else {
            let dayEntries = entries(model.entries, onSameDayAs: selectedDate)
            List {
                Section {
                    // One List row containing all three, with explicit Dividers, rather
                    // than three separate rows — List's automatic separator insets came
                    // out inconsistent (only partially spanning) once the day selector's
                    // buttons were in the mix.
                    VStack(spacing: 10) {
                        DaySelectorRow(selectedDate: $selectedDate)
                        Divider()
                        TotalsRow(
                            label: "Day",
                            entries: dayEntries,
                            targetCalories: model.targetCalories,
                            targetProteinG: model.targetProteinG
                        )
                        Divider()
                        TotalsRow(
                            label: "Week",
                            entries: weekEntries(model.entries, containing: selectedDate),
                            targetCalories: model.targetCalories.map { $0 * 7 },
                            targetProteinG: model.targetProteinG.map { $0 * 7 }
                        )
                    }
                }
                Section {
                    if dayEntries.isEmpty {
                        Text("Nothing logged on this day.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(dayEntries) { entry in
                            FoodEntryRow(entry: entry)
                        }
                        .onDelete { offsets in
                            Task { await model.delete(at: offsets, in: dayEntries) }
                        }
                    }
                }
            }
        }
    }

    private func entries(_ entries: [FoodEntry], onSameDayAs date: Date) -> [FoodEntry] {
        entries.filter { Calendar.current.isDate($0.consumedAt, inSameDayAs: date) }
    }

    private func weekEntries(_ entries: [FoodEntry], containing date: Date) -> [FoodEntry] {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return entries.filter { week.contains($0.consumedAt) }
    }
}

private struct DaySelectorRow: View {
    @Binding var selectedDate: Date

    private var calendar: Calendar { .current }
    private var isToday: Bool { calendar.isDateInToday(selectedDate) }

    /// Always includes the weekday, even for Today/Yesterday, so paging
    /// back through past days doesn't require doing the day-of-week math
    /// in your head.
    private var label: String {
        let weekday = selectedDate.formatted(.dateTime.weekday(.abbreviated))
        if isToday { return "Today · \(weekday)" }
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday · \(weekday)" }
        let date = selectedDate.formatted(date: .abbreviated, time: .omitted)
        return "\(weekday), \(date)"
    }

    var body: some View {
        HStack {
            Button {
                shift(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            Spacer()
            Text(label)
                .font(.headline)
            Spacer()
            Button {
                shift(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(isToday)
        }
        .buttonStyle(.borderless)
    }

    private func shift(by days: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else { return }
        selectedDate = min(newDate, calendar.startOfDay(for: Date()))
    }
}

private struct TotalsRow: View {
    let label: String
    let entries: [FoodEntry]
    let targetCalories: Int?
    let targetProteinG: Int?

    private var totalKcal: Decimal {
        entries.reduce(0) { $0 + ($1.kcal ?? 0) }
    }

    private var totalProteinG: Decimal {
        entries.reduce(0) { $0 + ($1.proteinG ?? 0) }
    }

    /// Unclamped ratio (can exceed 1) — the bar itself clamps its fill
    /// width, but color needs to know whether target was actually exceeded.
    private var kcalProgress: Double? {
        guard let targetCalories, targetCalories > 0 else { return nil }
        return Double(truncating: totalKcal as NSNumber) / Double(targetCalories)
    }

    private var proteinProgress: Double? {
        guard let targetProteinG, targetProteinG > 0 else { return nil }
        return Double(truncating: totalProteinG as NSNumber) / Double(targetProteinG)
    }

    /// The goal is to land at or under the calorie target — under/at is
    /// fine, over is the thing to avoid.
    private var kcalColor: Color {
        guard let targetCalories, targetCalories > 0 else { return .accentColor }
        if totalKcal > Decimal(targetCalories) { return .red }
        if totalKcal == Decimal(targetCalories) { return .green }
        return .accentColor
    }

    /// Protein is the opposite: the goal is to land at or over the target.
    private var proteinColor: Color {
        guard let targetProteinG, targetProteinG > 0 else { return .orange }
        return totalProteinG >= Decimal(targetProteinG) ? .green : .orange
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(kcalText)
                        .font(.headline)
                }
                Spacer()
                Text(proteinText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let kcalProgress {
                ThickProgressBar(progress: kcalProgress, color: kcalColor)
            }
            if let proteinProgress {
                ThickProgressBar(progress: proteinProgress, color: proteinColor)
            }
        }
        .padding(.vertical, 2)
    }

    private var kcalText: String {
        let total = totalKcal.formatted(.number.precision(.fractionLength(0)))
        guard let targetCalories else { return "\(total) kcal" }
        return "\(total) / \(targetCalories) kcal"
    }

    private var proteinText: String {
        let total = totalProteinG.formatted(.number.precision(.fractionLength(0)))
        guard let targetProteinG else { return "\(total)g protein" }
        return "\(total) / \(targetProteinG)g protein"
    }
}

/// A `ProgressView(.linear)` renders too thin to read at a glance and
/// offers no way to thicken it — this draws the fill directly so height
/// and color are both under our control. `progress` is unclamped (can
/// exceed 1); only the visual fill width clamps at the full bar.
private struct ThickProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 10)
    }
}

private struct FoodEntryRow: View {
    let entry: FoodEntry

    /// "45p · 12c · 6f" — only the macros that are actually set, in that order. `nil`
    /// when none are set (e.g. a quick no-macro log), so the row doesn't show a stray line.
    private var macroSummary: String? {
        let parts = [
            entry.proteinG.map { "\($0.formatted(.number.precision(.fractionLength(0))))p" },
            entry.carbsG.map { "\($0.formatted(.number.precision(.fractionLength(0))))c" },
            entry.fatG.map { "\($0.formatted(.number.precision(.fractionLength(0))))f" },
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(entry.consumedAt.formatted(date: .omitted, time: .shortened))
                    if let mealSlot = entry.mealSlot {
                        Text("·")
                        Text(mealSlot.capitalized)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let kcal = entry.kcal {
                    Text("\(kcal, format: .number.precision(.fractionLength(0))) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let macroSummary {
                    Text(macroSummary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FoodEntryListView()
        .environment(APIClient())
}
