import SwiftUI

struct SignupView: View {
    // MARK: - Properties
    @State private var email = ""
    @State private var password = ""
    @State private var university = ""
    @State private var department = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var isLoading = false
    @FocusState private var focusedField: Field?
    @StateObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    enum Field {
        case email, password, university, department
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        formView
                        signupButton
                        Spacer(minLength: 20)
                    }
                    .padding(.bottom, keyboardHeight)
                }
                .onTapGesture { focusedField = nil }
            }
            .navigationBarItems(leading: backButton)
            .navigationBarBackButtonHidden(true)
        }
        .onAppear(perform: setupKeyboardNotifications)
        .onDisappear(perform: removeKeyboardNotifications)
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
    
    private var backButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            HStack {
                Image(systemName: "chevron.left")
                Text(LocalizedStringKey("back"))
            }
            .foregroundColor(.white)
        }
    }
    
    private var headerView: some View {
        Text(LocalizedStringKey("create_account"))
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top, 50)
    }
    
    private var formView: some View {
        VStack(spacing: 20) {
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
            
            TextField(LocalizedStringKey("university"), text: $university)
                .customTextField()
                .focused($focusedField, equals: .university)
                .frame(minHeight: 50)
            
            TextField(LocalizedStringKey("department"), text: $department)
                .customTextField()
                .focused($focusedField, equals: .department)
                .frame(minHeight: 50)
            
            if let errorMessageKey = authViewModel.errorMessageKey {
                Text(errorMessageKey)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
            }
        }
        .padding(.horizontal, 30)
    }
    
    private var signupButton: some View {
        Button(action: handleSignup) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(LocalizedStringKey("signup"))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 20)
        .disabled(!isFormValid())
    }
    
    // MARK: - Helper Functions
    private func isFormValid() -> Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !university.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleSignup() {
        if validateForm() {
            isLoading = true
            authViewModel.signup(
                email: email,
                password: password,
                university: university,
                department: department
            )
            focusedField = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func validateForm() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUniversity = university.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDepartment = department.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        
        if trimmedPassword.count < 6 {
            authViewModel.errorMessageKey = "error_password_too_short"
            return false
        }
        
        if trimmedUniversity.isEmpty {
            authViewModel.errorMessageKey = "error_university_required"
            return false
        }
        
        if trimmedDepartment.isEmpty {
            authViewModel.errorMessageKey = "error_department_required"
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
