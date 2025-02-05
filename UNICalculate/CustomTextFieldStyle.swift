import SwiftUI

struct CustomTextFieldModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme // Cihazın modunu algılar

    func body(content: Content) -> some View {
        content
            .textFieldStyle(PlainTextFieldStyle())
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white) // Dark modda gri, light modda beyaz
            .foregroundColor(colorScheme == .dark ? .white : .black) // Metin rengi: Dark modda beyaz, light modda siyah
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

extension View {
    func customTextField() -> some View {
        self.modifier(CustomTextFieldModifier())
    }
}
