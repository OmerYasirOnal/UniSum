import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @AppStorage("selectedTheme") private var selectedTheme: String = "system"

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.md) {
                avatarHeader
                accountCard
                languageCard
                appearanceCard
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.md)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(LocalizedStringKey("profile"))
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(colorSchemeForSelectedTheme())
    }

    // MARK: - Avatar header
    private var avatarHeader: some View {
        VStack(spacing: DS.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(LinearGradient.brand)
                    .frame(width: 84, height: 84)
                Text(initials)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .brandGlow(radius: 18, y: 8, opacity: 0.35)

            Text(authViewModel.user?.email ?? "N/A")
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let department = authViewModel.user?.department, !department.isEmpty {
                Text(department)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.brandOnTint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.brandTint))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.lg)
        .card(padding: DS.Spacing.lg)
    }

    private var initials: String {
        let email = authViewModel.user?.email ?? "?"
        return String(email.prefix(1)).uppercased()
    }

    // MARK: - Account info
    private var accountCard: some View {
        VStack(spacing: 0) {
            infoRow(title: "email", value: authViewModel.user?.email ?? "N/A")
            Divider()
            infoRow(title: "university", value: authViewModel.user?.university ?? "N/A")
            Divider()
            infoRow(title: "department", value: authViewModel.user?.department ?? "N/A")
        }
        .card(padding: 0)
    }

    private func infoRow(title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: DS.Spacing.md)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.md)
    }

    // MARK: - Language
    private var languageCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeaderLabel(title: "language", systemImage: "globe")
            Picker(LocalizedStringKey("select_language"), selection: $languageManager.selectedLanguage) {
                (Text("🇺🇸 ") + Text(LocalizedStringKey("english"))).tag("en")
                (Text("🇹🇷 ") + Text(LocalizedStringKey("turkish"))).tag("tr")
            }
            .pickerStyle(.segmented)
        }
        .card()
    }

    // MARK: - Appearance
    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeaderLabel(title: "appearance", systemImage: "paintbrush")
            Picker(LocalizedStringKey("theme"), selection: $selectedTheme) {
                Text(LocalizedStringKey("system_default")).tag("system")
                Text(LocalizedStringKey("light")).tag("light")
                Text(LocalizedStringKey("dark")).tag("dark")
            }
            .pickerStyle(.segmented)
        }
        .card()
    }

    private func colorSchemeForSelectedTheme() -> ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
}
