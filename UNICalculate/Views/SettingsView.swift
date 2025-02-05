import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        NavigationView {
            Form {
                // Dil seçimi
                Section(header: Text(LocalizedStringKey("language"))) {
                    Picker(LocalizedStringKey("select_language"), selection: $languageManager.selectedLanguage) {
                        Text("🇺🇸 English").tag("en")
                        Text("🇹🇷 Türkçe").tag("tr")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Tema görünümü
                Section(header: Text(LocalizedStringKey("appearance"))) {
                    HStack {
                        Text(LocalizedStringKey("theme"))
                        Spacer()
                        Text(colorScheme == .dark ? "🌙 Dark" : "☀️ Light")
                            .bold()
                    }
                }

                // Çıkış yap butonu
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
    }
}
