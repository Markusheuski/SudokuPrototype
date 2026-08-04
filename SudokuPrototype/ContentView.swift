import SwiftUI

struct ContentView: View {
    @ObservedObject var game: GameState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.palette) private var palette
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            topBar

            ZStack {
                VStack(spacing: 16) {
                    BoardView(game: game)
                        .padding(.horizontal)

                    NumberPadView(game: game)
                        .padding(.horizontal)
                }
                .blur(radius: game.isPaused ? 20 : 0)
                .allowsHitTesting(!game.isPaused)

                if game.isPaused {
                    pausedOverlay
                }
            }

            Spacer()
        }
        .padding(.top, 8)
        .background(palette.background.ignoresSafeArea())
        .overlay {
            if game.isGameOver || game.isSolved {
                endOfGameOverlay
            }
        }
        .onAppear { game.startTimer() }
        .onDisappear { game.stopTimer() }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                game.startTimer()
            } else {
                game.stopTimer()
            }
        }
    }

    private var pausedOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Paused")
                .font(.title2.bold())

            VStack(spacing: 10) {
                Button {
                    game.togglePause()
                } label: {
                    Text("Resume")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onBack()
                } label: {
                    Text("Menu")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .frame(width: 200)
            .padding(.top, 4)
        }
        .padding(24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var endOfGameOverlay: some View {
        Color.black.opacity(0.001)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: game.isSolved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(game.isSolved ? Color.green : Color.red)

                    Text(game.isSolved ? "Solved!" : "Out of mistakes")
                        .font(.title2.bold())

                    Text(GameState.formatted(game.elapsedSeconds))
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())

                    VStack(spacing: 10) {
                        Button {
                            withAnimation { game.reset() }
                        } label: {
                            Text("Play Again")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            onBack()
                        } label: {
                            Text("Menu")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(width: 200)
                    .padding(.top, 4)
                }
                .padding(24)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
    }

    private var topBar: some View {
        HStack {
            backButton
            Spacer()
            timerControl
            Spacer()
            mistakesBadge
        }
        .padding(.horizontal)
    }

    private var timerControl: some View {
        HStack(spacing: 6) {
            Button {
                game.togglePause()
            } label: {
                Image(systemName: game.isPaused ? "play.fill" : "pause.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .disabled(game.isSolved || game.isGameOver)

            Text(GameState.formatted(game.elapsedSeconds))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.12), in: Capsule())
    }

    private var mistakesBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundColor(livesStateColor)

            HStack(spacing: 4) {
                ForEach(0..<game.maxMistakes, id: \.self) { index in
                    Circle()
                        .fill(dotColor(at: index))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.12), in: Capsule())
    }

    private var remainingLives: Int {
        max(game.maxMistakes - game.mistakes, 0)
    }

    private var livesStateColor: Color {
        if remainingLives <= 1 { return .red }
        if remainingLives == game.maxMistakes { return .green }
        return .yellow
    }

    private func dotColor(at index: Int) -> Color {
        index < remainingLives ? livesStateColor : Color.secondary.opacity(0.3)
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
