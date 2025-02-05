import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var languageChanged = false

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TermListView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .environment(\.locale, .init(identifier: languageManager.selectedLanguage))
        .id(languageManager.selectedLanguage)
        .onAppear {
            authViewModel.checkAuthentication()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
            languageChanged.toggle()
        }
    }
}
