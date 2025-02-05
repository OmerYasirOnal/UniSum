import SwiftUI
struct GradeFormView: View {
    let title: String
    let courseId: Int
    let grade: Grade?
    @ObservedObject var viewModel: GradeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var gradeType: String
    @State private var score: Double
    @State private var weight: Double
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(title: String, courseId: Int, grade: Grade? = nil, viewModel: GradeViewModel) {
        self.title = title
        self.courseId = courseId
        self.grade = grade
        self.viewModel = viewModel
        
        _gradeType = State(initialValue: grade?.gradeType ?? "")
        _score = State(initialValue: grade?.score ?? 50.0)
        _weight = State(initialValue: grade?.weight ?? 10.0)
    }
    
    private var remainingWeight: Double {
        if let grade = grade {
            // Düzenleme durumunda, mevcut notun ağırlığını dahil etme
            let currentTotal = viewModel.totalWeight(forCourse: courseId, excluding: grade.id)
            return 100 - currentTotal
        } else {
            // Yeni not ekleme durumunda
            let currentTotal = viewModel.totalWeight(forCourse: courseId)
            return 100 - currentTotal
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grade Details")) {
                    TextField("Type (e.g., Midterm, Final)", text: $gradeType)
                        .textInputAutocapitalization(.words)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Score")
                            Spacer()
                            Text("\(Int(score))%")
                        }
                        Slider(value: $score, in: 0...100, step: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Weight")
                            Spacer()
                            Text("\(Int(weight))% / Available: \(Int(remainingWeight))%")
                                .foregroundColor(weight > remainingWeight ? .red : .secondary)
                        }
                        Slider(value: $weight, in: 0...100, step: 1)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { validateAndSave() }
                        .disabled(!isFormValid())
                }
            }
            .alert("Warning", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func isFormValid() -> Bool {
        return !gradeType.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func validateAndSave() {
        let currentWeight = grade?.weight ?? 0
        let totalAfterChange = viewModel.totalWeight(forCourse: courseId, excluding: grade?.id) + weight
        
        if totalAfterChange > 100 {
            alertMessage = "Total weight cannot exceed 100%. Available weight: \(Int(remainingWeight))%"
            showAlert = true
            return
        }
        
        // Validation passed, proceed with save
        if let existingGrade = grade {
            viewModel.updateGrade(
                gradeId: existingGrade.id,
                courseId: courseId,
                gradeType: gradeType,
                score: score,
                weight: weight
            ) { result in
                handleResult(result)
            }
        } else {
            viewModel.addGrade(
                courseId: courseId,
                gradeType: gradeType,
                score: score,
                weight: weight
            ) { result in
                handleResult(result)
            }
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
