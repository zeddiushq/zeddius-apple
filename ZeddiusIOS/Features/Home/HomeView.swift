import SwiftUI

struct HomeView: View {
    @Environment(APIClient.self) private var api
    @State private var model: HomeModel?

    private static let kgPerLb = Decimal(0.45359237)

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Home")
            .task {
                if model == nil {
                    model = HomeModel(api: api)
                }
                await model?.load()
            }
            .refreshable {
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(for model: HomeModel) -> some View {
        if model.isLoading && !model.hasLoadedOnce {
            ProgressView()
        } else {
            List {
                Section("Sleep") {
                    if let sleep = model.latestSleep {
                        LabeledContent(sleep.date.formatted(date: .abbreviated, time: .omitted)) {
                            Text(Self.formatDuration(minutes: sleep.durationMinutes))
                        }
                    } else {
                        Text("No sleep logged yet")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Food today") {
                    HStack {
                        Text(kcalText(model))
                        Spacer()
                        Text(proteinText(model))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Weight") {
                    if let weight = model.latestWeight {
                        let lbs = weight.weightKg / Self.kgPerLb
                        LabeledContent(weight.recordedAt.formatted(date: .abbreviated, time: .omitted)) {
                            Text("\(lbs.formatted(.number.precision(.fractionLength(1)))) lb")
                        }
                    } else {
                        Text("No weight logged yet")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Last workout") {
                    if let workout = model.lastWorkout {
                        LabeledContent(WorkoutType.label(for: workout.type)) {
                            Text(workout.startedAt.formatted(date: .abbreviated, time: .omitted))
                        }
                    } else {
                        Text("No workouts logged yet")
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func kcalText(_ model: HomeModel) -> String {
        let total = model.todayKcal.formatted(.number.precision(.fractionLength(0)))
        guard let target = model.targetCalories else { return "\(total) kcal" }
        return "\(total) / \(target) kcal"
    }

    private func proteinText(_ model: HomeModel) -> String {
        let total = model.todayProteinG.formatted(.number.precision(.fractionLength(0)))
        guard let target = model.targetProteinG else { return "\(total)g protein" }
        return "\(total) / \(target)g protein"
    }

    private static func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}

#Preview {
    HomeView()
        .environment(APIClient())
}
