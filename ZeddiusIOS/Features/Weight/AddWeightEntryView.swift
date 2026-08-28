import SwiftUI

struct AddWeightEntryView: View {
    var model: WeightLogModel

    @Environment(\.dismiss) private var dismiss

    @State private var weightLbsText = ""
    @State private var bodyFatPctText = ""
    @State private var recordedAt = Date()
    @State private var isSaving = false
    @State private var validationError: String?

    private static let kgPerLb = Decimal(0.45359237)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Weight", text: $weightLbsText)
                            .keyboardType(.decimalPad)
                        Text("lb")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Body fat (optional)", text: $bodyFatPctText)
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    DatePicker("Recorded", selection: $recordedAt, in: ...Date())
                }

                if let validationError {
                    Text(validationError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Log Weight")
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
            .dismissKeyboardToolbar()
        }
    }

    private func save() async {
        validationError = nil

        guard let weightLbs = Decimal(string: weightLbsText), weightLbs > 0 else {
            validationError = "Enter a valid weight."
            return
        }

        var bodyFatPct: Decimal?
        if !bodyFatPctText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let value = Decimal(string: bodyFatPctText), value >= 0, value <= 100 else {
                validationError = "Body fat % must be between 0 and 100."
                return
            }
            bodyFatPct = value
        }

        let weightKg = weightLbs * Self.kgPerLb

        isSaving = true
        let success = await model.addEntry(weightKg: weightKg, bodyFatPct: bodyFatPct, recordedAt: recordedAt)
        isSaving = false

        if success {
            dismiss()
        }
    }
}

#Preview {
    AddWeightEntryView(model: WeightLogModel(api: APIClient()))
}
