import SwiftUI

struct SidebarView: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile Header
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 45, height: 45)
                    .foregroundColor(Color.accentColor)
                    .padding(.top, 8)
                
                Text(authViewModel.user?.email ?? "User")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            
            Divider()
            
            // Menu Items
            ScrollView {
                VStack(spacing: 0) {
                    NavigationLink(destination: ProfileView()) {
                        MenuItemView(icon: "person.fill", title: "profile")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        MenuItemView(icon: "gearshape.fill", title: "settings")
                    }
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        MenuItemView(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "logout",
                            iconColor: .red,
                            textColor: .red
                        )
                    }
                }
                .padding(.vertical, 10)
            }
            
            Spacer()
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
                            isVisible = false
                        }
                    }
                }
        )
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Menu Item View
struct MenuItemView: View {
    let icon: String
    let title: LocalizedStringKey
    var iconColor: Color = .primary
    var textColor: Color = .primary
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
                .foregroundColor(textColor)
                .font(.subheadline)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
