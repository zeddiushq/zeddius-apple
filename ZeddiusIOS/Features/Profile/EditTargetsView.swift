import SwiftUI

struct EditTargetsView: View {
    var model: ProfileModel

    @Environment(\.dismiss) private var dismiss

    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var weightLbsText: String
    @State private var wakeTime: Date
    @State private var bedTime: Date
    @State private var weeklyRunsText: String
    @State private var weeklyLiftsText: String
    @State private var isSaving = false
    @State private var validationError: String?

    private static let kgPerLb = Decimal(0.45359237)
    private static let defaultWakeTime = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
    private static let defaultBedTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()

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
        _wakeTime = State(initialValue: user?.targetWakeTime ?? Self.defaultWakeTime)
        _bedTime = State(initialValue: user?.targetBedTime ?? Self.defaultBedTime)
        _weeklyRunsText = State(initialValue: user?.targetWeeklyRuns.map(String.init) ?? "")
        _weeklyLiftsText = State(initialValue: user?.targetWeeklyLifts.map(String.init) ?? "")
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

                Section("Sleep schedule") {
                    DatePicker("Wake by", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    DatePicker("Bed by", selection: $bedTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    HStack {
                        TextField("Runs", text: $weeklyRunsText)
                            .keyboardType(.numberPad)
                        Text("per week")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Lifts", text: $weeklyLiftsText)
                            .keyboardType(.numberPad)
                        Text("per week")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Weekly cadence")
                } footer: {
                    Text("Leave a field blank to leave it unchanged.")
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
            .dismissKeyboardOnScroll()
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

        var weeklyRuns: Int?
        let trimmedRuns = weeklyRunsText.trimmingCharacters(in: .whitespaces)
        if !trimmedRuns.isEmpty {
            guard let value = Int(trimmedRuns), value > 0 else {
                validationError = "Runs per week must be a positive whole number."
                return
            }
            weeklyRuns = value
        }

        var weeklyLifts: Int?
        let trimmedLifts = weeklyLiftsText.trimmingCharacters(in: .whitespaces)
        if !trimmedLifts.isEmpty {
            guard let value = Int(trimmedLifts), value > 0 else {
                validationError = "Lifts per week must be a positive whole number."
                return
            }
            weeklyLifts = value
        }

        isSaving = true
        let success = await model.updateTargets(
            targetCalories: calories,
            targetProteinG: protein,
            targetWeightKg: weightKg,
            targetWakeTime: wakeTime,
            targetBedTime: bedTime,
            targetWeeklyRuns: weeklyRuns,
            targetWeeklyLifts: weeklyLifts
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
