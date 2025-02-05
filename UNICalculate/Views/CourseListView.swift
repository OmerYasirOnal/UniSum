import SwiftUI

struct CourseListView: View {
    @StateObject private var viewModel = CourseViewModel()
    let term: Term
    @State private var selectedCourse: Course? = nil  // Add this line
    @State private var isAddCourseViewVisible = false
    @State private var isEditing = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
           ZStack {
               mainContent
               
               if isAddCourseViewVisible {
                   AddCourseView(
                       isPresented: $isAddCourseViewVisible,
                       selectedCourse: $selectedCourse,  // Sırası değiştirildi
                       courseViewModel: viewModel,
                       termId: term.id,
                       userId: term.userId
                   )
                   .transition(.scale)
               }
           }
           .navigationTitle("Dersler")
           .navigationBarTitleDisplayMode(.inline)
           .toolbar { toolbarContent }
           .onAppear {
               viewModel.fetchCourses(for: term.id)
           }
           .onChange(of: selectedCourse) { course in
               if let course = course {
                   let destination = CourseDetailView(course: course)
                   if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootViewController = window.rootViewController {
                       if let navigationController = rootViewController.findNavigationController() {
                           DispatchQueue.main.async {
                               navigationController.pushViewController(UIHostingController(rootView: destination), animated: true)
                               selectedCourse = nil
                           }
                       }
                   }
               }
           }
       }
       
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if !viewModel.errorMessage.isEmpty {
                errorView
            } else if viewModel.courses.isEmpty {
                emptyStateView
            } else {
                courseList
            }
            
            addButton
        }
    }
    
    // MARK: - Supporting Views
    private var courseList: some View {
        List {
            ForEach(viewModel.courses) { course in
                courseRow(course: course)
            }
            .onDelete { indexSet in
                handleDelete(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func courseRow(course: Course) -> some View {
        NavigationLink(destination: CourseDetailView(course: course)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                
                HStack {
                    Text("Kredi:")
                    Text(String(format: "%.1f", course.credits))
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var errorView: some View {
        VStack {
            Text("Error")
                .font(.headline)
            Text(viewModel.errorMessage)
                .font(.subheadline)
                .foregroundColor(.red)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Henüz ders eklenmemiş")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
    
    private var addButton: some View {
        Button(action: { isAddCourseViewVisible = true }) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.accentColor)
        }
        .padding(.bottom, 30)
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(isEditing ? "Bitti" : "Düzenle") {
                withAnimation { isEditing.toggle() }
            }
        }
    }
    
    // MARK: - Actions
    private func handleDelete(at indexSet: IndexSet) {
        for index in indexSet {
            let course = viewModel.courses[index]
            viewModel.deleteCourse(courseId: course.id) { _ in }
        }
    }
}
extension UIViewController {
    func findNavigationController() -> UINavigationController? {
        if let nav = self as? UINavigationController {
            return nav
        }
        for child in children {
            if let nav = child.findNavigationController() {
                return nav
            }
        }
        return nil
    }
}
