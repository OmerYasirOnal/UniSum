import SwiftUI

class GradeScaleViewModel: ObservableObject {
    // MARK: - Properties
    @Published var currentGrade: String = "N/A"
    @Published var currentGPA: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var gradeScales: [GradeScale] = [] {
        didSet {
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
        self.gradeScales = GradeScale.getDefaultScales(for: course.id)
        fetchCustomScales()
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
                case .success:
                    self?.loadInitialData()
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
        
        let sortedScales = gradeScales.sorted { $0.minScore > $1.minScore }
        
        if let gradeScale = sortedScales.first(where: { Double($0.minScore) <= avg }) {
            currentGrade = gradeScale.letter
            currentGPA = gradeScale.gpa
        } else if let lowestGrade = sortedScales.last {
            currentGrade = lowestGrade.letter
            currentGPA = lowestGrade.gpa
        } else {
            currentGrade = "N/A"
            currentGPA = 0.0
        }
    }
    
    func resetToDefaultScales() {
        gradeScales = GradeScale.getDefaultScales(for: course.id)
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
    private func updateWithCustomScales(_ customScales: [GradeScale]) {
        var updatedScales = self.gradeScales
        
        for customScale in customScales {
            if let index = updatedScales.firstIndex(where: { $0.letter == customScale.letter }) {
                updatedScales[index] = customScale
            }
        }
        
        self.gradeScales = updatedScales
        calculateCurrentGrade(average: course.average)
    }
    
    private func fetchCustomScales() {
        isLoading = true
        
        networkManager.get(
            endpoint: "/api/grade-scales/courses/\(course.id)",
            requiresAuth: true
        ) { [weak self] (result: Result<[GradeScale], Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let customScales):
                    self?.updateWithCustomScales(customScales)
                case .failure(let error):
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
}
