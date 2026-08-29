import SwiftUI

struct ProfileView: View {
    @Environment(APIClient.self) private var api
    @State private var model: ProfileModel?
    @State private var isSigningOut = false
    @State private var isPresentingEditTargets = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(for: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $isPresentingEditTargets) {
                if let model {
                    EditTargetsView(model: model)
                }
            }
            .task {
                if model == nil {
                    model = ProfileModel(api: api)
                }
                await model?.load()
            }
            .refreshable {
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(for model: ProfileModel) -> some View {
        if model.isLoading && model.user == nil {
            ProgressView()
        } else if let user = model.user {
            List {
                Section {
                    LabeledContent("Display name", value: user.displayName)
                    LabeledContent("Username", value: "@\(user.username)")
                    LabeledContent("Email", value: user.email)
                    LabeledContent("Email verified", value: user.emailVerifiedAt != nil ? "Yes" : "No")
                }

                Section("Settings") {
                    LabeledContent("Timezone", value: user.timezone)
                    if let heightCm = user.heightCm {
                        LabeledContent("Height", value: "\(Int(heightCm)) cm")
                    }
                    if let birthdate = user.birthdate {
                        LabeledContent("Birthdate", value: birthdate.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                Section {
                    if let targetCalories = user.targetCalories {
                        LabeledContent("Calories", value: "\(targetCalories) kcal")
                    }
                    if let targetProteinG = user.targetProteinG {
                        LabeledContent("Protein", value: "\(targetProteinG) g")
                    }
                    if let targetWeightKg = user.targetWeightKg {
                        let lbs = targetWeightKg / Decimal(0.45359237)
                        LabeledContent("Weight goal", value: "\(lbs.formatted(.number.precision(.fractionLength(0...1)))) lb")
                    }
                    if let targetSleepHours = user.targetSleepHours {
                        LabeledContent("Sleep", value: "\(targetSleepHours.formatted(.number.precision(.fractionLength(1)))) hrs")
                    }
                    if let wakeTime = user.targetWakeTime {
                        LabeledContent("Wake by", value: wakeTime.formatted(date: .omitted, time: .shortened))
                    }
                    if let bedTime = user.targetBedTime {
                        LabeledContent("Bed by", value: bedTime.formatted(date: .omitted, time: .shortened))
                    }
                    if let runs = user.targetWeeklyRuns {
                        LabeledContent("Runs", value: "\(runs) per week")
                    }
                    if let lifts = user.targetWeeklyLifts {
                        LabeledContent("Lifts", value: "\(lifts) per week")
                    }
                    Button("Edit Targets") {
                        isPresentingEditTargets = true
                    }
                } header: {
                    Text("Targets")
                }

                Section {
                    LabeledContent("Member since", value: user.createdAt.formatted(date: .abbreviated, time: .omitted))
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            isSigningOut = true
                            await AuthService.shared.signOutRemotely()
                            isSigningOut = false
                        }
                    }
                    .disabled(isSigningOut)
                }
            }
        } else if let errorMessage = model.errorMessage {
            ContentUnavailableView {
                Label("Couldn't load profile", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Retry") {
                    Task { await model.load() }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(APIClient())
}
