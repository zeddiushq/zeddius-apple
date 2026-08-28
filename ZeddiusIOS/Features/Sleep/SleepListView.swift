import SwiftUI

struct SleepListView: View {
    @Environment(APIClient.self) private var api
    @State private var model: SleepLogModel?
    @State private var isPresentingAddEntry = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Sleep")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddEntry) {
                if let model {
                    AddSleepEntryView(model: model)
                }
            }
            .task {
                if model == nil {
                    model = SleepLogModel(api: api)
                }
                await model?.load()
            }
            .refreshable {
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(for model: SleepLogModel) -> some View {
        if model.isLoading && model.entries.isEmpty {
            ProgressView()
        } else if model.entries.isEmpty {
            ContentUnavailableView {
                Label("No sleep entries yet", systemImage: "bed.double")
            } description: {
                Text("Tap + to log last night's sleep.")
            }
        } else {
            List {
                ForEach(model.entries) { entry in
                    SleepRow(entry: entry)
                }
                .onDelete { offsets in
                    Task { await model.delete(at: offsets) }
                }
            }
        }
    }
}

private struct SleepRow: View {
    let entry: SleepLog

    private var durationText: String {
        let hours = entry.durationMinutes / 60
        let minutes = entry.durationMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(durationText)
                    .font(.headline)
                Text(entry.wakeTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let qualityScore = entry.qualityScore {
                Label("\(qualityScore)", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SleepListView()
        .environment(APIClient())
}
