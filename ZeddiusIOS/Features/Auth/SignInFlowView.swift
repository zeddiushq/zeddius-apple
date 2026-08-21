import SwiftUI

struct SignInFlowView: View {
    @State private var model = AuthFlowModel()

    var body: some View {
        switch model.stage {
        case .signIn:
            NavigationStack {
                SignInView(model: model)
            }
        case .needsProfile(let identityToken):
            CompleteProfileView(model: model, identityToken: identityToken)
        case .needsPasswordLink(let identityToken):
            LinkPasswordView(model: model, identityToken: identityToken)
        }
    }
}

#Preview {
    SignInFlowView()
}
