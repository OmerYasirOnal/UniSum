import SwiftUI

struct CourseDetailView: View {
    // MARK: - Properties
    let course: Course
    @StateObject var gradeViewModel = GradeViewModel()
    @StateObject private var gradeScaleViewModel: GradeScaleViewModel
    @State private var currentAverage: Double
    @State private var activeSheet: ActiveSheet?
    @State private var showingDeleteConfirmation = false
    @State private var gradeToDelete: Grade?
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Sheet Type Enum
    private enum ActiveSheet: Identifiable {
        case addGrade
        case editGrade(Grade)
        case gradeScaleEditor
        
        var id: Int {
            switch self {
            case .addGrade: return 0
            case .editGrade: return 1
            case .gradeScaleEditor: return 2
            }
        }
    }
    
    init(course: Course) {
        self.course = course
        self._currentAverage = State(initialValue: course.average)
        _gradeScaleViewModel = StateObject(wrappedValue: GradeScaleViewModel(course: course))
    }
    
    // MARK: - Body
    var body: some View {
        List {
            if gradeScaleViewModel.isLoading {
                loadingView
            } else {
                courseDetailsSection
                gradesSection
                gradeScaleSection
            }
        }
        .navigationTitle(course.name)
        .onAppear { setupView() }
        .onChange(of: gradeViewModel.grades) { _ in updateAverageAndGrade() }
        .alert("Delete Grade", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let grade = gradeToDelete {
                    deleteGrade(grade)
                }
            }
            Button("Cancel", role: .cancel) {
                gradeToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this grade?")
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addGrade:
                GradeFormView(
                    title: "Add Grade",
                    courseId: course.id,
                    viewModel: gradeViewModel
                )
            case .editGrade(let grade):
                GradeFormView(
                    title: "Edit Grade",
                    courseId: course.id,
                    grade: grade,
                    viewModel: gradeViewModel
                )
            case .gradeScaleEditor:
                GradeScaleEditorView(viewModel: gradeScaleViewModel)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView("Loading...")
                .progressViewStyle(.circular)
                .padding()
            Spacer()
        }
    }
    
    // MARK: - Course Details Section
    private var courseDetailsSection: some View {
        Section("Course Details") {
            DetailRow(title: "Course Name", value: course.name)
            DetailRow(title: "Credits", value: String(format: "%.2f", course.credits))
            DetailRow(title: "Average", value: String(format: "%.2f", currentAverage))
            DetailRow(title: "Letter Grade", value: gradeScaleViewModel.currentGrade)
                .foregroundColor(.blue)
            DetailRow(title: "GPA Impact", value: String(format: "%.2f", gradeScaleViewModel.currentGPA))
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Grades Section
    private var gradesSection: some View {
        Section {
            if gradeViewModel.grades.isEmpty {
                emptyGradesView
            } else {
                gradesListView
            }
        } header: {
            HStack {
                Text("Grades")
                Spacer()
                Text("Remaining: \(gradeViewModel.remainingWeight(forCourse: course.id), specifier: "%.0f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
                Button {
                    activeSheet = .addGrade
                } label: {
                    Image(systemName: "plus.circle.fill")  // plus yerine plus.circle.fill kullanıyoruz
                        .font(.system(size: 22))  // boyutu 14'ten 22'ye çıkardık
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
    private var emptyGradesView: some View {
        Text("No grades yet")
            .foregroundColor(.secondary)
            .italic()
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
    }
    
    private var gradesListView: some View {
        ForEach(gradeViewModel.grades) { grade in
            gradeRowView(grade: grade)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        gradeToDelete = grade
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        activeSheet = .editGrade(grade)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
        }
    }
    
    private var gradesHeaderView: some View {
        HStack {
            Text("Grades")
            Spacer()
            Text("Remaining: \(gradeViewModel.remainingWeight(forCourse: course.id), specifier: "%.0f")%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Grade Scale Section
    private var gradeScaleSection: some View {
        Section(header: gradeScaleHeaderView) {
            ForEach(gradeScaleViewModel.gradeScales.sorted { $0.minScore > $1.minScore }) { scale in
                HStack {
                    Text(scale.letter)
                        .font(.headline)
                        .foregroundColor(scale.is_custom ? .blue : .primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("≥ \(scale.minScore)")
                            .font(.subheadline)
                        Text("GPA: \(scale.gpa, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var gradeScaleHeaderView: some View {
        HStack {
            Text("Grade Scale")
            Spacer()
            Button("Edit") {
                activeSheet = .gradeScaleEditor
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                activeSheet = .addGrade
            } label: {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
            }
            .accessibilityLabel("Add Grade")
        }
    }
    
    // MARK: - Row Views
    private func gradeRowView(grade: Grade) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(grade.gradeType)
                    .font(.headline)
                HStack {
                    Text("\(grade.score, specifier: "%.1f")")
                        .foregroundColor(.primary)
                    Text("(\(grade.weight, specifier: "%.1f")%)")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
    
    // MARK: - Helper Methods
    private func setupView() {
        gradeViewModel.fetchGrades(forCourse: course.id)
        gradeScaleViewModel.loadInitialData()
    }
    
    private func updateAverageAndGrade() {
        let newAverage = gradeViewModel.calculateAverage()
        currentAverage = newAverage
        gradeViewModel.updateCourseAverage(courseId: course.id)
        gradeScaleViewModel.calculateCurrentGrade(average: newAverage)
    }
    
    private func deleteGrade(_ grade: Grade) {
        withAnimation {
            gradeViewModel.deleteGrade(gradeId: grade.id, courseId: course.id)
        }
        gradeToDelete = nil
    }
}

// MARK: - Helper Views
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}
