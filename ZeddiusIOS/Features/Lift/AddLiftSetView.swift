import SwiftUI

struct AddLiftSetView: View {
    let exercises: [Exercise]
    let onAdd: (DraftLiftSet) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedExercise: Exercise?
    @State private var repsText = ""
    @State private var weightLbsText = ""
    @State private var rpeText = ""
    @State private var notesText = ""
    @State private var validationError: String?

    private static let kgPerLb = Decimal(0.45359237)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Exercise", selection: $selectedExercise) {
                        Text("Select an exercise").tag(Exercise?.none)
                        ForEach(exercises) { exercise in
                            Text(exercise.name).tag(Exercise?.some(exercise))
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
            .navigationTitle("Add Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                }
            }
        }
    }

    private func add() {
        validationError = nil

        guard let exercise = selectedExercise else {
            validationError = "Choose an exercise."
            return
        }

        var actualReps: Int?
        if !repsText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let reps = Int(repsText), reps > 0 else {
                validationError = "Reps must be a whole number."
                return
            }
            actualReps = reps
        }

        var actualWeightKg: Decimal?
        if !weightLbsText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let lbs = Decimal(string: weightLbsText), lbs >= 0 else {
                validationError = "Weight must be a non-negative number."
                return
            }
            actualWeightKg = lbs * Self.kgPerLb
        }

        var rpe: Decimal?
        if !rpeText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let value = Decimal(string: rpeText), value >= 0, value <= 10 else {
                validationError = "RPE must be between 0 and 10."
                return
            }
            rpe = value
        }

        let notes = notesText.trimmingCharacters(in: .whitespaces)

        onAdd(
            DraftLiftSet(
                exercise: exercise,
                actualReps: actualReps,
                actualWeightKg: actualWeightKg,
                rpe: rpe,
                notes: notes.isEmpty ? nil : notes
            )
        )
        dismiss()
    }
}

#Preview {
    AddLiftSetView(exercises: []) { _ in }
}
