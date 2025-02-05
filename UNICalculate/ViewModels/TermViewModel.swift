import Foundation

class TermViewModel: ObservableObject {
    // MARK: - Properties
    @Published var terms: [Term] = []
    @Published var errorMessage: String = ""
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Term Operations
    func fetchTerms() {
        isLoading = true
        print("🔄 Dönemler getiriliyor...")
        
        networkManager.get(endpoint: "/terms/my-terms", requiresAuth: true) { [weak self] (result: Result<[Term], Error>) in
            DispatchQueue.main.async {
                self?.handleFetchTermsResponse(result)
            }
        }
    }
    
    func addTerm(classLevel: String, termNumber: Int) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            self.errorMessage = "Kullanıcı kimliği bulunamadı"
            return
        }
        
        let parameters: [String: Any] = [
            "user_id": userId,
            "class_level": classLevel,
            "term_number": termNumber
        ]
        
        print("📤 Dönem ekleniyor:", parameters)
        
        networkManager.post(endpoint: "/terms", parameters: parameters, requiresAuth: true) { [weak self] (result: Result<Term, Error>) in
            DispatchQueue.main.async {
                self?.handleAddTermResponse(result)
            }
        }
    }
    
    func deleteTerm(termId: Int, completion: @escaping (Bool) -> Void) {
        print("🗑 Dönem siliniyor: \(termId)")
        
        networkManager.delete(endpoint: "/terms/\(termId)", requiresAuth: true) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleDeleteTermResponse(result, termId: termId, completion: completion)
            }
        }
    }
    
    // MARK: - Response Handlers
    private func handleFetchTermsResponse(_ result: Result<[Term], Error>) {
        isLoading = false
        
        switch result {
        case .success(let terms):
            print("✅ Dönemler başarıyla getirildi")
            self.terms = terms
            self.errorMessage = ""
            
        case .failure(let error):
            print("❌ Dönem getirme hatası:", error.localizedDescription)
            handleError(error)
        }
    }
    
    private func handleAddTermResponse(_ result: Result<Term, Error>) {
        switch result {
        case .success(let newTerm):
            print("✅ Dönem başarıyla eklendi:", newTerm)
            fetchTerms()
            errorMessage = ""
            
        case .failure(let error):
            print("❌ Dönem ekleme hatası:", error.localizedDescription)
            handleError(error)
        }
    }
    
    private func handleDeleteTermResponse(_ result: Result<Void, Error>, termId: Int, completion: @escaping (Bool) -> Void) {
        switch result {
        case .success:
            print("✅ Dönem başarıyla silindi")
            terms.removeAll { $0.id == termId }
            errorMessage = ""
            completion(true)
            
        case .failure(let error):
            print("❌ Dönem silme hatası:", error.localizedDescription)
            handleError(error)
            fetchTerms()
            completion(false)
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                errorMessage = "Oturum süresi doldu. Lütfen tekrar giriş yapın."
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
