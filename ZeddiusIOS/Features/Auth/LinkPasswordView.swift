import SwiftUI

struct LinkPasswordView: View {
    var model: AuthFlowModel
    let identityToken: String

    @State private var password = ""

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Account already exists")
                    .font(.title.bold())
                Text("An account with this email already has a password. Enter it to link Sign in with Apple.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 24)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                Task { await model.submitPassword(identityToken: identityToken, password: password) }
            } label: {
                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Link Account")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(password.isEmpty || model.isLoading)
            .padding(.horizontal, 24)

            Button("Cancel", role: .cancel) {
                model.cancel()
            }

            Spacer()
        }
    }
}

#Preview {
    LinkPasswordView(model: AuthFlowModel(), identityToken: "preview-token")
}
