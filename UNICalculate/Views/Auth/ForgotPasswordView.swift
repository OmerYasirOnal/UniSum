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
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text(LocalizedStringKey("reset_password"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 50)
                        
                        Text(LocalizedStringKey("reset_password_instructions"))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        TextField(LocalizedStringKey("email"), text: $email)
                            .customTextField()
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($emailFocused)
                            .padding(.horizontal)
                        
                        resetButton
                    }
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
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var resetButton: some View {
        Button(action: handlePasswordReset) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding(.trailing, 5)
                }
                
                Text(LocalizedStringKey("reset_password"))
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(.blue)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .disabled(!isValid() || isLoading)
        .opacity(isValid() && !isLoading ? 1 : 0.6)
        .padding(.horizontal)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private func isValid() -> Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.isValidEmail
    }
    
    private func handlePasswordReset() {
        isLoading = true
        authViewModel.requestPasswordReset(email: email) { success, _ in
            isLoading = false
            if success {
                // "password_reset_email_sent" lokalizasyon anahtarının
                // Localizable.strings dosyanızda tanımlı olduğundan emin olun.
                toast = Toast(message: "password_reset_email_sent", type: .success)
                showToast = true
                // 2 saniye bekledikten sonra ForgotPasswordView kapatılarak login ekranına yönlendirilir.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }
}
