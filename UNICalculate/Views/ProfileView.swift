import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @AppStorage("selectedTheme") private var selectedTheme: String = "system" // "system", "light", "dark"
    
    var body: some View {
        NavigationView {
            Form {
                // Hesap Bilgileri Bölümü
                Section(header: Text(LocalizedStringKey("account_information"))) {
                    HStack {
                        Text(LocalizedStringKey("email"))
                        Spacer()
                        Text(authViewModel.user?.email ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text(LocalizedStringKey("university"))
                        Spacer()
                        Text(authViewModel.user?.university ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text(LocalizedStringKey("department"))
                        Spacer()
                        Text(authViewModel.user?.department ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Dil Seçimi Bölümü
                Section(header: Text(LocalizedStringKey("language"))) {
                    Picker(LocalizedStringKey("select_language"), selection: $languageManager.selectedLanguage) {
                        Text("🇺🇸 " + LocalizedStringKey("english").stringValue)
                            .tag("en")
                        Text("🇹🇷 " + LocalizedStringKey("turkish").stringValue)
                            .tag("tr")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Tema / Görünüm Seçimi Bölümü
                Section(header: Text(LocalizedStringKey("appearance"))) {
                    Picker(LocalizedStringKey("theme"), selection: $selectedTheme) {
                        Text(LocalizedStringKey("system_default"))
                            .tag("system")
                        Text(LocalizedStringKey("light"))
                            .tag("light")
                        Text(LocalizedStringKey("dark"))
                            .tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle(LocalizedStringKey("profile"))
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

// LocalizedStringKey'den string değer çekmek için yardımcı genişletme
extension LocalizedStringKey {
    var stringValue: String {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == "key", let value = child.value as? String {
                return value
            }
        }
        return ""
    }
}
