import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    private let networkManager = NetworkManager.shared
    @Published var errorMessageKey: LocalizedStringKey? // String yerine LocalizedStringKey kullanıyoruz
    
    init() {
        checkAuthentication()
    }
    // Token süre kontrolü ve logout işlemi için yeni metod
    func handleTokenExpiration(_ error: Error) {
        if let networkError = error as? NetworkError,
           case .unauthorized = networkError {
            DispatchQueue.main.async {
                // Token süresi dolmuşsa logout yap
                self.logout()
                self.errorMessageKey = "error_session_expired"
                // Kullanıcıya bildirim göster
                NotificationCenter.default.post(
                    name: Notification.Name("SessionExpired"),
                    object: nil
                )
            }
        }
    }
    func login(email: String, password: String) {
        let parameters = ["email": email, "password": password]
        
        networkManager.post(endpoint: "/auth/login", parameters: parameters) { (result: Result<LoginResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.user = response.user
                    self.isAuthenticated = true
                    UserDefaults.standard.set(response.token, forKey: "authToken")
                    UserDefaults.standard.set(response.user.id, forKey: "userId")
                    self.errorMessageKey = nil
                case .failure(let error):
                    // Hata türüne göre uygun mesaj anahtarını seç
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .badResponse(401):
                            self.errorMessageKey = "error_invalid_credentials"
                        case .noResponse:
                            self.errorMessageKey = "error_no_connection"
                        case .unauthorized:
                            self.errorMessageKey = "error_session_expired"
                        default:
                            self.errorMessageKey = "error_unknown"
                        }
                    } else {
                        self.errorMessageKey = "error_unknown"
                    }
                }
            }
        }
    }
    
    func signup(email: String, password: String, university: String, department: String) {
        let parameters = ["email": email, "password": password, "university": university, "department": department]
        
        networkManager.post(endpoint: "/auth/signup", parameters: parameters) { (result: Result<User, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self.user = user
                    self.isAuthenticated = true
                    self.login(email: email, password: password)
                    self.errorMessageKey = nil
                case .failure(let error):
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .badResponse(409):
                            self.errorMessageKey = "error_email_exists"
                        case .noResponse:
                            self.errorMessageKey = "error_no_connection"
                        case .invalidParameters:
                            self.errorMessageKey = "error_invalid_input"
                        default:
                            self.errorMessageKey = "error_unknown"
                        }
                    } else {
                        self.errorMessageKey = "error_unknown"
                    }
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
    
    // AuthViewModel.swift
    func checkAuthentication() {
        guard let token = UserDefaults.standard.string(forKey: "authToken"),
              let _ = UserDefaults.standard.string(forKey: "userId") else {
            isAuthenticated = false
            return
        }
        print("✅ Kullanıcı oturum açık. Token:", token)
        // Token geçerliliğini API ile kontrol edebilirsiniz (opsiyonel)
        isAuthenticated = true
    }
}

struct LoginResponse: Codable {
    let user: User
    let token: String
}
