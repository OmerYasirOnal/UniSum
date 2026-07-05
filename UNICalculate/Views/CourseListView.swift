import SwiftUI

struct CourseListView: View {
    @StateObject private var viewModel = CourseViewModel()
    let term: Term
    @State private var selectedCourse: Course? = nil
    @State private var isAddCourseViewVisible = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()

            mainContent

            FloatingAddButton {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isAddCourseViewVisible = true
                }
            }
            .padding(DS.Spacing.lg)

            if isAddCourseViewVisible {
                AddCourseView(
                    isPresented: $isAddCourseViewVisible,
                    selectedCourse: $selectedCourse,
                    courseViewModel: viewModel,
                    termId: term.id,
                    userId: term.userId
                )
                .transition(.opacity)
                .zIndex(3)
            }
        }
        .navigationTitle(LocalizedStringKey("courses"))
        .navigationBarTitleDisplayMode(.inline)
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
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !viewModel.errorMessage.isEmpty {
            errorView
        } else {
            List {
                Section {
                    termHeaderCard.plainCardRow(vertical: DS.Spacing.xs)
                }

                if viewModel.courses.isEmpty {
                    emptyStateView.plainCardRow()
                } else {
                    Section {
                        ForEach(viewModel.courses) { course in
                            courseRow(course: course).plainCardRow()
                        }
                        .onDelete { indexSet in handleDelete(at: indexSet) }
                    }
                }

                Color.clear
                    .frame(height: 84)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListHeaderHeight, 0)
        }
    }

    // MARK: - Term summary header
    private var termHeaderCard: some View {
        HStack(spacing: DS.Spacing.lg) {
            if viewModel.isLoadingGPA {
                ProgressView()
                    .frame(width: 92, height: 92)
            } else {
                GPARing(gpa: viewModel.termGPA, size: 92, lineWidth: 10)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                summaryStat(icon: "creditcard.fill",
                            title: "total_credits",
                            value: String(format: "%.1f", viewModel.totalCredits))
                summaryStat(icon: "books.vertical.fill",
                            title: "courses",
                            value: "\(viewModel.courses.count)")
            }
            Spacer(minLength: 0)
        }
        .card(padding: DS.Spacing.lg)
    }

    private func summaryStat(icon: String, title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 22)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: DS.Spacing.xs)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Course row
    private func courseRow(course: Course) -> some View {
        ZStack {
            courseCard(course)
            NavigationLink(destination: CourseDetailView(course: course)) { EmptyView() }
                .opacity(0)
        }
    }

    private func courseCard(_ course: Course) -> some View {
        HStack(spacing: DS.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Image(systemName: "creditcard")
                    Text(String(format: "%.1f", course.credits))
                    Text(LocalizedStringKey("credits"))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: DS.Spacing.xs)

            VStack(alignment: .trailing, spacing: 6) {
                Text(String(format: "%.1f", course.average))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(GradeColor.forScore(course.average))
                if let letter = course.letterGrade, !letter.isEmpty {
                    GradeBadge(letter: letter, gpa: course.gpa, compact: true)
                }
            }
        }
        .card()
    }

    // MARK: - States
    private var errorView: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 46))
                .foregroundStyle(Color.dangerRed)
            Text(viewModel.errorMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            systemImage: "book.closed",
            title: "no_courses_yet",
            message: "add_new_course"
        )
    }

    // MARK: - Delete
    private func handleDelete(at indexSet: IndexSet) {
        for index in indexSet {
            let course = viewModel.courses[index]
            viewModel.deleteCourse(courseId: course.id) { success in
                if success {
                    viewModel.fetchTermGPA(for: term.id)
                }
            }
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
