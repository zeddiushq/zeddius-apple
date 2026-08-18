import SwiftUI

@main
struct ZeddiusApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(AuthService.shared)
                .environment(APIClient())
        }
    }
}
