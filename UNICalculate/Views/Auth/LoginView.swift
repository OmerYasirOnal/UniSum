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
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Dil seçici üst toolbar
                    HStack {
                        Spacer()
                        languageSelector
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Ana içerik
                    welcomeView
                    formView
                    forgotPasswordButton
                    loginButton
                    signupPrompt
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Toast mesajı
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
        .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
            TermListView()
        }
    }
    
    // Dil seçici component
    private var languageSelector: some View {
        Menu {
            Button(action: { languageManager.selectedLanguage = "tr" }) {
                HStack {
                    Text("Türkçe")
                    if languageManager.selectedLanguage == "tr" {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: { languageManager.selectedLanguage = "en" }) {
                HStack {
                    Text("English")
                    if languageManager.selectedLanguage == "en" {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                Text(LocalizedStringKey("language"))
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.15))
            .foregroundColor(.blue)
            .cornerRadius(20)
        }
    }

    // Diğer componentler aynı kalıyor
    private var welcomeView: some View {
        Text(LocalizedStringKey("welcome_back"))
            .font(.system(size: 32, weight: .bold))
            .padding(.bottom, 20)
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
                .textContentType(.password)
                .focused($focusedField, equals: .password)
        }
    }
    
    private var forgotPasswordButton: some View {
        Button(action: { showForgotPassword = true }) {
            Text(LocalizedStringKey("forgot_password"))
                .foregroundColor(.blue)
                .font(.subheadline)
        }
    }
    
    private var loginButton: some View {
        Button(action: handleLogin) {
            Text(LocalizedStringKey("login"))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 2)
        }
    }
    
    private var signupPrompt: some View {
        HStack {
            Text(LocalizedStringKey("no_account"))
            Button(action: { showSignup = true }) {
                Text(LocalizedStringKey("signup"))
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, 10)
    }
    
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
        if let errorMessage = errorMessage {
            switch errorMessage {
            case "error_email_not_verified":
                toast = Toast(message: LocalizedStringKey("error_email_not_verified"), type: .error)
            case "error_invalid_credentials":
                toast = Toast(message: LocalizedStringKey("error_invalid_credentials"), type: .error)
            default:
                toast = Toast(message: LocalizedStringKey("error_unknown"), type: .error)
            }
        } else {
            toast = Toast(message: LocalizedStringKey("error_unknown"), type: .error)
        }
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


