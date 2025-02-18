import SwiftUI
import Foundation

class AuthViewModel: ObservableObject {
    @Published var user: User?
        @Published var isAuthenticated = false
        private let networkManager = NetworkManager.shared
        @Published var errorMessageKey: LocalizedStringKey?
        
        init() {
            checkAuthentication()
        }
        
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let parameters = ["email": email, "password": password]
        
        networkManager.post(endpoint: "/auth/login", parameters: parameters) { (result: Result<LoginResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.user = response.user
                    self.isAuthenticated = true
                    UserDefaults.standard.set(response.token, forKey: "authToken")
                    UserDefaults.standard.set(response.user.id, forKey: "userId")
                    
                    // Kullanıcıyı JSON'a çevirip saklayın
                    if let encodedUser = try? JSONEncoder().encode(response.user) {
                        UserDefaults.standard.set(encodedUser, forKey: "currentUser")
                    }
                    completion(true, nil)
                case .failure(let error):
                    let errorMessage = self.parseError(error)
                    self.errorMessageKey = LocalizedStringKey(errorMessage)
                    completion(false, errorMessage)
                }
            }
        }
    }
        
    
    func handleTokenExpiration(_ error: Error) {
        if let networkError = error as? NetworkError, case .unauthorized = networkError {
            DispatchQueue.main.async {
                self.logout()
                self.errorMessageKey = "error_session_expired"
                NotificationCenter.default.post(name: Notification.Name("SessionExpired"), object: nil)
            }
        }
    }
    
    
    
    func signup(email: String, password: String, university: String, department: String, completion: @escaping (Bool, String?) -> Void) {
            let parameters = [
                "email": email,
                "password": password,
                "university": university,
                "department": department
            ]
            
            networkManager.post(endpoint: "/auth/signup", parameters: parameters) { (result: Result<SignupResponse, Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.success {
                            // Başarılı durumda hata mesajı set edilmez.
                            completion(true, response.message)
                        } else {
                            self.errorMessageKey = LocalizedStringKey(response.message)
                            completion(false, response.message)
                        }
                    case .failure(let error):
                        let errorMessage = self.parseError(error)
                        self.errorMessageKey = LocalizedStringKey(errorMessage)
                        completion(false, errorMessage)
                    }
                }
            }
        }
    func requestPasswordReset(email: String, completion: @escaping (Bool, String?) -> Void) {
            let parameters = ["email": email]
            
            networkManager.post(endpoint: "/auth/password-reset", parameters: parameters) { (result: Result<[String: String], Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        completion(true, nil)
                    case .failure(let error):
                        let errorMessage = self.parseError(error)
                        self.errorMessageKey = LocalizedStringKey(errorMessage)
                        completion(false, errorMessage)
                    }
                }
            }
        }
    func resetPassword(token: String, newPassword: String, completion: @escaping (Bool, String?) -> Void) {
            let parameters = [
                "token": token,
                "newPassword": newPassword
            ]
            
            networkManager.post(endpoint: "/auth/reset-password", parameters: parameters) { (result: Result<[String: String], Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let responseDict):
                        let message = responseDict["message"] ?? "password_updated_successfully"
                        completion(true, message)
                    case .failure(let error):
                        let errorMessage = self.parseError(error)
                        completion(false, errorMessage)
                    }
                }
            }
        }
    func logout() {
            UserDefaults.standard.removeObject(forKey: "authToken")
            UserDefaults.standard.removeObject(forKey: "userId")
            self.user = nil
            self.isAuthenticated = false
        }
        
    func checkAuthentication() {
        guard let _ = UserDefaults.standard.string(forKey: "authToken"),
              let _ = UserDefaults.standard.string(forKey: "userId") else {
            isAuthenticated = false
            return
        }
        
        // UserDefaults'tan kullanıcı bilgilerini geri yükle
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let savedUser = try? JSONDecoder().decode(User.self, from: userData) {
            self.user = savedUser
        }
        
        isAuthenticated = true
    }
    
    private func parseError(_ error: Error) -> String {
            if let networkError = error as? NetworkError {
                switch networkError {
                case .badResponse(401):
                    return "error_invalid_credentials"
                case .badResponse(403):
                    return "error_email_not_verified"
                case .badResponse(409):
                    return "error_email_exists"
                case .noResponse:
                    return "error_no_connection"
                case .unauthorized:
                    // .unauthorized durumunda artık "error_invalid_credentials" dönüyoruz.
                    return "error_invalid_credentials"
                default:
                    return "error_unknown"
                }
            }
            return "error_unknown"
        }
    
    private func setError(_ key: String) {
        errorMessageKey = LocalizedStringKey(key)
    }
    
}

struct LoginResponse: Codable {
    let user: User
    let token: String
}
