import SwiftUI

class GradeViewModel: ObservableObject {
    @Published var grades: [Grade] = []
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    
    // GradeViewModel.swift
    // Güncellenmiş remainingWeight fonksiyonu
    // Toplam ağırlık hesaplama (belirli bir notu hariç tutarak)
    func totalWeight(forCourse courseId: Int, excluding gradeId: Int? = nil) -> Double {
        let total = grades
            .filter { grade in
                if let excludeId = gradeId {
                    return grade.courseId == courseId && grade.id != excludeId
                }
                return grade.courseId == courseId
            }
            .reduce(0.0) { $0 + $1.weight }
        
        print("Total weight (excluding \(String(describing: gradeId))): \(total)")
        return total
    }
    
    // Kalan ağırlık hesaplama (düzenlenen notu hariç tutarak)
    func remainingWeight(forCourse courseId: Int, excludingGradeId: Int? = nil) -> Double {
        let used = totalWeight(forCourse: courseId, excluding: excludingGradeId)
        let remaining = max(0, 100.0 - used)
        return remaining
    }
    
    // Maksimum izin verilen ağırlık hesaplama
    func maxAllowedWeight(forCourse courseId: Int, currentGradeId: Int) -> Double {
        let currentGrade = grades.first { $0.id == currentGradeId }
        let currentWeight = currentGrade?.weight ?? 0.0
        let remaining = remainingWeight(forCourse: courseId, excludingGradeId: currentGradeId)
        let maxWeight = remaining + currentWeight
        
        print("Current weight: \(currentWeight)")
        print("Remaining weight: \(remaining)")
        print("Max allowed weight: \(maxWeight)")
        
        return min(100, maxWeight) // Asla 100'ü geçemez
    }
    func fetchGrades(forCourse courseId: Int) {
        networkManager.get(endpoint: "/grades/courses/\(courseId)", requiresAuth: true) { (result: Result<[Grade], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedGrades):
                    self.grades = fetchedGrades
                    self.objectWillChange.send() // ✅ SwiftUI değişikliği algılasın diye ekledik
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    func addGrade(courseId: Int, gradeType: String, score: Double, weight: Double, completion: @escaping (Result<Grade, Error>) -> Void) {
        let parameters: [String: Any] = [
            "course_id": courseId,
            "grade_type": gradeType,
            "score": score,
            "weight": weight
        ]
        
        networkManager.post(endpoint: "/grades", parameters: parameters, requiresAuth: true) { (result: Result<Grade, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let newGrade):
                    self.grades.append(newGrade)
                    self.fetchGrades(forCourse: courseId) // ✅ Not eklendikten sonra notları güncelle
                    completion(.success(newGrade))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    func totalWeight(forCourse courseId: Int) -> Double {
        return grades.filter { $0.courseId == courseId }.reduce(0) { $0 + $1.weight }
    }
    // MARK: - Average Calculation
    func calculateAverage() -> Double {
        guard !grades.isEmpty else { return 0.0 }
        
        var totalWeightedScore = 0.0
        var totalWeight = 0.0
        
        for grade in grades {
            totalWeightedScore += grade.score * (grade.weight / 100.0)
            totalWeight += grade.weight
        }
        
        // Ağırlıkları normalize et
        if totalWeight > 0 {
            let normalizedAverage = totalWeightedScore * (100.0 / totalWeight)
            print("📊 Calculated Average: \(normalizedAverage) (Total Weight: \(totalWeight))")
            return normalizedAverage
        }
        
        return 0.0
    }
    
    // MARK: - Update Course Average
    func updateCourseAverage(courseId: Int) {
        let average = calculateAverage()
        print("📝 Updating course \(courseId) average to: \(average)")
        
        let parameters: [String: Any] = ["average": average]
        
        networkManager.put(
            endpoint: "/courses/\(courseId)/average",
            parameters: parameters,
            requiresAuth: true
        ) { (result: Result<Course, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let course):
                    print("✅ Course average updated successfully: \(course.average)")
                    // Bildirim gönder
                    NotificationCenter.default.post(
                        name: Notification.Name("CourseAverageUpdated"),
                        object: nil,
                        userInfo: ["courseId": courseId, "average": average]
                    )
                case .failure(let error):
                    print("❌ Failed to update course average: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Delete Grade
    func deleteGrade(gradeId: Int, courseId: Int) {
        print("🗑 Deleting grade with ID: \(gradeId)")
        
        // Önce local listeden kaldır (UI'ı hemen güncelle)
        grades.removeAll { $0.id == gradeId }
        
        networkManager.delete(
            endpoint: "/grades/\(gradeId)",
            requiresAuth: true
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Grade deleted successfully")
                    // Başarılı silme durumunda tekrar fetch yapmaya gerek yok
                    // Grade zaten local listeden kaldırıldı
                    if let average = self?.calculateAverage() {
                        self?.updateCourseAverage(courseId: courseId)
                    }
                case .failure(let error):
                    print("❌ Failed to delete grade:", error)
                    self?.errorMessage = error.localizedDescription
                    // Silme başarısız olduysa notları tekrar getir
                    self?.fetchGrades(forCourse: courseId)
                }
            }
        }
    }
    
    // MARK: - Update Grade
    func updateGrade(
        gradeId: Int,
        courseId: Int,
        gradeType: String,
        score: Double,
        weight: Double,
        completion: @escaping (Result<Grade, Error>) -> Void
    ) {
        let parameters: [String: Any] = [
            "grade_type": gradeType,
            "score": score,
            "weight": weight
        ]
        
        print("📝 Updating grade with parameters:", parameters)
        
        networkManager.put(
            endpoint: "/grades/\(gradeId)",
            parameters: parameters,
            requiresAuth: true
        ) { [weak self] (result: Result<Grade, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedGrade):
                    print("✅ Grade updated successfully")
                    // Güncellenmiş notu listede güncelle
                    if let index = self?.grades.firstIndex(where: { $0.id == gradeId }) {
                        self?.grades[index] = updatedGrade
                    }
                    // Ortalamayı güncelle
                    if let average = self?.calculateAverage() {
                        self?.updateCourseAverage(courseId: courseId)
                    }
                    completion(.success(updatedGrade))
                    
                case .failure(let error):
                    print("❌ Failed to update grade:", error)
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Validation Methods
    func validateWeight(forCourse courseId: Int, newWeight: Double, excludingGradeId: Int? = nil) -> Bool {
        let currentTotalWeight = grades
            .filter { $0.courseId == courseId && $0.id != excludingGradeId }
            .reduce(0.0) { $0 + $1.weight }
        
        return (currentTotalWeight + newWeight) <= 100.0
    }
    
    
}
