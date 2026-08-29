import SwiftUI

struct HistoryView: View {
    @Environment(APIClient.self) private var api
    @State private var model: HistoryModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("History")
            .task {
                if model == nil {
                    model = HistoryModel(api: api)
                }
                await model?.load()
            }
            .refreshable {
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(for model: HistoryModel) -> some View {
        if model.isLoading && !model.hasLoadedOnce {
            ProgressView()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Legend()

                    if model.user?.targetCalories != nil {
                        HabitSection(title: "Calories", dates: model.gridDates, status: model.caloriesStatus)
                    }
                    if model.user?.targetProteinG != nil {
                        HabitSection(title: "Protein", dates: model.gridDates, status: model.proteinStatus)
                    }
                    HabitSection(title: "Sleep", dates: model.gridDates, status: model.sleepStatus)
                    if model.user?.targetWeeklyRuns != nil {
                        HabitSection(
                            title: "Runs", dates: model.gridDates,
                            status: { model.runsStatus(forWeekContaining: $0) }
                        )
                    }
                    if model.user?.targetWeeklyLifts != nil {
                        HabitSection(
                            title: "Lifts", dates: model.gridDates,
                            status: { model.liftsStatus(forWeekContaining: $0) }
                        )
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
        }
    }
}

private struct HabitSection: View {
    let title: String
    let dates: [Date]
    let status: (Date) -> HabitCellStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            HabitGraph(dates: dates, status: status)
        }
    }
}

/// A GitHub-style contribution grid: 7 rows (days of week) x 13 columns
/// (weeks), oldest week on the left. Each cell is a hollow square until
/// resolved — filled green/red only once its day (or week) is judged.
private struct HabitGraph: View {
    let dates: [Date]
    let status: (Date) -> HabitCellStatus

    private static let rows = 7
    private static let cellSize: CGFloat = 14
    private static let cellSpacing: CGFloat = 3

    private var columns: Int { dates.count / Self.rows }

    private var weekdayLabels: [String] {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        let firstIndex = Calendar.current.firstWeekday - 1
        return (0..<7).map { symbols[(firstIndex + $0) % 7] }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(spacing: Self.cellSpacing) {
                ForEach(0..<Self.rows, id: \.self) { row in
                    Text(weekdayLabels[row])
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(width: 12, height: Self.cellSize)
                }
            }
            HStack(spacing: Self.cellSpacing) {
                ForEach(0..<columns, id: \.self) { column in
                    VStack(spacing: Self.cellSpacing) {
                        ForEach(0..<Self.rows, id: \.self) { row in
                            cell(for: dates[column * Self.rows + row])
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for date: Date) -> some View {
        let cellStatus = status(date)
        RoundedRectangle(cornerRadius: 3)
            .fill(fillColor(for: cellStatus))
            .frame(width: Self.cellSize, height: Self.cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(cellStatus == .neutral ? Color.secondary.opacity(0.35) : .clear, lineWidth: 1)
            )
    }

    private func fillColor(for status: HabitCellStatus) -> Color {
        switch status {
        case .met: .green
        case .missed: .red
        case .neutral: .clear
        }
    }
}

private struct Legend: View {
    var body: some View {
        HStack(spacing: 16) {
            swatch(.green, "Met")
            swatch(.red, "Missed")
            swatch(.clear, "Not closed", strokeVisible: true)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func swatch(_ color: Color, _ label: String, strokeVisible: Bool = false) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(strokeVisible ? Color.secondary.opacity(0.35) : .clear, lineWidth: 1)
                )
            Text(label)
        }
    }
}

#Preview {
    HistoryView()
        .environment(APIClient())
}
