import SwiftUI
import AuthenticationServices

struct SignInView: View {
    var model: AuthFlowModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("Zeddius")
                    .font(.largeTitle.bold())
                Text("Your personal health tracker")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email]
                    request.nonce = model.makeNonce()
                } onCompletion: { result in
                    handle(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(model.isLoading)

                NavigationLink("Continue with Email") {
                    EmailAuthView()
                }
                .font(.subheadline)

                if model.isLoading {
                    ProgressView()
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8)
            else {
                model.errorMessage = "Apple didn't return a usable identity token."
                return
            }
            Task { await model.handleAppleIdentityToken(identityToken) }
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == ASAuthorizationError.errorDomain,
               nsError.code == ASAuthorizationError.canceled.rawValue {
                return
            }
            model.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SignInView(model: AuthFlowModel())
}
