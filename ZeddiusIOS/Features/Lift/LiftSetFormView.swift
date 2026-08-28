import SwiftUI

/// Add a set or edit one, in the same form. In edit mode the exercise is
/// fixed (shown as text, not a picker) and fields start pre-filled; in add
/// mode you pick an exercise and everything starts blank. Either way,
/// saving persists directly — there's no local "draft" staged for a later
/// bulk save, since most sessions get logged set-by-set over time, not all
/// at once.
struct LiftSetFormView: View {
    let exercises: [Exercise]
    let existingSet: LiftSet?
    let onSave: (UUID, Int?, Decimal?, Decimal?, String?) async -> Bool

    @Environment(\.dismiss) private var dismiss

    @State private var selectedExercise: Exercise?
    @State private var repsText: String
    @State private var weightLbsText: String
    @State private var rpeText: String
    @State private var notesText: String
    @State private var validationError: String?
    @State private var isSaving = false
    @State private var isShowingSaveError = false

    private static let kgPerLb = Decimal(0.45359237)

    init(exercises: [Exercise], existingSet: LiftSet?, onSave: @escaping (UUID, Int?, Decimal?, Decimal?, String?) async -> Bool) {
        self.exercises = exercises
        self.existingSet = existingSet
        self.onSave = onSave
        _selectedExercise = State(initialValue: existingSet.flatMap { set in exercises.first { $0.id == set.exerciseId } })
        _repsText = State(initialValue: existingSet?.actualReps.map(String.init) ?? "")
        if let weightKg = existingSet?.actualWeightKg {
            let lbs = weightKg / Self.kgPerLb
            _weightLbsText = State(initialValue: lbs.formatted(.number.precision(.fractionLength(0...1))))
        } else {
            _weightLbsText = State(initialValue: "")
        }
        _rpeText = State(initialValue: existingSet?.rpe.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? "")
        _notesText = State(initialValue: existingSet?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if existingSet != nil {
                        LabeledContent("Exercise", value: selectedExercise?.name ?? "")
                    } else {
                        Picker("Exercise", selection: $selectedExercise) {
                            Text("Select an exercise").tag(Exercise?.none)
                            ForEach(exercises) { exercise in
                                Text(exercise.name).tag(Exercise?.some(exercise))
                            }
                        }
                    }
                }

                Section {
                    TextField("Reps", text: $repsText)
                        .keyboardType(.numberPad)
                    HStack {
                        TextField("Weight (optional)", text: $weightLbsText)
                            .keyboardType(.decimalPad)
                        Text("lb")
                            .foregroundStyle(.secondary)
                    }
                    TextField("RPE (optional, 0-10)", text: $rpeText)
                        .keyboardType(.decimalPad)
                    TextField("Notes (optional)", text: $notesText)
                }

                if let validationError {
                    Text(validationError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(existingSet == nil ? "Add Set" : "Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Couldn't save set", isPresented: $isShowingSaveError, presenting: validationError) { _ in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(existingSet == nil ? "Add" : "Save") { Task { await save() } }
                    }
                }
            }
            .dismissKeyboardOnScroll()
        }
    }

    private func save() async {
        guard let exercise = selectedExercise else {
            validationError = "Choose an exercise."
            isShowingSaveError = true
            return
        }

        var actualReps: Int?
        if !repsText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let reps = Int(repsText), reps > 0 else {
                validationError = "Reps must be a whole number."
                isShowingSaveError = true
                return
            }
            actualReps = reps
        }

        var actualWeightKg: Decimal?
        if !weightLbsText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let lbs = Decimal(string: weightLbsText), lbs >= 0 else {
                validationError = "Weight must be a non-negative number."
                isShowingSaveError = true
                return
            }
            actualWeightKg = lbs * Self.kgPerLb
        }

        var rpe: Decimal?
        if !rpeText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let value = Decimal(string: rpeText), value >= 0, value <= 10 else {
                validationError = "RPE must be between 0 and 10."
                isShowingSaveError = true
                return
            }
            rpe = value
        }

        let notes = notesText.trimmingCharacters(in: .whitespaces)

        isSaving = true
        let success = await onSave(exercise.id, actualReps, actualWeightKg, rpe, notes.isEmpty ? nil : notes)
        isSaving = false
        if success {
            dismiss()
        } else {
            validationError = "Something went wrong. Try again."
            isShowingSaveError = true
        }
    }
}

#Preview {
    LiftSetFormView(exercises: [], existingSet: nil) { _, _, _, _, _ in true }
}
