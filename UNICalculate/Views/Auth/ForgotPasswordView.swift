import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var isLoading = false
    @State private var showToast = false
    @State private var toast: Toast?
    @FocusState private var emailFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AuthBackground()

                ScrollView {
                    VStack(spacing: DS.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(Color.brandTint)
                                .frame(width: 88, height: 88)
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 38, weight: .medium))
                                .foregroundStyle(Color.brandPrimary)
                        }
                        .padding(.top, DS.Spacing.xl)

                        Text(LocalizedStringKey("reset_password"))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(LocalizedStringKey("reset_password_instructions"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Spacing.md)

                        IconTextField(systemImage: "envelope", isFocused: emailFocused) {
                            TextField(LocalizedStringKey("email"), text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($emailFocused)
                                .submitLabel(.go)
                                .onSubmit(handlePasswordReset)
                        }
                        .padding(.top, DS.Spacing.xs)

                        resetButton

                        Spacer(minLength: DS.Spacing.lg)
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)

                if showToast, let toast = toast {
                    ToastView(toast: toast, isPresented: $showToast)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(LocalizedStringKey("back"))
                        }
                        .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
        }
    }

    private var resetButton: some View {
        Button(action: handlePasswordReset) {
            HStack(spacing: DS.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(LocalizedStringKey("reset_password"))
            }
        }
        .buttonStyle(PrimaryButtonStyle(enabled: isValid() && !isLoading))
        .disabled(!isValid() || isLoading)
        .opacity(isValid() && !isLoading ? 1 : 0.7)
    }

    private func isValid() -> Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.isValidEmail
    }

    private func handlePasswordReset() {
        guard isValid() else { return }
        isLoading = true
        authViewModel.requestPasswordReset(email: email) { success, _ in
            isLoading = false
            if success {
                toast = Toast(message: "password_reset_email_sent", type: .success)
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            } else {
                toast = Toast(message: "error_password_reset_failed", type: .error)
                showToast = true
            }
        }
    }
}
