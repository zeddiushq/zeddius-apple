import SwiftUI

struct RunListView: View {
    @Environment(APIClient.self) private var api
    @State private var model: RunModel?
    @State private var isPresentingLogRun = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Run")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingLogRun = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingLogRun) {
                if let model {
                    LogRunView(model: model)
                }
            }
            .task {
                if model == nil {
                    model = RunModel(api: api)
                }
                await model?.load()
            }
            .refreshable {
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(for model: RunModel) -> some View {
        let runWorkouts = model.runWorkouts
        if model.isLoading && runWorkouts.isEmpty {
            ProgressView()
        } else if runWorkouts.isEmpty {
            ContentUnavailableView {
                Label("No runs yet", systemImage: "figure.run")
            } description: {
                Text("Tap + to log a run.")
            }
        } else {
            List {
                ForEach(runWorkouts) { workout in
                    RunWorkoutRow(workout: workout)
                }
                .onDelete { offsets in
                    Task { await model.delete(at: offsets, in: runWorkouts) }
                }
            }
        }
    }
}

private struct RunWorkoutRow: View {
    let workout: Workout

    private static let metersPerMile = Decimal(1609.344)
    private static let kmPerMile = 1.609344

    /// "3.1 mi · 30:00 · 9:39 /mi" — nil when there's no run_session yet
    /// (shouldn't happen for a row created via LogRunView, but the list
    /// endpoint's join makes this genuinely optional on the wire).
    private var summary: String? {
        guard let session = workout.runSession else { return nil }
        let miles = session.distanceMeters / Self.metersPerMile
        var parts = [
            "\(miles.formatted(.number.precision(.fractionLength(1)))) mi",
            Self.formatDuration(session.durationSeconds),
        ]
        if let paceSecondsPerKm = session.avgPaceSecondsPerKm {
            let paceSecondsPerMile = Int((Double(paceSecondsPerKm) * Self.kmPerMile).rounded())
            parts.append("\(Self.formatDuration(paceSecondsPerMile)) /mi")
        }
        return parts.joined(separator: " · ")
    }

    private static func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(WorkoutType.label(for: workout.type))
                .font(.headline)
            Text(workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
            if let summary {
                Text(summary)
                    .font(.subheadline)
            }
            if let notes = workout.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RunListView()
        .environment(APIClient())
}
