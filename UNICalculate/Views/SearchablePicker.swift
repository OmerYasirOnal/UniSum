import SwiftUI

/// A form field that opens a searchable list sheet to pick one string value.
struct SearchablePicker: View {
    let placeholder: LocalizedStringKey
    let systemImage: String
    let options: [String]
    @Binding var selection: String

    @State private var showSheet = false
    @State private var query = ""

    private var filtered: [String] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return options }
        return options.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        Button { showSheet = true } label: {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(selection.isEmpty ? Color.textSecondary : Color.brandPrimary)
                    .frame(width: 22)
                if selection.isEmpty {
                    Text(placeholder).foregroundStyle(Color.textSecondary)
                } else {
                    Text(selection).foregroundStyle(Color.textPrimary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .customTextField(isFocused: !selection.isEmpty)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                List {
                    ForEach(filtered, id: \.self) { opt in
                        Button {
                            selection = opt
                            query = ""
                            showSheet = false
                        } label: {
                            HStack {
                                Text(opt).foregroundStyle(Color.textPrimary)
                                Spacer()
                                if opt == selection {
                                    Image(systemName: "checkmark").foregroundStyle(Color.brandPrimary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $query, prompt: Text(LocalizedStringKey("search")))
                .autocorrectionDisabled()
                .navigationTitle(placeholder)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedStringKey("cancel")) { showSheet = false }
                    }
                }
            }
            .presentationDetents([.large, .medium])
        }
    }
}
