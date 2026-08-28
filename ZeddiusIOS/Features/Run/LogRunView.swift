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
    @State private var isShowingSaveError = false

    private static let metersPerMile = Decimal(1609.344)
    private static let metersPerFoot = Decimal(0.3048)

    /// Governs the Save button directly — required fields must be validly
    /// filled, and any optional field that's non-empty must also be valid.
    /// Catching this before the tap (rather than alerting after) means
    /// there's nothing left for save() to reject.
    private var canSave: Bool {
        guard let miles = Decimal(string: distanceMilesText), miles > 0 else { return false }

        let minutes = Int(minutesText) ?? 0
        let seconds = Int(secondsText) ?? 0
        guard minutes * 60 + seconds > 0 else { return false }

        if !avgHeartRateText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let value = Int(avgHeartRateText), value > 0 else { return false }
        }
        if !maxHeartRateText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let value = Int(maxHeartRateText), value > 0 else { return false }
        }
        if !elevationFeetText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let feet = Decimal(string: elevationFeetText), feet >= 0 else { return false }
        }
        return true
    }

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
            .alert("Couldn't save run", isPresented: $isShowingSaveError, presenting: model.errorMessage) { _ in
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
                            .disabled(!canSave)
                    }
                }
            }
            .dismissKeyboardOnScroll()
        }
    }

    /// `canSave` already guarantees every field here parses cleanly — the
    /// guards below just extract the values, not re-validate them.
    private func save() async {
        guard let miles = Decimal(string: distanceMilesText) else { return }

        let minutes = Int(minutesText) ?? 0
        let seconds = Int(secondsText) ?? 0
        let totalSeconds = minutes * 60 + seconds

        let avgHeartRateTrimmed = avgHeartRateText.trimmingCharacters(in: .whitespaces)
        let avgHeartRate = avgHeartRateTrimmed.isEmpty ? nil : Int(avgHeartRateTrimmed)

        let maxHeartRateTrimmed = maxHeartRateText.trimmingCharacters(in: .whitespaces)
        let maxHeartRate = maxHeartRateTrimmed.isEmpty ? nil : Int(maxHeartRateTrimmed)

        let elevationFeetTrimmed = elevationFeetText.trimmingCharacters(in: .whitespaces)
        let elevationGainMeters = elevationFeetTrimmed.isEmpty
            ? nil
            : Decimal(string: elevationFeetTrimmed).map { $0 * Self.metersPerFoot }

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
            isShowingSaveError = true
        }
    }
}

#Preview {
    LogRunView(model: RunModel(api: APIClient()))
}
