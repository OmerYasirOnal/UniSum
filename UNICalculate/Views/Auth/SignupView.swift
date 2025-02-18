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
                Color(.systemBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        formView
                        signupButton
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.immediately)
                
                if showToast, let toast = toast {
                    ToastView(toast: toast, isPresented: $showToast)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(LocalizedStringKey("back"))
                        }
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        Text(LocalizedStringKey("create_account"))
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.top, 50)
    }
    
    private var formView: some View {
        VStack(spacing: 15) {
            TextField(LocalizedStringKey("email"), text: $email)
                .customTextField()
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .focused($focusedField, equals: .email)
            
            SecureField(LocalizedStringKey("password"), text: $password)
                .customTextField()
                .textContentType(.newPassword)
                .focused($focusedField, equals: .password)
            
            TextField(LocalizedStringKey("university"), text: $university)
                .customTextField()
                .textContentType(.organizationName)
                .focused($focusedField, equals: .university)
            
            TextField(LocalizedStringKey("department"), text: $department)
                .customTextField()
                .textContentType(.none)
                .focused($focusedField, equals: .department)
        }
        .padding(.top, 20)
    }
    
    private var signupButton: some View {
        Button(action: handleSignup) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 5)
                }
                
                Text(LocalizedStringKey("signup"))
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .disabled(!isFormValid() || isLoading)
        .opacity(isFormValid() && !isLoading ? 1 : 0.6)
        .padding(.top, 20)
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
                
                // 2 saniye sonra Login ekranına yönlendirme
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
