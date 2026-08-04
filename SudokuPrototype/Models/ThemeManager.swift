import SwiftUI

final class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    @Published var isDimmed = false

    init() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }

    func toggle() {
        withAnimation(.easeInOut(duration: 0.15)) {
            isDimmed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self else { return }
            self.isDarkMode.toggle()
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isDimmed = false
            }
        }
    }
}
