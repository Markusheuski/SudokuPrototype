import SwiftUI

@main
struct SudokuPrototypeApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var game = GameState()
    @State private var hasStarted = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasStarted {
                    ContentView(game: game) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasStarted = false
                        }
                    }
                } else {
                    StartView(theme: theme, game: game) {
                        game.reset()
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasStarted = true
                        }
                    } onContinue: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasStarted = true
                        }
                    }
                }

                Color.black
                    .opacity(theme.isDimmed ? 1 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        }
    }
}
