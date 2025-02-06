import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var navigateToSignup = false
    @FocusState private var focusedField: Field?
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var languageManager: LanguageManager
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        languageToggleButton
                    }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            Spacer(minLength: 50)
                            welcomeView
                            formView
                            loginButton
                            signupPrompt
                            Spacer(minLength: 20)
                            footerView
                        }
                        .padding(.bottom, keyboardHeight)
                    }
                    .onTapGesture { focusedField = nil }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $navigateToSignup) {
                SignupView(authViewModel: authViewModel)
            }
        }
        .onAppear(perform: setupKeyboardNotifications)
        .onDisappear(perform: removeKeyboardNotifications)
    }
    
    private var languageToggleButton: some View {
        Menu {
            Button(action: { languageManager.selectedLanguage = "tr" }) {
                HStack {
                    Text("Türkçe")
                    if languageManager.selectedLanguage == "tr" {
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
            }
            
            Button(action: { languageManager.selectedLanguage = "en" }) {
                HStack {
                    Text("English")
                    if languageManager.selectedLanguage == "en" {
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
            }
        } label: {
            HStack {
                Text(languageManager.displayText)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.2)))
            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
        }
        .foregroundColor(.white)
        .padding(.top, 50)
        .padding(.trailing, 20)
    }
    
    // MARK: - UI Components
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var welcomeView: some View {
        Text(LocalizedStringKey("welcome_back"))
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
    
    private var formView: some View {
        VStack(spacing: 15) {
            TextField(LocalizedStringKey("email"), text: $email)
                .customTextField()
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .focused($focusedField, equals: .email)
                .frame(minHeight: 50)
            
            SecureField(LocalizedStringKey("password"), text: $password)
                .customTextField()
                .focused($focusedField, equals: .password)
                .frame(minHeight: 50)
        }
        .padding(.horizontal, 30)
    }
    
    private var loginButton: some View {
        Button(action: handleLogin) {
            Text(LocalizedStringKey("login"))
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .shadow(radius: 5)
        }
        .padding(.horizontal, 30)
        .disabled(!isFormValid())
    }
    
    private var signupPrompt: some View {
        HStack {
            Text(LocalizedStringKey("no_account"))
            Button(action: { navigateToSignup = true }) {
                Text(LocalizedStringKey("signup"))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var footerView: some View {
        Text("© 2024 UniCalculate")
            .font(.footnote)
            .foregroundColor(.white.opacity(0.7))
            .padding(.bottom, 20)
    }
    
    // MARK: - Helper Functions
    private func isFormValid() -> Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleLogin() {
        if validateForm() {
            authViewModel.login(email: email, password: password)
        }
        focusedField = nil
    }
    
    private func validateForm() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            authViewModel.errorMessageKey = "error_email_required"
            return false
        }
        
        if !trimmedEmail.isValidEmail {
            authViewModel.errorMessageKey = "error_invalid_email_format"
            return false
        }
        
        if trimmedPassword.isEmpty {
            authViewModel.errorMessageKey = "error_password_required"
            return false
        }
        
        return true
    }
    
    // MARK: - Keyboard Management
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardHeight = 0
        }
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Email Validation Extension
extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}
