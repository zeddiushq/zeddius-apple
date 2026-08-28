import SwiftUI

struct WorkoutListView: View {
    @Environment(APIClient.self) private var api
    @State private var model: WorkoutModel?
    @State private var isPresentingNewWorkout = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Lift")
            .navigationDestination(for: UUID.self) { workoutId in
                WorkoutDetailView(workoutId: workoutId)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingNewWorkout = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewWorkout) {
                if let model {
                    NewWorkoutView(model: model) { newWorkoutId in
                        path.append(newWorkoutId)
                    }
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
        let liftWorkouts = model.liftWorkouts
        if model.isLoading && liftWorkouts.isEmpty {
            ProgressView()
        } else if liftWorkouts.isEmpty {
            ContentUnavailableView {
                Label("No workouts yet", systemImage: "dumbbell")
            } description: {
                Text("Tap + to start a lifting session.")
            }
        } else {
            List {
                ForEach(liftWorkouts) { workout in
                    NavigationLink(value: workout.id) {
                        WorkoutRow(workout: workout)
                    }
                }
                .onDelete { offsets in
                    Task { await model.delete(at: offsets, in: liftWorkouts) }
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
