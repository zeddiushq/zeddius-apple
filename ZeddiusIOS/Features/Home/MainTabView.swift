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
        }
    }
}

#Preview {
    MainTabView()
        .environment(APIClient())
}
