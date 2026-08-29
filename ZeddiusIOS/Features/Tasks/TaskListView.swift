import SwiftUI

/// Manage the recurring tasks that make up the daily checklist (laundry,
/// cat boxes, dishwasher, water trees, dinner, etc.) — add and remove them
/// here. Checking them off day-to-day happens on Home, not here.
struct TaskListView: View {
    @Environment(APIClient.self) private var api
    @State private var model: TaskListModel?
    @State private var isPresentingAddTask = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Manage Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddTask) {
                if let model {
                    AddTaskView(model: model)
                }
            }
            .task {
                if model == nil {
                    model = TaskListModel(api: api)
                }
                await model?.load()
            }
            .refreshable {
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(for model: TaskListModel) -> some View {
        if model.isLoading && model.tasks.isEmpty {
            ProgressView()
        } else if model.tasks.isEmpty {
            ContentUnavailableView {
                Label("No tasks yet", systemImage: "checklist")
            } description: {
                Text("Tap + to add a recurring task.")
            }
        } else {
            List {
                ForEach(model.tasks) { task in
                    TaskRow(task: task)
                }
                .onDelete { offsets in
                    Task { await model.delete(at: offsets) }
                }
                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

private struct TaskRow: View {
    let task: DailyTask

    private var subtitle: String {
        if task.recurrence == "weekly", let count = task.targetCountPerWeek {
            return "\(count)x per week"
        }
        return "Daily"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(task.title)
                .font(.body)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    TaskListView()
        .environment(APIClient())
}
