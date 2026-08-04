import SwiftUI

struct ContentView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var game: GameState
    let onBack: () -> Void

    var body: some View {
        GeometryReader { geo in
            Group {
                if geo.size.width > geo.size.height {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .overlay {
            if game.isGameOver {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { game.reset() }
                    }
                    .overlay(alignment: .bottom) {
                        gameOverBanner
                            .padding(.bottom, 40)
                    }
            }
        }
        .alert("Решено!", isPresented: $game.isSolved) {
            Button("OK") { }
        }
    }

    private var gameOverBanner: some View {
        Text("Ошибки закончились — нажмите, чтобы сыграть заново")
            .font(.footnote.bold())
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: Capsule())
            .transition(.opacity)
    }

    private var portraitLayout: some View {
        VStack(spacing: 16) {
            topBar

            Text("Ошибки: \(game.mistakes)/\(game.maxMistakes)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            BoardView(game: game)
                .padding(.horizontal)

            NumberPadView(game: game)
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 8)
    }

    private var landscapeLayout: some View {
        VStack(spacing: 8) {
            HStack {
                backButton
                Spacer()
                VStack(spacing: 2) {
                    Text("Судоку")
                        .font(.headline)
                    Text("Ошибки: \(game.mistakes)/\(game.maxMistakes)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ThemeToggleButton(theme: theme)
            }
            .padding(.horizontal)

            BoardView(game: game)
                .padding(.horizontal)

            if game.selected != nil {
                NumberPadView(game: game)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.3), value: game.selected != nil)
    }

    private var topBar: some View {
        HStack {
            backButton
            Spacer()
            Text("Судоку")
                .font(.largeTitle.bold())
            Spacer()
            ThemeToggleButton(theme: theme)
        }
        .padding(.horizontal)
    }

    private var backButton: some View {
        Button {
            onBack()
        } label: {
            Image(systemName: "chevron.left")
                .font(.title2)
                .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    ContentView(theme: ThemeManager(), game: GameState(), onBack: {})
}
