import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            LogView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet.clipboard")
                }

            TrainView()
                .tabItem {
                    Label("Train", systemImage: "figure.run")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(APIClient())
}
