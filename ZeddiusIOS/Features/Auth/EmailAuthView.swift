import SwiftUI

struct EmailAuthView: View {
    private enum Mode: String, CaseIterable {
        case signIn = "Sign In"
        case createAccount = "Create Account"
    }

    private enum Field {
        case email, username, displayName, password
    }

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private var canSubmit: Bool {
        guard !isLoading, !email.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            return false
        }
        if mode == .createAccount {
            return !username.trimmingCharacters(in: .whitespaces).isEmpty
                && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                VStack(spacing: 16) {
                    field("Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress, field: .email, next: mode == .createAccount ? .username : .password, autocapitalize: false)

                    if mode == .createAccount {
                        field("Username", text: $username, contentType: .username, keyboard: .default, field: .username, next: .displayName, autocapitalize: false)
                        field("Display name", text: $displayName, contentType: .name, keyboard: .default, field: .displayName, next: .password)
                    }

                    SecureField("Password", text: $password)
                        .textContentType(mode == .createAccount ? .newPassword : .password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit { Task { await submit() } }
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 24)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(mode == .signIn ? "Sign In" : "Create Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Email")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: mode) { errorMessage = nil }
    }

    @ViewBuilder
    private func field(
        _ title: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType,
        field: Field,
        next: Field,
        autocapitalize: Bool = true
    ) -> some View {
        TextField(title, text: text)
            .textContentType(contentType)
            .keyboardType(keyboard)
            .textInputAutocapitalization(autocapitalize ? .words : .never)
            .autocorrectionDisabled(!autocapitalize)
            .focused($focusedField, equals: field)
            .submitLabel(.next)
            .onSubmit { focusedField = next }
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            if mode == .signIn {
                _ = try await AuthService.shared.login(email: trimmedEmail, password: password)
            } else {
                _ = try await AuthService.shared.register(
                    email: trimmedEmail,
                    username: username.trimmingCharacters(in: .whitespaces),
                    displayName: displayName.trimmingCharacters(in: .whitespaces),
                    password: password
                )
            }
            // On success, AuthService.isSignedIn (and possibly needsEmailVerification)
            // flip and RootView reacts — nothing else to do here.
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        EmailAuthView()
    }
}
