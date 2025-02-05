import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    @Published var selectedLanguage: String {
            didSet {
                UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
                Bundle.setLanguage(selectedLanguage)
                NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
            }
        }
        
    var displayText: String {
            selectedLanguage == "en" ? "Language" : "Dil"
        }
        
        
    init() {
            let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            let supportedLanguage = ["en", "tr"].contains(deviceLanguage) ? deviceLanguage : "en"
            self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? supportedLanguage
            Bundle.setLanguage(selectedLanguage)
        }
    
        

        
        func toggleLanguage() {
            selectedLanguage = selectedLanguage == "en" ? "tr" : "en"
        }

    func updateLanguage(_ newLanguage: String) {
        UserDefaults.standard.set(newLanguage, forKey: "selectedLanguage")
        self.selectedLanguage = newLanguage
        Bundle.setLanguage(newLanguage)
        reloadApp()
    }

    static func getStoredLanguage() -> String {
        return UserDefaults.standard.string(forKey: "selectedLanguage") ?? Locale.current.language.languageCode?.identifier ?? "en"
    }

    func reloadApp() {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                return
            }

            window.rootViewController = UIHostingController(
                rootView: ContentView()
                    .environmentObject(self)
            )

            window.makeKeyAndVisible()
        }
    }
}

// MARK: - Bundle Extension for Language Switching
extension Bundle {
    private static var bundleKey: UInt8 = 0

    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, PrivateBundle.self)
        }
        
        objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle(path: Bundle.main.path(forResource: language, ofType: "lproj") ?? ""), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private class PrivateBundle: Bundle {
        override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
            let bundle = objc_getAssociatedObject(self, &Bundle.bundleKey) as? Bundle
            return bundle?.localizedString(forKey: key, value: value, table: tableName) ?? super.localizedString(forKey: key, value: value, table: tableName)
        }
    }
}
