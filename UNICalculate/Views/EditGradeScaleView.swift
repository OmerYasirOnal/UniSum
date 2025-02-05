import SwiftUI

struct EditGradeScaleView: View {
    @Binding var gradeScales: [GradeScale]
    
    var body: some View {
        NavigationView {
            List {
                ForEach($gradeScales) { $scale in
                    HStack {
                        Text(scale.letter)
                            .bold()
                        
                        Spacer()
                        
                        TextField("Min", value: $scale.minScore, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                        
                        TextField("GPA", value: $scale.gpa, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                    }
                }
            }
            .navigationTitle("Edit Grade Scale")
        }
    }
}
