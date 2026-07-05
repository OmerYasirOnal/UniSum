import SwiftUI

struct SidebarView: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            profileHeader

            ScrollView {
                VStack(spacing: DS.Spacing.xxs) {
                    NavigationLink(destination: ProfileView()) {
                        MenuItemView(icon: "person.fill", title: "profile")
                    }

                    Button(action: { authViewModel.logout() }) {
                        MenuItemView(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "logout",
                            iconColor: .dangerRed,
                            textColor: .dangerRed
                        )
                    }
                }
                .padding(.top, DS.Spacing.md)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cardBackground.ignoresSafeArea())
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isVisible = false
                        }
                    }
                }
        )
    }

    private var profileHeader: some View {
        VStack(spacing: DS.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 66, height: 66)
                Image(systemName: "person.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 2) {
                Text(authViewModel.user?.email ?? "No Email")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let university = authViewModel.user?.university, !university.isEmpty {
                    Text(university)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
        .padding(.bottom, DS.Spacing.lg)
        .padding(.horizontal, DS.Spacing.md)
        .background(LinearGradient.brand.ignoresSafeArea(edges: .top))
    }
}

struct MenuItemView: View {
    let icon: String
    let title: LocalizedStringKey
    var iconColor: Color = .brandPrimary
    var textColor: Color = .primary

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 26)
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(textColor)
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.md)
        .contentShape(Rectangle())
    }
}
