import SwiftUI

struct VerifyEmailView: View {
    @State private var code = ""
    @State private var isVerifying = false
    @State private var isResending = false
    @State private var errorMessage: String?
    @State private var resendConfirmation: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Check your email")
                    .font(.title.bold())
                Text("Enter the 6-digit code we sent to \(AuthService.shared.currentUser?.email ?? "your email").")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.title2.monospaced())
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 48)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            if let resendConfirmation {
                Text(resendConfirmation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await verify() }
            } label: {
                if isVerifying {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Verify").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || isVerifying)
            .padding(.horizontal, 24)

            Button("Resend Code") {
                Task { await resend() }
            }
            .disabled(isResending)

            Spacer()

            Button("Sign Out", role: .destructive) {
                AuthService.shared.signOut()
            }
            .padding(.bottom, 24)
        }
    }

    private func verify() async {
        errorMessage = nil
        resendConfirmation = nil
        isVerifying = true
        defer { isVerifying = false }

        do {
            _ = try await AuthService.shared.verifyEmail(code: code.trimmingCharacters(in: .whitespaces))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resend() async {
        errorMessage = nil
        resendConfirmation = nil
        isResending = true
        defer { isResending = false }

        do {
            try await AuthService.shared.resendVerificationCode()
            resendConfirmation = "A fresh code is on its way."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    VerifyEmailView()
}
