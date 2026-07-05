import SwiftUI
import Foundation

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var university = ""
    @State private var department = ""
    @State private var city = ""
    @State private var country = "Türkiye"
    @State private var isLoading = false
    @State private var showToast = false
    @State private var toast: Toast?
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ZStack {
                AuthBackground()

                ScrollView {
                    VStack(spacing: DS.Spacing.lg) {
                        AppLogoMark(size: 56)
                            .padding(.top, DS.Spacing.sm)
                        Text(LocalizedStringKey("create_account"))
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
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
                    .submitLabel(.done)
            }
            SearchablePicker(placeholder: "country", systemImage: "globe", options: SignupData.countries, selection: $country)
            SearchablePicker(placeholder: "city", systemImage: "mappin.and.ellipse", options: SignupData.cities, selection: $city)
            SearchablePicker(placeholder: "university", systemImage: "building.columns", options: SignupData.universities, selection: $university)
            SearchablePicker(placeholder: "department", systemImage: "book", options: SignupData.departments, selection: $department)
        }
        .padding(.top, DS.Spacing.xs)
    }

    private var signupButton: some View {
        Button(action: handleSignup) {
            HStack(spacing: DS.Spacing.xs) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
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
        !email.trimmed.isEmpty && !password.trimmed.isEmpty &&
        !university.isEmpty && !department.isEmpty && !city.isEmpty && !country.isEmpty
    }

    private func handleSignup() {
        guard validateForm() else { return }
        isLoading = true
        authViewModel.signup(
            email: email.trimmed,
            password: password,
            university: university,
            department: department,
            city: city,
            country: country
        ) { success, messageKey in
            isLoading = false
            if success {
                toast = Toast(message: LocalizedStringKey("signup_success_verify"), type: .success)
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { dismiss() }
            } else {
                toast = Toast(message: LocalizedStringKey(messageKey ?? "error_unknown"), type: .error)
                showToast = true
            }
        }
    }

    private func validateForm() -> Bool {
        func fail(_ key: String) { toast = Toast(message: LocalizedStringKey(key), type: .error); showToast = true }
        if !email.trimmed.isNotEmpty { fail("error_email_required"); return false }
        if !email.trimmed.isValidEmail { fail("error_invalid_email_format"); return false }
        if !password.trimmed.isNotEmpty { fail("error_password_required"); return false }
        if !password.trimmed.isValidPassword { fail("error_password_too_short"); return false }
        if country.isEmpty { fail("error_country_required"); return false }
        if city.isEmpty { fail("error_city_required"); return false }
        if university.isEmpty { fail("error_university_required"); return false }
        if department.isEmpty { fail("error_department_required"); return false }
        return true
    }
}

extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    var isNotEmpty: Bool { !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var isValidPassword: Bool { count >= 6 }
    var trimmed: String { self.trimmingCharacters(in: .whitespacesAndNewlines) }
}

struct SignupResponse: Codable {
    let success: Bool
    let message: String
    let verificationLink: String?
}
