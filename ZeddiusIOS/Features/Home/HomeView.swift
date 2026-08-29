import SwiftUI

struct HomeView: View {
    @Environment(APIClient.self) private var api
    @State private var model: HomeModel?
    @State private var isPresentingManageTasks = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var tomorrowFocusText = ""
    @State private var isClosingDay = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Home")
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
                        isPresentingManageTasks = true
                    } label: {
                        Image(systemName: "checklist")
                    }
                }
            }
            .sheet(isPresented: $isPresentingManageTasks) {
                TaskListView()
            }
            .task {
                if model == nil {
                    model = HomeModel(api: api)
                }
                await model?.load()
                syncTomorrowFocusText()
            }
            .refreshable {
                await model?.load()
                syncTomorrowFocusText()
            }
            .onChange(of: selectedDate) {
                syncTomorrowFocusText()
            }
            .dismissKeyboardOnScroll()
        }
    }

    private func syncTomorrowFocusText() {
        tomorrowFocusText = model?.checkin(for: selectedDate)?.tomorrowFocus ?? ""
    }

    @ViewBuilder
    private func content(for model: HomeModel) -> some View {
        if model.isLoading && !model.hasLoadedOnce {
            ProgressView()
        } else {
            List {
                Section {
                    DaySelectorRow(selectedDate: $selectedDate)
                }

                if let focus = model.focusSetForDay(selectedDate), !focus.isEmpty {
                    Section("Today's focus") {
                        Text(focus)
                    }
                }

                dailyGoalsSection(for: model)
                thisWeekSection(for: model)
                tasksSection(for: model)
                closeDaySection(for: model)

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Daily goals

    @ViewBuilder
    private func dailyGoalsSection(for model: HomeModel) -> some View {
        let isClosed = model.checkin(for: selectedDate)?.closedAt != nil

        Section("Daily goals") {
            if let target = model.user?.targetCalories {
                // Being under target so far is never a false positive to
                // avoid — going over is a real, permanent violation the
                // moment it happens, so that shows red immediately. But
                // "under so far" isn't the same as "stayed under" until the
                // day is actually done — it can still tip over later — so
                // it only turns green once Close Day confirms nothing more
                // is coming. Before that it's neutral, not a checkmark.
                let kcal = model.kcal(on: selectedDate)
                let isOver = kcal > Decimal(target)
                let symbolName = isOver ? "xmark.circle.fill" : (isClosed ? "checkmark.circle.fill" : "circle")
                let symbolColor: Color = isOver ? .red : (isClosed ? .green : .secondary)
                GoalRow(
                    label: "Calories",
                    detail: "\(kcal.formatted(.number.precision(.fractionLength(0)))) / \(target) kcal",
                    symbolName: symbolName,
                    symbolColor: symbolColor
                )
            }
            if let target = model.user?.targetProteinG {
                let proteinG = model.proteinG(on: selectedDate)
                let isMet = proteinG >= Decimal(target)
                let resolved = Self.resolvedSymbol(isMet: isMet, isClosed: isClosed)
                GoalRow(
                    label: "Protein",
                    detail: "\(proteinG.formatted(.number.precision(.fractionLength(0)))) / \(target)g",
                    symbolName: resolved.name,
                    symbolColor: resolved.color
                )
            }
            let weightResolved = Self.resolvedSymbol(isMet: model.weightLogged(on: selectedDate), isClosed: isClosed)
            GoalRow(
                label: "Weight logged",
                detail: nil,
                symbolName: weightResolved.name,
                symbolColor: weightResolved.color
            )
            let sleepResolved = Self.resolvedSymbol(isMet: model.sleepLogged(on: selectedDate), isClosed: isClosed)
            GoalRow(
                label: "Sleep logged",
                detail: nil,
                symbolName: sleepResolved.name,
                symbolColor: sleepResolved.color
            )
            if let target = model.user?.targetWakeTime {
                let met = model.wakeTimeMet(on: selectedDate) ?? false
                let resolved = Self.resolvedSymbol(isMet: met, isClosed: isClosed)
                GoalRow(
                    label: "Wake by \(target.formatted(date: .omitted, time: .shortened))",
                    detail: model.sleepLog(on: selectedDate).map { "Woke at \($0.wakeTime.formatted(date: .omitted, time: .shortened))" },
                    symbolName: resolved.name,
                    symbolColor: resolved.color
                )
            }
            if let target = model.user?.targetBedTime {
                if Calendar.current.isDateInToday(selectedDate) {
                    // Not a pass/fail check: tonight hasn't happened yet, so
                    // this is a plain forward reminder, not a checkmark —
                    // closing today early doesn't make it judgeable, since
                    // the event it judges genuinely hasn't occurred yet.
                    GoalRow(
                        label: "Bed by \(target.formatted(date: .omitted, time: .shortened)) tonight",
                        detail: nil,
                        symbolName: "moon.zzz",
                        symbolColor: .secondary
                    )
                } else {
                    // A past day's bedtime already happened, so it can
                    // actually be judged — the log for that night lives on
                    // the *next* day's sleep entry (its wake time is the
                    // following morning).
                    let met = model.bedTimeMet(forNightOf: selectedDate) ?? false
                    let resolved = Self.resolvedSymbol(isMet: met, isClosed: isClosed)
                    GoalRow(
                        label: "Bed by \(target.formatted(date: .omitted, time: .shortened))",
                        detail: model.sleepLog(forNightOf: selectedDate).map {
                            "Went to bed at \($0.bedTime.formatted(date: .omitted, time: .shortened))"
                        },
                        symbolName: resolved.name,
                        symbolColor: resolved.color
                    )
                }
            }
        }
    }

    /// Shared resolution for every daily-goal row except calories (which has
    /// its own immediate-violation case — going over is real the instant it
    /// happens, independent of Close Day). For everything else, "not done
    /// yet" only becomes a real miss once Close Day confirms nothing more is
    /// coming: closing signals "I'm done for today," so anything still
    /// unmet at that point resolves to red instead of staying neutral.
    private static func resolvedSymbol(isMet: Bool, isClosed: Bool) -> (name: String, color: Color) {
        if isMet { return ("checkmark.circle.fill", .green) }
        if isClosed { return ("xmark.circle.fill", .red) }
        return ("circle", .secondary)
    }

    // MARK: - This week

    @ViewBuilder
    private func thisWeekSection(for model: HomeModel) -> some View {
        if model.user?.targetWeeklyRuns != nil || model.user?.targetWeeklyLifts != nil {
            Section("This week") {
                if let target = model.user?.targetWeeklyRuns {
                    ProgressRow(label: "Runs", count: model.weeklyRunCount(containing: selectedDate), target: target)
                }
                if let target = model.user?.targetWeeklyLifts {
                    ProgressRow(label: "Lifts", count: model.weeklyLiftCount(containing: selectedDate), target: target)
                }
            }
        }
    }

    // MARK: - Tasks

    @ViewBuilder
    private func tasksSection(for model: HomeModel) -> some View {
        if !model.tasks.isEmpty {
            let isClosed = model.checkin(for: selectedDate)?.closedAt != nil
            Section("Tasks") {
                ForEach(model.tasks) { task in
                    TaskToggleRow(task: task, date: selectedDate, model: model, isDayClosed: isClosed)
                }
            }
        }
    }

    // MARK: - Close Day

    @ViewBuilder
    private func closeDaySection(for model: HomeModel) -> some View {
        Section("Close Day") {
            TextField("Tomorrow's one important task", text: $tomorrowFocusText, axis: .vertical)

            if let closedAt = model.checkin(for: selectedDate)?.closedAt {
                Label(
                    "Closed at \(closedAt.formatted(date: .omitted, time: .shortened))",
                    systemImage: "checkmark.seal.fill"
                )
                .foregroundStyle(.green)

                HStack {
                    Spacer()
                    Button {
                        Task { await reopenDay(model) }
                    } label: {
                        if isClosingDay {
                            ProgressView()
                        } else {
                            Text("Reopen Day")
                        }
                    }
                    .disabled(isClosingDay)
                }
            } else {
                HStack {
                    Spacer()
                    Button {
                        Task { await closeDay(model) }
                    } label: {
                        if isClosingDay {
                            ProgressView()
                        } else {
                            Text("Close Day")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isClosingDay)
                }
            }
        }
    }

    /// Saving the focus text as part of closing means there's no separate
    /// step to remember — "close out the day" and "set tomorrow's focus"
    /// happen together, matching how Joshua described the nightly ritual.
    private func closeDay(_ model: HomeModel) async {
        isClosingDay = true
        _ = await model.saveTomorrowFocus(tomorrowFocusText.isEmpty ? nil : tomorrowFocusText, for: selectedDate)
        _ = await model.closeDay(selectedDate)
        isClosingDay = false
    }

    private func reopenDay(_ model: HomeModel) async {
        isClosingDay = true
        _ = await model.reopenDay(selectedDate)
        isClosingDay = false
    }
}

/// Same weekday-aware day stepper as FoodEntryListView's — kept local here
/// rather than shared, matching how that one is scoped to its own file too.
private struct DaySelectorRow: View {
    @Binding var selectedDate: Date

    private var calendar: Calendar { .current }
    private var isToday: Bool { calendar.isDateInToday(selectedDate) }

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

private struct GoalRow: View {
    let label: String
    let detail: String?
    let symbolName: String
    let symbolColor: Color

    var body: some View {
        HStack {
            Image(systemName: symbolName)
                .foregroundStyle(symbolColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct ProgressRow: View {
    let label: String
    let count: Int
    let target: Int

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(count)/\(target) this week")
                .foregroundStyle(count >= target ? .green : .secondary)
        }
    }
}

private struct TaskToggleRow: View {
    let task: DailyTask
    let date: Date
    let model: HomeModel
    let isDayClosed: Bool

    private var isDone: Bool { model.isTaskCompleted(task, on: date) }

    // Weekly tasks aren't expected every single day — just N times
    // somewhere in the week — so a specific day closing doesn't make an
    // undone one a miss the way it does for a daily task.
    private var resolvesOnClose: Bool { task.recurrence == "daily" }

    private var symbolName: String {
        if isDone { return "checkmark.circle.fill" }
        if isDayClosed && resolvesOnClose { return "xmark.circle.fill" }
        return "circle"
    }

    private var symbolColor: Color {
        if isDone { return .green }
        if isDayClosed && resolvesOnClose { return .red }
        return .secondary
    }

    var body: some View {
        Button {
            Task { await model.toggleTask(task, on: date) }
        } label: {
            HStack {
                Image(systemName: symbolName)
                    .foregroundStyle(symbolColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .foregroundStyle(.primary)
                    if task.recurrence == "weekly", let target = task.targetCountPerWeek {
                        Text("\(model.completionsInWeek(task, containing: date))/\(target) this week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environment(APIClient())
}
