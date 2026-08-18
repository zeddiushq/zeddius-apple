import SwiftUI

struct WeightListView: View {
    @Environment(APIClient.self) private var api
    @State private var model: WeightLogModel?
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
            .navigationTitle("Weight")
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
                    AddWeightEntryView(model: model)
                }
            }
            .task {
                if model == nil {
                    model = WeightLogModel(api: api)
                }
                await model?.load()
            }
            .refreshable {
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(for model: WeightLogModel) -> some View {
        if model.isLoading && model.entries.isEmpty {
            ProgressView()
        } else if model.entries.isEmpty {
            ContentUnavailableView {
                Label("No weight entries yet", systemImage: "scalemass")
            } description: {
                Text("Tap + to log your first weigh-in.")
            }
        } else {
            List {
                ForEach(model.entries) { entry in
                    WeightRow(entry: entry)
                }
                .onDelete { offsets in
                    Task { await model.delete(at: offsets) }
                }
            }
        }
    }
}

private struct WeightRow: View {
    let entry: WeightLog

    private var weightLbs: Decimal {
        entry.weightKg * Decimal(2.20462)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(weightLbs, format: .number.precision(.fractionLength(1))) lb")
                    .font(.headline)
                Text(entry.recordedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let bodyFatPct = entry.bodyFatPct {
                Text("\(bodyFatPct, format: .number.precision(.fractionLength(1)))% BF")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WeightListView()
        .environment(APIClient())
}
