import SwiftUI

struct EditTargetsView: View {
    var model: ProfileModel

    @Environment(\.dismiss) private var dismiss

    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var weightLbsText: String
    @State private var isSaving = false
    @State private var validationError: String?

    private static let kgPerLb = Decimal(0.45359237)

    init(model: ProfileModel) {
        self.model = model
        let user = model.user
        _caloriesText = State(initialValue: user?.targetCalories.map(String.init) ?? "")
        _proteinText = State(initialValue: user?.targetProteinG.map(String.init) ?? "")
        if let kg = user?.targetWeightKg {
            let lbs = kg / Self.kgPerLb
            _weightLbsText = State(initialValue: lbs.formatted(.number.precision(.fractionLength(0...1))))
        } else {
            _weightLbsText = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Calories", text: $caloriesText)
                            .keyboardType(.numberPad)
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Protein", text: $proteinText)
                            .keyboardType(.numberPad)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Daily targets")
                } footer: {
                    Text("Leave a field blank to leave it unchanged.")
                }

                Section("Weight goal") {
                    HStack {
                        TextField("Target weight", text: $weightLbsText)
                            .keyboardType(.decimalPad)
                        Text("lb")
                            .foregroundStyle(.secondary)
                    }
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
            .navigationTitle("Edit Targets")
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

        var calories: Int?
        let trimmedCalories = caloriesText.trimmingCharacters(in: .whitespaces)
        if !trimmedCalories.isEmpty {
            guard let value = Int(trimmedCalories), value > 0 else {
                validationError = "Calories must be a positive whole number."
                return
            }
            calories = value
        }

        var protein: Int?
        let trimmedProtein = proteinText.trimmingCharacters(in: .whitespaces)
        if !trimmedProtein.isEmpty {
            guard let value = Int(trimmedProtein), value > 0 else {
                validationError = "Protein must be a positive whole number."
                return
            }
            protein = value
        }

        var weightKg: Decimal?
        let trimmedWeight = weightLbsText.trimmingCharacters(in: .whitespaces)
        if !trimmedWeight.isEmpty {
            guard let lbs = Decimal(string: trimmedWeight), lbs > 0 else {
                validationError = "Target weight must be a positive number."
                return
            }
            weightKg = lbs * Self.kgPerLb
        }

        isSaving = true
        let success = await model.updateTargets(
            targetCalories: calories,
            targetProteinG: protein,
            targetWeightKg: weightKg
        )
        isSaving = false
        if success {
            dismiss()
        }
    }
}

#Preview {
    EditTargetsView(model: ProfileModel(api: APIClient()))
}
