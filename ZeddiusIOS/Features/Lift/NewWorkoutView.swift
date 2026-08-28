import SwiftUI

/// Creates just the workout shell. Sets get added afterward from
/// WorkoutDetailView, which this view navigates into on success.
struct NewWorkoutView: View {
    var model: WorkoutModel
    var onCreated: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var type = WorkoutType.liftOptions[0].value
    @State private var startedAt = Date()
    @State private var notesText = ""
    @State private var isSaving = false
    @State private var isShowingSaveError = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $type) {
                    ForEach(WorkoutType.liftOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                DatePicker("Started", selection: $startedAt, in: ...Date())
                TextField("Notes (optional)", text: $notesText)
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Couldn't create workout", isPresented: $isShowingSaveError, presenting: model.errorMessage) { _ in
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
                        Button("Start") { Task { await save() } }
                    }
                }
            }
            .dismissKeyboardOnScroll()
        }
    }

    private func save() async {
        isSaving = true
        let notes = notesText.trimmingCharacters(in: .whitespaces)
        let workout = await model.createWorkout(
            type: type, startedAt: startedAt, notes: notes.isEmpty ? nil : notes
        )
        isSaving = false
        if let workout {
            dismiss()
            onCreated(workout.id)
        } else {
            isShowingSaveError = true
        }
    }
}

#Preview {
    NewWorkoutView(model: WorkoutModel(api: APIClient())) { _ in }
}
