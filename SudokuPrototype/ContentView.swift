import SwiftUI

struct ContentView: View {
    @ObservedObject var game: GameState
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            topBar

            BoardView(game: game)
                .padding(.horizontal)

            NumberPadView(game: game)
                .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 8)
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
        .alert("Solved!", isPresented: $game.isSolved) {
            Button("OK") { }
        }
    }

    private var gameOverBanner: some View {
        Text("Out of mistakes — tap to play again")
            .font(.footnote.bold())
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: Capsule())
            .transition(.opacity)
    }

    private var topBar: some View {
        HStack {
            backButton
            Spacer()
            mistakesBadge
        }
        .padding(.horizontal)
    }

    private var mistakesBadge: some View {
        HStack(spacing: 4) {
            ForEach(0..<game.maxMistakes, id: \.self) { index in
                Circle()
                    .fill(index < game.mistakes ? Color.red : Color.red.opacity(0.2))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1), in: Capsule())
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
    ContentView(game: GameState(), onBack: {})
}
