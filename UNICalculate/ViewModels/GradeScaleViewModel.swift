import SwiftUI

class GradeScaleViewModel: ObservableObject {
    // MARK: - Properties
    @Published var currentGrade: String = "N/A"
    @Published var currentGPA: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var gradeScales: [GradeScale] = [] {
        didSet {
            // GradeScales her değiştiğinde notu tekrar hesapla
            calculateCurrentGrade(average: course.average)
        }
    }
    private let networkManager = NetworkManager.shared
    private let course: Course
    
    
    // MARK: - Initialization
    init(course: Course) {
        self.course = course
        loadInitialData()
    }
    
    // MARK: - Public Methods
    func loadInitialData() {
        // Önce varsayılan değerleri yükle
        self.gradeScales = GradeScale.getDefaultScales(for: course.id)
        
        // Custom scale'leri getir
        fetchCustomScales()
        
        // Mevcut ortalamaya göre notu hesapla
        calculateCurrentGrade(average: course.average)
    }
    
    private func updateWithCustomScales(_ customScales: [GradeScale]) {
        var updatedScales = self.gradeScales
        
        for customScale in customScales {
            if let index = updatedScales.firstIndex(where: { $0.letter == customScale.letter }) {
                updatedScales[index] = customScale
            }
        }
        
        self.gradeScales = updatedScales
        // Notu tekrar hesapla
        calculateCurrentGrade(average: course.average)
    }
    func saveGradeScales() {
        let modifiedScales = gradeScales.filter { $0.isDifferentFromDefault() }
        let scalesToSave = modifiedScales.map { scale -> [String: Any] in
            [
                "letter": scale.letter,
                "min_score": scale.minScore,
                "gpa": scale.gpa,
                "is_custom": true
            ]
        }
        
        networkManager.post(
            endpoint: "/api/grade-scales/courses/\(course.id)",
            parameters: ["gradeScales": scalesToSave],
            requiresAuth: true
        ) { [weak self] (result: Result<[GradeScale], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Başarılı kayıt sonrası skalaları yeniden yükle
                    self?.loadInitialData()
                    // Notu tekrar hesapla
                    if let average = self?.course.average {
                        self?.calculateCurrentGrade(average: average)
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func calculateCurrentGrade(average: Double?) {
        guard let avg = average else {
            currentGrade = "N/A"
            currentGPA = 0.0
            return
        }
        
        // Skalaları min_score'a göre büyükten küçüğe sırala
        let sortedScales = gradeScales.sorted { $0.minScore > $1.minScore }
        
        // İlk eşleşen skalayı bul
        if let gradeScale = sortedScales.first(where: { Double($0.minScore) <= avg }) {
            currentGrade = gradeScale.letter
            currentGPA = gradeScale.gpa
            print("📊 Calculated grade for average \(avg): \(gradeScale.letter) (GPA: \(gradeScale.gpa))")
        } else if let lowestGrade = sortedScales.last {
            currentGrade = lowestGrade.letter
            currentGPA = lowestGrade.gpa
            print("📊 Using lowest grade for average \(avg): \(lowestGrade.letter) (GPA: \(lowestGrade.gpa))")
        } else {
            currentGrade = "N/A"
            currentGPA = 0.0
            print("⚠️ No grade scale found for average \(avg)")
        }
    }
    
    func resetToDefaultScales() {
        gradeScales = GradeScale.getDefaultScales(for: course.id)
        // Veritabanındaki özel skalaları sil
        networkManager.delete(
            endpoint: "/api/grade-scales/courses/\(course.id)",
            requiresAuth: true
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.loadInitialData()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func fetchCustomScales() {
        isLoading = true // Yükleme durumunu göster
        
        networkManager.get(
            endpoint: "/api/grade-scales/courses/\(course.id)",
            requiresAuth: true
        ) { [weak self] (result: Result<[GradeScale], Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false // Yükleme durumunu gizle
                switch result {
                case .success(let customScales):
                    print("📊 Received \(customScales.count) custom scales")
                    self?.updateWithCustomScales(customScales)
                case .failure(let error):
                    print("❌ Failed to fetch custom scales:", error)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func hasCustomChanges() -> Bool {
        let defaultScales = GradeScale.getDefaultScales(for: course.id)
        return gradeScales.contains { currentScale in
            guard let defaultScale = defaultScales.first(where: { $0.letter == currentScale.letter }) else {
                return true
            }
            return currentScale.minScore != defaultScale.minScore ||
            abs(currentScale.gpa - defaultScale.gpa) > 0.001
        }
    }
    
    
    
    private func deleteCustomScales() {
        networkManager.delete(
            endpoint: "/api/grade-scales/courses/\(course.id)",
            requiresAuth: true
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleDeleteResponse(result)
            }
        }
    }
    
    // MARK: - Response Handlers
    private func handleFetchResponse(_ result: Result<[GradeScale], Error>) {
        isLoading = false
        switch result {
        case .success(let customScales):
            if !customScales.isEmpty {
                updateWithCustomScales(customScales)
            }
            calculateCurrentGrade(average: course.average)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleSaveResponse(_ result: Result<[GradeScale], Error>) {
        switch result {
        case .success(let savedScales):
            updateWithCustomScales(savedScales)
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleDeleteResponse(_ result: Result<Void, Error>) {
        switch result {
        case .success:
            gradeScales = GradeScale.getDefaultScales(for: course.id)
            calculateCurrentGrade(average: course.average)
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
