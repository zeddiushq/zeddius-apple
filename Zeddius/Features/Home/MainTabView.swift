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
        }
    }
}

#Preview {
    MainTabView()
        .environment(APIClient())
}
