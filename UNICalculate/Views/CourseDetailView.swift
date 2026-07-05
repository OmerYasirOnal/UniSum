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
                ProgressView(LocalizedStringKey("loading"))
                    .frame(maxWidth: .infinity)
                    .padding(.top, DS.Spacing.xxl)
                    .plainCardRow()
            } else {
                Section {
                    headerCard.plainCardRow(vertical: DS.Spacing.xs)
                }

                Section {
                    if gradeViewModel.grades.isEmpty {
                        emptyGradesCard.plainCardRow()
                    } else {
                        ForEach(gradeViewModel.grades) { grade in
                            gradeCard(grade: grade).plainCardRow()
                        }
                    }
                } header: {
                    gradesHeader
                }

                Section {
                    gradeScaleCard.plainCardRow(vertical: DS.Spacing.xs)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListHeaderHeight, 0)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(course.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { setupView() }
        .onChange(of: gradeViewModel.grades) { _ in updateAverageAndGrade() }
        .alert(LocalizedStringKey("delete_grade"), isPresented: $showingDeleteConfirmation) {
            Button(LocalizedStringKey("delete"), role: .destructive) {
                if let grade = gradeToDelete { deleteGrade(grade) }
            }
            Button(LocalizedStringKey("cancel"), role: .cancel) { gradeToDelete = nil }
        } message: {
            Text(LocalizedStringKey("delete_confirmation"))
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addGrade:
                GradeFormView(title: NSLocalizedString("add_grade", comment: ""),
                              courseId: course.id, viewModel: gradeViewModel)
            case .editGrade(let grade):
                GradeFormView(title: NSLocalizedString("edit_grade", comment: ""),
                              courseId: course.id, grade: grade, viewModel: gradeViewModel)
            case .gradeScaleEditor:
                GradeScaleEditorView(viewModel: gradeScaleViewModel)
            }
        }
    }

    // MARK: - Header (GPA ring + course meta)
    private var headerCard: some View {
        HStack(spacing: DS.Spacing.lg) {
            GPARing(gpa: gradeScaleViewModel.currentGPA,
                    centerText: gradeScaleViewModel.currentGrade,
                    size: 108)

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                metaRow(icon: "number", title: "average",
                        value: String(format: "%.2f", currentAverage),
                        color: GradeColor.forScore(currentAverage))
                Divider()
                metaRow(icon: "creditcard.fill", title: "credits",
                        value: String(format: "%.1f", course.credits),
                        color: .primary)
            }
            Spacer(minLength: 0)
        }
        .card(padding: DS.Spacing.lg)
    }

    private func metaRow(icon: String, title: LocalizedStringKey, value: String, color: Color) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: DS.Spacing.xs)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(color)
        }
    }

    // MARK: - Grades header
    private var gradesHeader: some View {
        HStack {
            SectionHeaderLabel(title: "grades", systemImage: "list.bullet.rectangle")
            Spacer()
            Text(String(format: NSLocalizedString("remaining_weight", comment: ""),
                        Int(gradeViewModel.remainingWeight(forCourse: course.id))))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(nil)
            Button { activeSheet = .addGrade } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.brandPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.top, DS.Spacing.xs)
    }

    private var emptyGradesCard: some View {
        HStack {
            Spacer()
            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.brandPrimary.opacity(0.7))
                Text(LocalizedStringKey("no_grades_yet"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, DS.Spacing.lg)
        .card()
    }

    private func gradeCard(grade: Grade) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                Text(LocalizedStringKey(grade.gradeType))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(String(format: "%.0f", grade.score))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(GradeColor.forScore(grade.score))
            }
            HStack(spacing: DS.Spacing.sm) {
                WeightBar(fraction: grade.weight / 100, color: .brandPrimary)
                Text(String(format: "%.0f%%", grade.weight))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .card()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                gradeToDelete = grade
                showingDeleteConfirmation = true
            } label: {
                Label(LocalizedStringKey("delete"), systemImage: "trash")
            }
            Button {
                activeSheet = .editGrade(grade)
            } label: {
                Label(LocalizedStringKey("edit"), systemImage: "pencil")
            }
            .tint(Color.brandPrimary)
        }
    }

    // MARK: - Grade scale card
    private var gradeScaleCard: some View {
        VStack(spacing: DS.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("current_grade"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(gradeScaleViewModel.currentGrade)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(GradeColor.forGPA(gradeScaleViewModel.currentGPA))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(LocalizedStringKey("semester_gpa"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", gradeScaleViewModel.currentGPA))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                }
            }

            Button { activeSheet = .gradeScaleEditor } label: {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "slider.horizontal.3")
                    Text(LocalizedStringKey("view_grade_scale"))
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .card(padding: DS.Spacing.lg)
    }

    // MARK: - Helper Methods
    private func setupView() {
        gradeViewModel.fetchGrades(forCourse: course.id)
        gradeScaleViewModel.loadInitialData()
        gradeScaleViewModel.calculateCurrentGrade(average: currentAverage)
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
