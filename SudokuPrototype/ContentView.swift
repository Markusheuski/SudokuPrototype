import SwiftUI

struct ContentView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var game: GameState

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
        .alert("Решено!", isPresented: $game.isSolved) {
            Button("Новая игра") { newGame() }
        }
    }

    private var portraitLayout: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 24) {
                Text("Судоку")
                    .font(.largeTitle.bold())

                BoardView(game: game)
                    .padding(.horizontal)

                NumberPadView(game: game)
                    .padding(.horizontal)

                Button("Новая игра") {
                    newGame()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top)

            ThemeToggleButton(theme: theme)
                .padding()
        }
    }

    private var landscapeLayout: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Судоку")
                    .font(.headline)
                Spacer()
                Button("Новая игра") {
                    newGame()
                }
                .buttonStyle(.bordered)

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

    private func newGame() {
        game.reset()
    }
}

#Preview {
    ContentView(theme: ThemeManager(), game: GameState())
}
