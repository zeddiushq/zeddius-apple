import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }

            WeightListView()
                .tabItem {
                    Label("Weight", systemImage: "scalemass")
                }

            SleepListView()
                .tabItem {
                    Label("Sleep", systemImage: "bed.double")
                }

            FoodEntryListView()
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }

            WorkoutListView()
                .tabItem {
                    Label("Lift", systemImage: "dumbbell")
                }

            RunListView()
                .tabItem {
                    Label("Run", systemImage: "figure.run")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(APIClient())
}
