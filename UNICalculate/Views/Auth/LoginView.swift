import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var showForgotPassword = false
    @State private var showToast = false
    @State private var toast: Toast?
    @FocusState private var focusedField: Field?
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject private var languageManager: LanguageManager

    enum Field {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuthBackground()

                ScrollView {
                    VStack(spacing: DS.Spacing.lg) {
                        HStack {
                            Spacer()
                            languageSelector
                        }

                        Spacer(minLength: DS.Spacing.xl)

                        AppWordmark()
                        Text(LocalizedStringKey("welcome_back"))
                            .font(.system(.title3, design: .rounded).weight(.medium))
                            .foregroundStyle(.secondary)

                        formCard
                        loginButton
                        signupPrompt

                        Spacer(minLength: DS.Spacing.lg)
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.top, DS.Spacing.xs)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)

                if showToast, let toast = toast {
                    ToastView(toast: toast, isPresented: $showToast)
                }
            }
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    // MARK: - Language selector
    private var languageSelector: some View {
        Menu {
            Button { languageManager.selectedLanguage = "tr" } label: {
                HStack {
                    Text("Türkçe")
                    if languageManager.selectedLanguage == "tr" { Image(systemName: "checkmark") }
                }
            }
            Button { languageManager.selectedLanguage = "en" } label: {
                HStack {
                    Text("English")
                    if languageManager.selectedLanguage == "en" { Image(systemName: "checkmark") }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                Text(LocalizedStringKey("language"))
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(Color.brandOnTint)
            .background(Capsule().fill(Color.brandTint))
        }
    }

    // MARK: - Form
    private var formCard: some View {
        VStack(spacing: DS.Spacing.md) {
            IconTextField(systemImage: "envelope", isFocused: focusedField == .email) {
                TextField(LocalizedStringKey("email"), text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }

            IconTextField(systemImage: "lock", isFocused: focusedField == .password) {
                SecureField(LocalizedStringKey("password"), text: $password)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit(handleLogin)
            }

            HStack {
                Spacer()
                Button { showForgotPassword = true } label: {
                    Text(LocalizedStringKey("forgot_password"))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
        .padding(.top, DS.Spacing.xs)
    }

    private var loginButton: some View {
        Button(action: handleLogin) {
            Text(LocalizedStringKey("login"))
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    private var signupPrompt: some View {
        HStack(spacing: 4) {
            Text(LocalizedStringKey("no_account"))
                .foregroundStyle(.secondary)
            Button { showSignup = true } label: {
                Text(LocalizedStringKey("signup"))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)
            }
        }
        .font(.subheadline)
        .padding(.top, DS.Spacing.xxs)
    }

    // MARK: - Actions
    private func handleLogin() {
        guard validateForm() else { return }

        authViewModel.login(email: email, password: password) { success, errorMessage in
            if success {
                toast = Toast(message: LocalizedStringKey("login_successful"), type: .success)
            } else {
                handleLoginError(errorMessage)
            }
            showToast = true
        }
    }

    private func handleLoginError(_ errorMessage: String?) {
        // errorMessage is already a valid localization key from AuthViewModel.parseError
        // (error_no_connection, error_session_expired, error_email_exists, ...), so show it
        // directly instead of collapsing everything to "error_unknown".
        toast = Toast(message: LocalizedStringKey(errorMessage ?? "error_unknown"), type: .error)
    }

    private func validateForm() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            showErrorToast(message: "error_email_required")
            return false
        }

        guard trimmedEmail.isValidEmail else {
            showErrorToast(message: "error_invalid_email_format")
            return false
        }

        guard !trimmedPassword.isEmpty else {
            showErrorToast(message: "error_password_required")
            return false
        }

        return true
    }

    private func showErrorToast(message: String) {
        toast = Toast(message: LocalizedStringKey(message), type: .error)
        showToast = true
    }
}

/// Soft brand-tinted backdrop shared by the auth screens.
struct AuthBackground: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            LinearGradient(
                colors: [Color.brandPrimary.opacity(0.16), Color.brandSecondary.opacity(0.05), Color.clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }
}
