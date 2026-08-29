import SwiftUI

struct AddTaskView: View {
    var model: TaskListModel

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var recurrence = "daily"
    @State private var targetCountPerWeekText = ""
    @State private var isSaving = false
    @State private var validationError: String?
    @State private var isShowingSaveError = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)

                Picker("Recurrence", selection: $recurrence) {
                    Text("Daily").tag("daily")
                    Text("Weekly").tag("weekly")
                }
                .pickerStyle(.segmented)

                if recurrence == "weekly" {
                    HStack {
                        TextField("Times", text: $targetCountPerWeekText)
                            .keyboardType(.numberPad)
                        Text("per week")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Couldn't add task", isPresented: $isShowingSaveError, presenting: validationError) { _ in
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
                        Button("Add") { Task { await save() } }
                    }
                }
            }
            .dismissKeyboardOnScroll()
        }
    }

    private func save() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            validationError = "Enter a title."
            isShowingSaveError = true
            return
        }

        var targetCountPerWeek: Int?
        if recurrence == "weekly" {
            guard let value = Int(targetCountPerWeekText), value > 0 else {
                validationError = "Enter how many times per week."
                isShowingSaveError = true
                return
            }
            targetCountPerWeek = value
        }

        isSaving = true
        let success = await model.addTask(title: trimmedTitle, recurrence: recurrence, targetCountPerWeek: targetCountPerWeek)
        isSaving = false
        if success {
            dismiss()
        } else {
            validationError = model.errorMessage ?? "Something went wrong. Try again."
            isShowingSaveError = true
        }
    }
}

#Preview {
    AddTaskView(model: TaskListModel(api: APIClient()))
}
