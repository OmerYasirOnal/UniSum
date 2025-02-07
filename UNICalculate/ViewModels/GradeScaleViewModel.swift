import SwiftUI

import SwiftUI

class GradeScaleViewModel: ObservableObject {
    @Published var course: Course
    @Published var gradeScales: [GradeScale] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentGrade: String = "N/A"
        @Published var currentGPA: Double = 0.0
    private let networkManager = NetworkManager.shared
    
    init(course: Course) {
        self.course = course
        loadInitialData()
    }
    
    // ✅ İlk açılışta default skalaları yükle
    func loadInitialData() {
        self.gradeScales = GradeScale.getDefaultScales(for: course.id)
        fetchCustomScales()
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

    // ✅ Backend’den custom scale’leri çek
    private func fetchCustomScales() {
        isLoading = true
        
        networkManager.get(
            endpoint: "/grade-scales/courses/\(course.id)",
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
    
    // ✅ Eğer custom skala varsa, default skalayı override et
    private func updateWithCustomScales(_ customScales: [GradeScale]) {
        var updatedScales = self.gradeScales
        
        for customScale in customScales {
            if let index = updatedScales.firstIndex(where: { $0.letter == customScale.letter }) {
                updatedScales[index] = customScale
            }
        }
        
        self.gradeScales = updatedScales
    }
    
    // ✅ Kullanıcı güncelleyince backend’e kaydet ve GPA güncelle
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
                endpoint: "/grade-scales/courses/\(course.id)",
                parameters: ["gradeScales": scalesToSave],
                requiresAuth: true
            ) { [weak self] (result: Result<[GradeScale], Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.loadInitialData()
                        self?.updateCourseGPA() // ✅ Dersin GPA’sini güncelle
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }



    // ✅ GPA’yı backend’e kaydet
    private func updateCourseGPA() {
        networkManager.put(
            endpoint: "/courses/\(course.id)/updateGPA",
            parameters: [:],
            requiresAuth: true
        ) { [weak self] (result: Result<Course, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedCourse):
                    self?.course = updatedCourse
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

