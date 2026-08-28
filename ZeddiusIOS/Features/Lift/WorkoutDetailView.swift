import SwiftUI

struct WorkoutDetailView: View {
    let workoutId: UUID

    @Environment(APIClient.self) private var api
    @State private var model: WorkoutDetailModel?
    @State private var isPresentingAddSet = false
    @State private var editingSet: LiftSet?

    var body: some View {
        Group {
            if let model {
                content(for: model)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(model?.workout.map { WorkoutType.label(for: $0.type) } ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddSet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddSet) {
            if let model {
                LiftSetFormView(exercises: model.exercises, existingSet: nil) { exerciseId, reps, weightKg, rpe, notes in
                    await model.addSet(exerciseId: exerciseId, actualReps: reps, actualWeightKg: weightKg, rpe: rpe, notes: notes)
                }
            }
        }
        .sheet(item: $editingSet) { set in
            if let model {
                LiftSetFormView(exercises: model.exercises, existingSet: set) { _, reps, weightKg, rpe, notes in
                    await model.updateSet(id: set.id, actualReps: reps, actualWeightKg: weightKg, rpe: rpe, notes: notes)
                }
            }
        }
        .task {
            if model == nil {
                model = WorkoutDetailModel(api: api, workoutId: workoutId)
            }
            await model?.load()
        }
        .refreshable {
            await model?.load()
        }
    }

    @ViewBuilder
    private func content(for model: WorkoutDetailModel) -> some View {
        if model.isLoading && model.workout == nil {
            ProgressView()
        } else if let workout = model.workout {
            List {
                Section {
                    LabeledContent("Started", value: workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                    if let notes = workout.notes, !notes.isEmpty {
                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                }

                if workout.liftSets.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No sets yet", systemImage: "dumbbell")
                        } description: {
                            Text("Tap + to log a set.")
                        }
                    }
                } else {
                    ForEach(groupedSets(workout.liftSets, exercises: model.exercises), id: \.exercise.id) { group in
                        Section(group.exercise.name) {
                            ForEach(group.sets) { set in
                                Button {
                                    editingSet = set
                                } label: {
                                    LiftSetRow(set: set)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        } else if let errorMessage = model.errorMessage {
            ContentUnavailableView {
                Label("Couldn't load workout", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Retry") { Task { await model.load() } }
            }
        }
    }

    /// Groups by exercise, preserving first-appearance order rather than
    /// re-sorting alphabetically — matches the order sets were logged in.
    private func groupedSets(_ sets: [LiftSet], exercises: [Exercise]) -> [(exercise: Exercise, sets: [LiftSet])] {
        var order: [UUID] = []
        var byExercise: [UUID: [LiftSet]] = [:]
        for set in sets {
            if byExercise[set.exerciseId] == nil {
                order.append(set.exerciseId)
            }
            byExercise[set.exerciseId, default: []].append(set)
        }
        return order.compactMap { exerciseId in
            guard let exercise = exercises.first(where: { $0.id == exerciseId }) else { return nil }
            let exerciseSets = (byExercise[exerciseId] ?? []).sorted { $0.setNumber < $1.setNumber }
            return (exercise, exerciseSets)
        }
    }
}

private struct LiftSetRow: View {
    let set: LiftSet

    private var detailText: String {
        var parts: [String] = []
        if let reps = set.actualReps {
            parts.append("\(reps) reps")
        }
        if let weightKg = set.actualWeightKg {
            let weightLbs = weightKg * Decimal(2.20462)
            parts.append("\(weightLbs.formatted(.number.precision(.fractionLength(0)))) lb")
        }
        if let rpe = set.rpe {
            parts.append("RPE \(rpe.formatted(.number.precision(.fractionLength(0...1))))")
        }
        return parts.isEmpty ? "No details" : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Set \(set.setNumber)")
                    .font(.subheadline)
                Text(detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let notes = set.notes, !notes.isEmpty {
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
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workoutId: UUID())
            .environment(APIClient())
    }
}
