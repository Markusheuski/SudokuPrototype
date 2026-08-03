import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameState()

    var body: some View {
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
        .alert("Решено!", isPresented: $game.isSolved) {
            Button("Новая игра") { newGame() }
        }
    }

    private func newGame() {
        game.reset()
    }
}

#Preview {
    ContentView()
}
