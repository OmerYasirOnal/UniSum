import SwiftUI

/// Rounded, elevated text-field container used across auth and form screens.
struct CustomTextField: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, 15)
            .foregroundStyle(Color.textPrimary)
            .tint(Color.brandPrimary)
            .font(.system(.body, design: .rounded))
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(isFocused ? Color.brandPrimary : Color.hairline,
                            lineWidth: isFocused ? 2 : 1)
            )
            .shadow(color: isFocused ? Color.brandPrimary.opacity(0.14) : Color.black.opacity(0.03),
                    radius: isFocused ? 8 : 3, x: 0, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

extension View {
    func customTextField(isFocused: Bool = false) -> some View {
        self.modifier(CustomTextField(isFocused: isFocused))
    }
}

/// Text field with a leading SF Symbol icon, wrapped in the standard container.
struct IconTextField<Field: View>: View {
    let systemImage: String
    var isFocused: Bool = false
    @ViewBuilder var field: () -> Field

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isFocused ? Color.brandPrimary : Color.textSecondary)
                .frame(width: 22)
            field()
        }
        .customTextField(isFocused: isFocused)
    }
}
