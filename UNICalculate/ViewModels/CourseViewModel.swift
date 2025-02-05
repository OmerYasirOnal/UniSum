import Foundation

// MARK: - CourseViewModel
class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Fetch Courses
    func fetchCourses(for termId: Int) {
        isLoading = true
        print("📡 Fetching courses for term: \(termId)")
        
        networkManager.get(
            endpoint: "/terms/\(termId)/courses",
            requiresAuth: true
        ) { [weak self] (result: Result<[Course], Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let courses):
                    print("✅ Found \(courses.count) courses")
                    self?.courses = courses
                    self?.errorMessage = ""
                case .failure(let error):
                    print("❌ Error fetching courses:", error)
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
        
        print("📤 Adding course:", parameters)
        
        networkManager.post(
            endpoint: "/terms/\(termId)/courses",
            parameters: parameters,
            requiresAuth: true
        ) { [weak self] (result: Result<Course, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let newCourse):
                    print("✅ Course added:", newCourse)
                    self?.courses.append(newCourse)
                    completion(true)
                case .failure(let error):
                    print("❌ Failed to add course:", error)
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Delete Course
    func deleteCourse(courseId: Int, completion: @escaping (Bool) -> Void) {
        print("🗑 Deleting course: \(courseId)")
        
        networkManager.delete(
            endpoint: "/courses/\(courseId)",
            requiresAuth: true
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Course deleted successfully")
                    self?.courses.removeAll { $0.id == courseId }
                    self?.errorMessage = ""
                    completion(true)
                case .failure(let error):
                    print("❌ Failed to delete course:", error)
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}

