import SwiftUI

struct LogRunView: View {
    var model: RunModel

    @Environment(\.dismiss) private var dismiss

    @State private var type = WorkoutType.runOptions[0].value
    @State private var startedAt = Date()
    @State private var distanceMilesText = ""
    @State private var minutesText = ""
    @State private var secondsText = ""
    @State private var avgHeartRateText = ""
    @State private var maxHeartRateText = ""
    @State private var elevationFeetText = ""
    @State private var notesText = ""
    @State private var isSaving = false
    @State private var validationError: String?
    @State private var isShowingSaveError = false

    private static let metersPerMile = Decimal(1609.344)
    private static let metersPerFoot = Decimal(0.3048)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(WorkoutType.runOptions, id: \.value) { option in
                            Text(option.label).tag(option.value)
                        }
                    }
                    DatePicker("Started", selection: $startedAt, in: ...Date())
                    TextField("Notes (optional)", text: $notesText)
                }

                Section("Distance & Duration") {
                    HStack {
                        TextField("Distance", text: $distanceMilesText)
                            .keyboardType(.decimalPad)
                        Text("mi")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Minutes", text: $minutesText)
                            .keyboardType(.numberPad)
                        TextField("Seconds", text: $secondsText)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Optional") {
                    TextField("Avg heart rate (bpm)", text: $avgHeartRateText)
                        .keyboardType(.numberPad)
                    TextField("Max heart rate (bpm)", text: $maxHeartRateText)
                        .keyboardType(.numberPad)
                    HStack {
                        TextField("Elevation gain", text: $elevationFeetText)
                            .keyboardType(.decimalPad)
                        Text("ft")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Log Run")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Couldn't save run", isPresented: $isShowingSaveError, presenting: validationError) { _ in
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
                        Button("Save") { Task { await save() } }
                    }
                }
            }
            .dismissKeyboardToolbar()
        }
    }

    private func save() async {
        validationError = nil

        guard let miles = Decimal(string: distanceMilesText), miles > 0 else {
            fail("Enter a valid distance.")
            return
        }

        let minutes = Int(minutesText) ?? 0
        let seconds = Int(secondsText) ?? 0
        let totalSeconds = minutes * 60 + seconds
        guard totalSeconds > 0 else {
            fail("Enter a duration — minutes and/or seconds.")
            return
        }

        var avgHeartRate: Int?
        if !avgHeartRateText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let value = Int(avgHeartRateText), value > 0 else {
                fail("Avg heart rate must be a whole number.")
                return
            }
            avgHeartRate = value
        }

        var maxHeartRate: Int?
        if !maxHeartRateText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let value = Int(maxHeartRateText), value > 0 else {
                fail("Max heart rate must be a whole number.")
                return
            }
            maxHeartRate = value
        }

        var elevationGainMeters: Decimal?
        if !elevationFeetText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let feet = Decimal(string: elevationFeetText), feet >= 0 else {
                fail("Elevation gain must be a non-negative number.")
                return
            }
            elevationGainMeters = feet * Self.metersPerFoot
        }

        let notes = notesText.trimmingCharacters(in: .whitespaces)
        let distanceMeters = miles * Self.metersPerMile

        isSaving = true
        let success = await model.logRun(
            type: type,
            startedAt: startedAt,
            notes: notes.isEmpty ? nil : notes,
            distanceMeters: distanceMeters,
            durationSeconds: totalSeconds,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            elevationGainMeters: elevationGainMeters
        )
        isSaving = false
        if success {
            dismiss()
        } else {
            fail(model.errorMessage ?? "Something went wrong. Try again.")
        }
    }

    /// Routes every failure through the same alert, so it's visible
    /// regardless of scroll position or whether the keyboard is covering
    /// the bottom of the form — unlike inline text, which can be hidden.
    private func fail(_ message: String) {
        validationError = message
        isShowingSaveError = true
    }
}

#Preview {
    LogRunView(model: RunModel(api: APIClient()))
}
