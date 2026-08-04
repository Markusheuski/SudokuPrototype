import SwiftUI

final class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }

    init() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }

    func toggle() {
        withAnimation(.easeInOut(duration: 0.4)) {
            isDarkMode.toggle()
        }
    }
}
