import SwiftUI

@main
struct SudokuPrototypeApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var game = GameState()
    @State private var hasStarted = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView(theme: theme, game: game, hasStarted: $hasStarted)

                Color.black
                    .opacity(theme.isDimmed ? 1 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .preferredColorScheme(theme.appearanceMode.colorScheme)
        }
    }
}

private struct RootView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var game: GameState
    @Binding var hasStarted: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var palette: Palette {
        colorScheme == .dark ? .dark(for: theme.selectedVariant) : .light
    }

    var body: some View {
        Group {
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
        }
        .environment(\.palette, palette)
    }
}
