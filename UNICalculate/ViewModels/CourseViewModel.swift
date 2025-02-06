import Foundation

class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    
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
