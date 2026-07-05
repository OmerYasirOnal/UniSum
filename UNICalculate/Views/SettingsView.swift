import SwiftUI

// NOTE: This screen is currently not linked from anywhere in the navigation
// (ProfileView is used instead). Kept and cleaned up so it stays consistent and
// fully localized should it be wired up again.
struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("selectedTheme") private var selectedTheme: String = "system"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedStringKey("account_information"))) {
                    settingRow(title: "email", value: authViewModel.user?.email ?? "N/A")
                    settingRow(title: "university", value: authViewModel.user?.university ?? "N/A")
                    settingRow(title: "department", value: authViewModel.user?.department ?? "N/A")
                }

                Section(header: Text(LocalizedStringKey("language"))) {
                    Picker(LocalizedStringKey("select_language"), selection: $languageManager.selectedLanguage) {
                        (Text("🇺🇸 ") + Text(LocalizedStringKey("english"))).tag("en")
                        (Text("🇹🇷 ") + Text(LocalizedStringKey("turkish"))).tag("tr")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text(LocalizedStringKey("appearance"))) {
                    Picker(LocalizedStringKey("theme"), selection: $selectedTheme) {
                        Text(LocalizedStringKey("system_default")).tag("system")
                        Text(LocalizedStringKey("light")).tag("light")
                        Text(LocalizedStringKey("dark")).tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section {
                    Button(action: { authViewModel.logout() }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text(LocalizedStringKey("logout"))
                        }
                        .foregroundStyle(Color.dangerRed)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("settings"))
        }
        .preferredColorScheme(colorSchemeForSelectedTheme())
    }

    private func settingRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func colorSchemeForSelectedTheme() -> ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
}
