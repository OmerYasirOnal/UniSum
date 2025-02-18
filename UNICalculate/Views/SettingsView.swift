import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("selectedTheme") private var selectedTheme: String = "system" // "system", "light" veya "dark"
    
    var body: some View {
        NavigationView {
            Form {
                // Hesap Bilgileri
                Section(header: Text("Account Information")) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authViewModel.user?.email ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("University")
                        Spacer()
                        Text(authViewModel.user?.university ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Department")
                        Spacer()
                        Text(authViewModel.user?.department ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Dil Seçimi
                Section(header: Text(LocalizedStringKey("language"))) {
                    Picker(LocalizedStringKey("select_language"), selection: $languageManager.selectedLanguage) {
                        Text("🇺🇸 English").tag("en")
                        Text("🇹🇷 Türkçe").tag("tr")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Tema / Görünüm Seçimi
                Section(header: Text("Theme")) {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("System Default").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Çıkış Yap Butonu
                Section {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Text(LocalizedStringKey("logout"))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("settings"))
        }
        .preferredColorScheme(colorSchemeForSelectedTheme())
    }
    
    private func colorSchemeForSelectedTheme() -> ColorScheme? {
        switch selectedTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}
