import SwiftUI

struct WorkoutListView: View {
    @Environment(APIClient.self) private var api
    @State private var model: WorkoutModel?
    @State private var isPresentingLogWorkout = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Lift")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingLogWorkout = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingLogWorkout) {
                if let model {
                    LogWorkoutView(model: model)
                }
            }
            .task {
                if model == nil {
                    model = WorkoutModel(api: api)
                }
                await model?.load()
            }
            .refreshable {
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(for model: WorkoutModel) -> some View {
        if model.isLoading && model.workouts.isEmpty {
            ProgressView()
        } else if model.workouts.isEmpty {
            ContentUnavailableView {
                Label("No workouts yet", systemImage: "dumbbell")
            } description: {
                Text("Tap + to log a lifting session.")
            }
        } else {
            List {
                ForEach(model.workouts) { workout in
                    WorkoutRow(workout: workout)
                }
                .onDelete { offsets in
                    Task { await model.delete(at: offsets) }
                }
            }
        }
    }
}

private struct WorkoutRow: View {
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
    WorkoutListView()
        .environment(APIClient())
}
