import SwiftUI
import Foundation

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var university = ""
    @State private var department = ""
    @State private var isLoading = false
    @State private var showToast = false
    @State private var toast: Toast?
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, university, department
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuthBackground()

                ScrollView {
                    VStack(spacing: DS.Spacing.lg) {
                        AppLogoMark(size: 60)
                            .padding(.top, DS.Spacing.md)

                        Text(LocalizedStringKey("create_account"))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)

                        formCard
                        signupButton

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
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .university }
            }

            IconTextField(systemImage: "building.columns", isFocused: focusedField == .university) {
                TextField(LocalizedStringKey("university"), text: $university)
                    .textContentType(.organizationName)
                    .focused($focusedField, equals: .university)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .department }
            }

            IconTextField(systemImage: "book", isFocused: focusedField == .department) {
                TextField(LocalizedStringKey("department"), text: $department)
                    .focused($focusedField, equals: .department)
                    .submitLabel(.done)
            }
        }
        .padding(.top, DS.Spacing.xs)
    }

    private var signupButton: some View {
        Button(action: handleSignup) {
            HStack(spacing: DS.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(LocalizedStringKey("signup"))
            }
        }
        .buttonStyle(PrimaryButtonStyle(enabled: isFormValid() && !isLoading))
        .disabled(!isFormValid() || isLoading)
        .opacity(isFormValid() && !isLoading ? 1 : 0.7)
        .padding(.top, DS.Spacing.xs)
    }

    private func isFormValid() -> Bool {
        return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !university.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleSignup() {
        guard validateForm() else { return }

        isLoading = true
        authViewModel.signup(
            email: email,
            password: password,
            university: university,
            department: department
        ) { success, messageKey in
            isLoading = false
            if success {
                toast = Toast(message: LocalizedStringKey(messageKey ?? "verification_email_sent"), type: .success)
                showToast = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            } else {
                toast = Toast(message: LocalizedStringKey(messageKey ?? "error_unknown"), type: .error)
                showToast = true
            }
        }
    }

    private func validateForm() -> Bool {
        let trimmedEmail = email.trimmed
        let trimmedPassword = password.trimmed

        if !trimmedEmail.isNotEmpty {
            toast = Toast(message: LocalizedStringKey("error_email_required"), type: .error)
            showToast = true
            return false
        }

        if !trimmedEmail.isValidEmail {
            toast = Toast(message: LocalizedStringKey("error_invalid_email_format"), type: .error)
            showToast = true
            return false
        }

        if !trimmedPassword.isNotEmpty {
            toast = Toast(message: LocalizedStringKey("error_password_required"), type: .error)
            showToast = true
            return false
        }

        if !trimmedPassword.isValidPassword {
            toast = Toast(message: LocalizedStringKey("error_password_too_short"), type: .error)
            showToast = true
            return false
        }

        return true
    }
}

extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    var isNotEmpty: Bool {
        !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isValidPassword: Bool {
        count >= 6
    }

    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct SignupResponse: Codable {
    let success: Bool
    let message: String
    let verificationLink: String?
}
