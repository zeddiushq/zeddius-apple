import SwiftUI

struct AddSleepEntryView: View {
    var model: SleepLogModel

    @Environment(\.dismiss) private var dismiss

    @State private var bedTime = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
    @State private var wakeTime = Date()
    @State private var qualityScore = 0 // 0 = unset; 1-5 = real score
    @State private var isSaving = false
    @State private var validationError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Bed time", selection: $bedTime, in: ...Date())
                    DatePicker("Wake time", selection: $wakeTime, in: ...Date())
                }

                Section {
                    Picker("Quality (optional)", selection: $qualityScore) {
                        Text("–").tag(0)
                        ForEach(1...5, id: \.self) { score in
                            Text("\(score)").tag(score)
                        }
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
            .navigationTitle("Log Sleep")
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

        guard wakeTime > bedTime else {
            validationError = "Wake time must be after bed time."
            return
        }

        isSaving = true
        let success = await model.addEntry(
            bedTime: bedTime,
            wakeTime: wakeTime,
            qualityScore: qualityScore == 0 ? nil : qualityScore
        )
        isSaving = false

        if success {
            dismiss()
        }
    }
}

#Preview {
    AddSleepEntryView(model: SleepLogModel(api: APIClient()))
}
