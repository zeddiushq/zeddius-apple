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

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(WorkoutType.label(for: workout.type))
                .font(.headline)
            Text(workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
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
