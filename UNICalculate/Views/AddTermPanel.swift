import SwiftUI

struct AddTermPanel: View {
    // MARK: - Properties
    @Binding var isVisible: Bool
    @ObservedObject var termViewModel: TermViewModel
    @State private var selectedClassLevel = 0
    @State private var selectedTermNumber = 0
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Constants
    let classLevels: [LocalizedStringKey] = [
        "class_level_pre", "class_level_1", "class_level_2", "class_level_3", "class_level_4"
    ]
    let classLevelKeys: [String] = ["pre", "1", "2", "3", "4"]
    let termNumbers: [LocalizedStringKey] = ["term_1", "term_2"]

    // MARK: - Body
    var body: some View {
        ZStack {
            overlayBackground
            panelContent
        }
    }

    // MARK: - UI Components
    private var overlayBackground: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture { dismiss() }
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            headerView
            classLevelPicker
            termNumberPicker
            saveButton
        }
        .padding(DS.Spacing.lg)
        .frame(width: min(UIScreen.main.bounds.width * 0.9, 420))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                .fill(Color.cardBackground)
        )
        .softShadow(24, y: 12, opacity: 0.2)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    private var headerView: some View {
        HStack {
            Text(LocalizedStringKey("add_new_term"))
                .font(.title3.weight(.bold))
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var classLevelPicker: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            SectionHeaderLabel(title: "class_level", systemImage: "graduationcap.fill")
            Picker("", selection: $selectedClassLevel) {
                ForEach(0..<classLevels.count, id: \.self) { index in
                    Text(classLevels[index]).tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(Color.brandTint.opacity(0.6))
            )
        }
    }

    private var termNumberPicker: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            SectionHeaderLabel(title: "term", systemImage: "calendar")
            Picker("", selection: $selectedTermNumber) {
                ForEach(0..<termNumbers.count, id: \.self) { index in
                    Text(termNumbers[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var saveButton: some View {
        Button(action: saveTerm) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                Text(LocalizedStringKey("save"))
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - Actions
    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isVisible = false
        }
    }

    private func saveTerm() {
        let formattedClassLevel = classLevelKeys[selectedClassLevel]
        termViewModel.addTerm(
            classLevel: formattedClassLevel,
            termNumber: selectedTermNumber + 1
        )
        dismiss()
    }
}
