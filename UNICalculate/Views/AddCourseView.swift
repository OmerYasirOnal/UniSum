import SwiftUI

struct AddCourseView: View {
    @Binding var isPresented: Bool
    @Binding var selectedCourse: Course?
    @ObservedObject var courseViewModel: CourseViewModel
    let termId: Int
    let userId: Int

    // MARK: - Properties
    @State private var courseName: String = ""
    @State private var credits: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: Field?

    private let keyboardPadding: CGFloat = 100

    enum Field {
        case courseName, credits
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { focusedField = nil }

            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                headerView
                formView
                saveButton
            }
            .padding(DS.Spacing.lg)
            .frame(width: min(UIScreen.main.bounds.width * 0.9, 420))
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .softShadow(24, y: 12, opacity: 0.2)
            .padding(.bottom, max(keyboardHeight / 2 - keyboardPadding, 0))
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: setupKeyboardNotifications)
        .onDisappear(perform: removeKeyboardNotifications)
    }

    // MARK: - UI Components
    private var headerView: some View {
        HStack {
            Text(LocalizedStringKey("add_course"))
                .font(.title3.weight(.bold))
            Spacer()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var formView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            IconTextField(systemImage: "book", isFocused: focusedField == .courseName) {
                TextField(LocalizedStringKey("course_name"), text: $courseName)
                    .focused($focusedField, equals: .courseName)
                    .submitLabel(.next)
                    .autocorrectionDisabled()
                    .onSubmit { focusedField = .credits }
                    .onChange(of: courseName) { _ in errorMessage = nil }
            }

            IconTextField(systemImage: "creditcard", isFocused: focusedField == .credits) {
                TextField(LocalizedStringKey("credits"), text: $credits)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .credits)
                    .onChange(of: credits) { newValue in validateCredits(newValue) }
            }

            if let errorMessage = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(LocalizedStringKey(errorMessage))
                }
                .font(.caption)
                .foregroundStyle(Color.dangerRed)
                .transition(.opacity)
            }
        }
    }

    private var saveButton: some View {
        Button(action: saveCourse) {
            HStack(spacing: DS.Spacing.xs) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text(LocalizedStringKey("save"))
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle(enabled: isFormValid() && !isLoading))
        .disabled(!isFormValid() || isLoading)
        .opacity(isFormValid() && !isLoading ? 1 : 0.7)
    }

    // MARK: - Helper Functions
    private func validateCredits(_ newValue: String) {
        let filtered = newValue.filter { "0123456789.".contains($0) }
        if filtered != newValue { credits = filtered }

        if filtered.filter({ $0 == "." }).count > 1 {
            credits = String(filtered.prefix(while: { $0 != "." })) + "."
        }

        if let dotIndex = filtered.firstIndex(of: ".") {
            let decimals = filtered[filtered.index(after: dotIndex)...]
            if decimals.count > 2 {
                credits = String(filtered[..<filtered.index(dotIndex, offsetBy: 3)])
            }
        }
        errorMessage = nil
    }

    private func isFormValid() -> Bool {
        guard !courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let creditsValue = Double(credits),
              creditsValue > 0,
              creditsValue <= 30 else {
            return false
        }
        return true
    }

    private func saveCourse() {
        guard let creditsValue = Double(credits) else {
            errorMessage = "invalid_credits"
            return
        }
        guard creditsValue <= 30 else {
            errorMessage = "credits_too_high"
            return
        }

        isLoading = true
        errorMessage = nil

        courseViewModel.addCourse(
            termId: termId,
            userId: userId,
            name: courseName.trimmingCharacters(in: .whitespacesAndNewlines),
            credits: creditsValue
        ) { [self] success in
            isLoading = false
            if success {
                if let newCourse = courseViewModel.courses.last {
                    selectedCourse = newCourse
                }
                courseViewModel.fetchCourses(for: termId)
                isPresented = false
            } else {
                errorMessage = "course_add_error"
            }
        }
    }

    // MARK: - Keyboard Management
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardHeight = 0
        }
    }

    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
