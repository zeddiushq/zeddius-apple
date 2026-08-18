import SwiftUI

struct CompleteProfileView: View {
    var model: AuthFlowModel
    let identityToken: String

    @State private var username = ""
    @State private var displayName = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case username, displayName
    }

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty
            && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
            && !model.isLoading
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Almost there")
                    .font(.title.bold())
                Text("Choose a username and how you'd like to be addressed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .displayName }
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

                TextField("Display name", text: $displayName)
                    .textContentType(.name)
                    .focused($focusedField, equals: .displayName)
                    .submitLabel(.done)
                    .onSubmit { Task { await submit() } }
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 24)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                Task { await submit() }
            } label: {
                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)
            .padding(.horizontal, 24)

            Button("Cancel", role: .cancel) {
                model.cancel()
            }

            Spacer()
        }
    }

    private func submit() async {
        await model.submitProfile(
            identityToken: identityToken,
            username: username.trimmingCharacters(in: .whitespaces),
            displayName: displayName.trimmingCharacters(in: .whitespaces)
        )
    }
}

#Preview {
    CompleteProfileView(model: AuthFlowModel(), identityToken: "preview-token")
}
