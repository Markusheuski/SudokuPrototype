import SwiftUI

@main
struct SudokuPrototypeApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var game = GameState()
    @State private var hasStarted = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasStarted {
                    ContentView(theme: theme, game: game)
                } else {
                    StartView(theme: theme) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasStarted = true
                        }
                    }
                }
            }
            .id(theme.isDarkMode)
            .transition(.opacity)
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        }
    }
}
