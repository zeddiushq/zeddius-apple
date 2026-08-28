import SwiftUI

/// A set the user has staged locally before saving — not yet sent to the API.
struct DraftLiftSet: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let actualReps: Int?
    let actualWeightKg: Decimal?
    let rpe: Decimal?
    let notes: String?
}

struct LogWorkoutView: View {
    var model: WorkoutModel

    @Environment(\.dismiss) private var dismiss

    @State private var type = WorkoutType.liftOptions[0].value
    @State private var startedAt = Date()
    @State private var notesText = ""
    @State private var draftSets: [DraftLiftSet] = []
    @State private var isPresentingAddSet = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(WorkoutType.liftOptions, id: \.value) { option in
                            Text(option.label).tag(option.value)
                        }
                    }
                    DatePicker("Started", selection: $startedAt, in: ...Date())
                    TextField("Notes (optional)", text: $notesText)
                }

                Section("Sets") {
                    if draftSets.isEmpty {
                        Text("No sets added yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(draftSets) { set in
                            DraftLiftSetRow(set: set)
                        }
                        .onDelete { offsets in
                            draftSets.remove(atOffsets: offsets)
                        }
                    }
                    Button {
                        isPresentingAddSet = true
                    } label: {
                        Label("Add Set", systemImage: "plus")
                    }
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddSet) {
                AddLiftSetView(exercises: model.exercises) { newSet in
                    draftSets.append(newSet)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        let notes = notesText.trimmingCharacters(in: .whitespaces)
        let success = await model.logWorkout(
            type: type,
            startedAt: startedAt,
            notes: notes.isEmpty ? nil : notes,
            sets: buildRequests(from: draftSets)
        )
        isSaving = false
        if success {
            dismiss()
        }
    }

    /// set_number is assigned per-exercise (1, 2, 3... within each exercise),
    /// not globally across the whole session — matches how a lifter thinks
    /// about "set 2 of bench," not "the 5th thing logged overall."
    private func buildRequests(from drafts: [DraftLiftSet]) -> [CreateLiftSetRequest] {
        var countByExercise: [UUID: Int] = [:]
        return drafts.map { draft in
            let number = (countByExercise[draft.exercise.id] ?? 0) + 1
            countByExercise[draft.exercise.id] = number
            return CreateLiftSetRequest(
                exerciseId: draft.exercise.id,
                setNumber: number,
                actualReps: draft.actualReps,
                actualWeightKg: draft.actualWeightKg,
                rpe: draft.rpe,
                notes: draft.notes
            )
        }
    }
}

private struct DraftLiftSetRow: View {
    let set: DraftLiftSet

    private var detailText: String? {
        guard let reps = set.actualReps else { return nil }
        guard let weightKg = set.actualWeightKg else { return "\(reps) reps" }
        let weightLbs = weightKg * Decimal(2.20462)
        let weightText = weightLbs.formatted(.number.precision(.fractionLength(0)))
        return "\(reps) @ \(weightText) lb"
    }

    var body: some View {
        HStack {
            Text(set.exercise.name)
            Spacer()
            if let detailText {
                Text(detailText)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    LogWorkoutView(model: WorkoutModel(api: APIClient()))
}
