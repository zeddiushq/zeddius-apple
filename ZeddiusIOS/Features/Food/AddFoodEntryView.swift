import SwiftUI

struct AddFoodEntryView: View {
    var model: FoodEntryModel

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var consumedAt: Date
    @State private var kcalText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var mealSlot: String? // nil = unset
    @State private var isSaving = false
    @State private var validationError: String?

    private static let mealSlots = ["breakfast", "lunch", "dinner", "snack"]

    /// `initialDate` lets the sheet default to whatever day is being viewed (e.g.
    /// backfilling yesterday) instead of always defaulting to "now".
    init(model: FoodEntryModel, initialDate: Date = Date()) {
        self.model = model
        _consumedAt = State(initialValue: initialDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    DatePicker("Consumed", selection: $consumedAt, in: ...Date())
                    Picker("Meal (optional)", selection: $mealSlot) {
                        Text("–").tag(String?.none)
                        ForEach(Self.mealSlots, id: \.self) { slot in
                            Text(slot.capitalized).tag(String?.some(slot))
                        }
                    }
                }

                Section("Macros (all optional)") {
                    HStack {
                        TextField("Calories", text: $kcalText)
                            .keyboardType(.decimalPad)
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Protein", text: $proteinText)
                            .keyboardType(.decimalPad)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Carbs", text: $carbsText)
                            .keyboardType(.decimalPad)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Fat", text: $fatText)
                            .keyboardType(.decimalPad)
                        Text("g")
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
            .navigationTitle("Log Food")
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

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "Enter a name."
            return
        }

        var hadParseError = false
        let kcal = parsedNonNegativeDecimal(kcalText, field: "Calories", failed: &hadParseError)
        let protein = parsedNonNegativeDecimal(proteinText, field: "Protein", failed: &hadParseError)
        let carbs = parsedNonNegativeDecimal(carbsText, field: "Carbs", failed: &hadParseError)
        let fat = parsedNonNegativeDecimal(fatText, field: "Fat", failed: &hadParseError)
        guard !hadParseError else { return }

        isSaving = true
        let success = await model.addEntry(
            name: name.trimmingCharacters(in: .whitespaces),
            consumedAt: consumedAt,
            kcal: kcal,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            mealSlot: mealSlot
        )
        isSaving = false

        if success {
            dismiss()
        }
    }

    /// Blank text means "not provided" (returns nil, no error). Non-blank text that
    /// isn't a valid non-negative number sets `validationError` and flips `failed`.
    private func parsedNonNegativeDecimal(_ text: String, field: String, failed: inout Bool) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        guard let value = Decimal(string: trimmed), value >= 0 else {
            validationError = "\(field) must be a non-negative number."
            failed = true
            return nil
        }
        return value
    }
}

#Preview {
    AddFoodEntryView(model: FoodEntryModel(api: APIClient()))
}
