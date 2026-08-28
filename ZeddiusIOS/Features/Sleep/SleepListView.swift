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
                StarRatingView(score: qualityScore)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Filled stars for the score (1-5), outline stars for the rest — the number
/// alone didn't read as a rating, and a fixed "star.fill" icon didn't either.
private struct StarRatingView: View {
    let score: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { position in
                Image(systemName: position <= score ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(position <= score ? .yellow : .secondary)
            }
        }
    }
}

#Preview {
    SleepListView()
        .environment(APIClient())
}
