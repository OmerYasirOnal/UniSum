import SwiftUI

struct Toast: Equatable {
    let message: LocalizedStringKey
    let type: ToastType

    init(stringMessage: String, type: ToastType) {
        self.message = LocalizedStringKey(stringMessage)
        self.type = type
    }

    init(message: LocalizedStringKey, type: ToastType) {
        self.message = message
        self.type = type
    }

    enum ToastType {
        case error
        case success
        case info

        var color: Color {
            switch self {
            case .error:   return .dangerRed
            case .success: return .successGreen
            case .info:    return .brandPrimary
            }
        }

        var icon: String {
            switch self {
            case .error:   return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .info:    return "info.circle.fill"
            }
        }
    }
}

struct ToastView: View {
    let toast: Toast
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: toast.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(toast.type.color)

                Text(toast.message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button {
                    withAnimation { isPresented = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(toast.type.color.opacity(0.35), lineWidth: 1)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(toast.type.color)
                    .frame(width: 4)
                    .padding(.vertical, 8)
            }
            .softShadow(18, y: 8, opacity: 0.14)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.xs)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isPresented = false
                }
            }
        }
    }
}
