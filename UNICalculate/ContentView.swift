import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var languageChanged = false

    var body: some View {
        Group {
            #if DEBUG
            if DemoMode.isActive {
                demoRoot
                    .environmentObject(authViewModel)
            } else {
                gate
            }
            #else
            gate
            #endif
        }
        .environment(\.locale, .init(identifier: languageManager.selectedLanguage))
        .id(languageManager.selectedLanguage)
        .onAppear {
            authViewModel.checkAuthentication()

            // Token expire notification'ını dinle
            NotificationCenter.default.addObserver(
                forName: Notification.Name("TokenExpired"),
                object: nil,
                queue: .main
            ) { _ in
                authViewModel.logout()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
            languageChanged.toggle()
        }
    }

    @ViewBuilder
    private var gate: some View {
        if authViewModel.isAuthenticated {
            TermListView()
                .environmentObject(authViewModel)
        } else {
            LoginView()
                .environmentObject(authViewModel)
        }
    }

    #if DEBUG
    /// Offline demo router — pick a screen with `UNISUM_DEMO_SCREEN` so any view
    /// can be launched directly and screenshotted without a backend.
    @ViewBuilder
    private var demoRoot: some View {
        switch ProcessInfo.processInfo.environment["UNISUM_DEMO_SCREEN"] ?? "terms" {
        case "login":
            LoginView()
        case "signup":
            SignupView()
        case "forgot":
            ForgotPasswordView()
        case "courses":
            NavigationStack { CourseListView(term: DemoData.terms[1]) }
        case "detail":
            NavigationStack { CourseDetailView(course: DemoData.courses(forTerm: 2)[2]) }
        case "profile":
            NavigationStack { ProfileView() }
        case "addterm":
            ZStack {
                Color.appBackground.ignoresSafeArea()
                AddTermPanel(isVisible: .constant(true), termViewModel: TermViewModel())
            }
        case "addcourse":
            ZStack {
                Color.appBackground.ignoresSafeArea()
                AddCourseView(isPresented: .constant(true),
                              selectedCourse: .constant(nil),
                              courseViewModel: CourseViewModel(),
                              termId: 2, userId: 1)
            }
        default:
            TermListView()
        }
    }
    #endif
}
