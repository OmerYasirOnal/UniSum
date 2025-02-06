import Foundation
import Combine

// MARK: - Response Models
struct TermGPAResponse: Codable {
    let gpa: Double
    let totalCredits: Double
    let courseDetails: [CourseGPADetail]
}

struct CourseGPADetail: Codable {
    let courseId: Int
    let credits: Double
    let average: Double
    let gpa: Double
}

class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    
    // Add properties for termAverageSection
    @Published var termGPA: Double = 0.0
    @Published var totalCredits: Double = 0.0
    @Published var isLoadingGPA = false
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Fetch Courses
    func fetchCourses(for termId: Int) {
        isLoading = true
        
        networkManager.get(
            endpoint: "/terms/\(termId)/courses",
            requiresAuth: true
        ) { [weak self] (result: Result<[Course], Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let courses):
                    self?.courses = courses
                    self?.errorMessage = ""
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Fetch Term GPA
    func fetchTermGPA(for termId: Int) {
        isLoadingGPA = true
        
        networkManager.get(
            endpoint: "/gpa/terms/\(termId)",
            requiresAuth: true
        ) { [weak self] (result: Result<TermGPAResponse, Error>) in
            DispatchQueue.main.async {
                self?.isLoadingGPA = false
                
                switch result {
                case .success(let response):
                    self?.termGPA = response.gpa
                    self?.totalCredits = response.totalCredits
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Add Course
    func addCourse(termId: Int, userId: Int, name: String, credits: Double, completion: @escaping (Bool) -> Void) {
        let parameters: [String: Any] = [
            "term_id": termId,
            "user_id": userId,
            "name": name,
            "credits": credits
        ]
        
        networkManager.post(
            endpoint: "/terms/\(termId)/courses",
            parameters: parameters,
            requiresAuth: true
        ) { [weak self] (result: Result<Course, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let newCourse):
                    self?.courses.append(newCourse)
                    // Fetch updated GPA after adding a course
                    if let termId = self?.courses.first?.termId {
                        self?.fetchTermGPA(for: termId)
                    }
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Delete Course
    func deleteCourse(courseId: Int, completion: @escaping (Bool) -> Void) {
        networkManager.delete(
            endpoint: "/courses/\(courseId)",
            requiresAuth: true
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.courses.removeAll { $0.id == courseId }
                    // Fetch updated GPA after deleting a course
                    if let termId = self?.courses.first?.termId {
                        self?.fetchTermGPA(for: termId)
                    }
                    self?.errorMessage = ""
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}
