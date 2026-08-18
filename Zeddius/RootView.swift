import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        if auth.needsEmailVerification {
            VerifyEmailView()
        } else if auth.isSignedIn {
            MainTabView()
        } else {
            SignInFlowView()
        }
    }
}

#Preview {
    RootView()
        .environment(AuthService.shared)
        .environment(APIClient())
}
