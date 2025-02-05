import SwiftUI

struct GradeFormView: View {
    // MARK: - Properties
    let title: String
    let courseId: Int
    let grade: Grade?
    @ObservedObject var viewModel: GradeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var gradeType: String
    @State private var selectedGradeType: GradeType = .custom
    @State private var score: Double
    @State private var weight: Double
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isScorePickerVisible = false
    @State private var isWeightPickerVisible = false
    
    // MARK: - Grade Types
    private enum GradeType: String, CaseIterable {
        case midterm1 = "Midterm 1"
        case midterm2 = "Midterm 2"
        case final = "Final"
        case quiz = "Quiz"
        case project = "Project"
        case homework = "Homework"
        case presentation = "Presentation"
        case custom = "Custom"
        
        var localizedName: LocalizedStringKey {
            LocalizedStringKey(rawValue)
        }
    }
    
    // MARK: - Initialization
    init(title: String, courseId: Int, grade: Grade? = nil, viewModel: GradeViewModel) {
        self.title = title
        self.courseId = courseId
        self.grade = grade
        self.viewModel = viewModel
        
        let initialGradeType = grade?.gradeType ?? ""
        _gradeType = State(initialValue: initialGradeType)
        _selectedGradeType = State(initialValue: GradeType.allCases.first { $0.rawValue == initialGradeType } ?? .custom)
        _score = State(initialValue: grade?.score ?? 50.0)
        _weight = State(initialValue: grade?.weight ?? 10.0)
    }
    
    // MARK: - Computed Properties
    private var remainingWeight: Double {
        if let grade = grade {
            let currentTotal = viewModel.totalWeight(forCourse: courseId, excluding: grade.id)
            return 100 - currentTotal
        } else {
            let currentTotal = viewModel.totalWeight(forCourse: courseId)
            return 100 - currentTotal
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                gradeTypeSection
                scoreAndWeightSection
            }
            .navigationTitle(LocalizedStringKey(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(LocalizedStringKey("warning"), isPresented: $showAlert) {
                Button(LocalizedStringKey("ok"), role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(alertMessage))
            }
            .sheet(isPresented: $isScorePickerVisible) {
                ScorePickerView(score: $score)
            }
            .sheet(isPresented: $isWeightPickerVisible) {
                WeightPickerView(
                    weight: $weight,
                    remainingWeight: remainingWeight,
                    currentGradeWeight: grade?.weight ?? 0
                )
            }
        }
    }
    
    // MARK: - Section Views
    private var gradeTypeSection: some View {
        Section(header: Text(LocalizedStringKey("grade_type"))) {
            Picker(LocalizedStringKey("select_type"), selection: $selectedGradeType) {
                ForEach(GradeType.allCases, id: \.self) { type in
                    Text(type.localizedName).tag(type)
                }
            }
            .onChange(of: selectedGradeType) { newValue in
                if newValue != .custom {
                    gradeType = newValue.rawValue
                }
            }
            
            if selectedGradeType == .custom {
                TextField(LocalizedStringKey("enter_custom_type"), text: $gradeType)
                    .textInputAutocapitalization(.words)
            }
        }
    }
    
    private var scoreAndWeightSection: some View {
        Section(header: Text(LocalizedStringKey("score_and_weight"))) {
            scoreRow
            weightRow
        }
    }
    
    private var scoreRow: some View {
        HStack {
            Text(LocalizedStringKey("score"))
            Spacer()
            Text("\(Int(score))")
                .foregroundColor(.blue)
            Button {
                isScorePickerVisible = true
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var weightRow: some View {
        HStack {
            Text(LocalizedStringKey("weight"))
            Spacer()
            Text("\(Int(weight))% / Available: \(Int(remainingWeight))%")
                .foregroundColor(weight > remainingWeight ? .red : .blue)
            Button {
                isWeightPickerVisible = true
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Toolbar Content
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button(LocalizedStringKey("cancel")) { dismiss() }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey("save")) { validateAndSave() }
                    .disabled(!isFormValid())
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isFormValid() -> Bool {
        !gradeType.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func validateAndSave() {
        let totalAfterChange = viewModel.totalWeight(forCourse: courseId, excluding: grade?.id) + weight
        
        if totalAfterChange > 100 {
            alertMessage = "Total weight cannot exceed 100%. Available weight: \(Int(remainingWeight))%"
            showAlert = true
            return
        }
        
        if let existingGrade = grade {
            updateExistingGrade(existingGrade)
        } else {
            addNewGrade()
        }
    }
    
    private func updateExistingGrade(_ existingGrade: Grade) {
        viewModel.updateGrade(
            gradeId: existingGrade.id,
            courseId: courseId,
            gradeType: gradeType,
            score: score,
            weight: weight
        ) { result in
            handleResult(result)
        }
    }
    
    private func addNewGrade() {
        viewModel.addGrade(
            courseId: courseId,
            gradeType: gradeType,
            score: score,
            weight: weight
        ) { result in
            handleResult(result)
        }
    }
    
    private func handleResult(_ result: Result<Grade, Error>) {
        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - Supporting Views
struct ScorePickerView: View {
    @Binding var score: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker(LocalizedStringKey("score"), selection: $score) {
                        ForEach(0...100, id: \.self) { value in
                            Text("\(value)").tag(Double(value))
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle(LocalizedStringKey("select_score"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("done")) { dismiss() }
                }
            }
        }
    }
}

struct WeightPickerView: View {
    @Binding var weight: Double
    let remainingWeight: Double
    let currentGradeWeight: Double
    @Environment(\.dismiss) var dismiss
    
    private var maxAllowedWeight: Double {
        remainingWeight + currentGradeWeight
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker(LocalizedStringKey("weight"), selection: $weight) {
                        ForEach(0...Int(min(100, maxAllowedWeight)), id: \.self) { value in
                            Text("\(value)%").tag(Double(value))
                        }
                    }
                    .pickerStyle(.wheel)
                } footer: {
                    Text("Available weight: \(Int(remainingWeight))%")
                }
            }
            .navigationTitle(LocalizedStringKey("select_weight"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("done")) { dismiss() }
                }
            }
        }
    }
}
