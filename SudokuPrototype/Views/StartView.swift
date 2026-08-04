import SwiftUI

struct StartView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var game: GameState
    @Environment(\.palette) private var palette
    @State private var showSettings = false
    let onStart: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("SUDOKU")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .tracking(2)
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
                .padding()
                Spacer()
            }

            VStack(spacing: 16) {
                Spacer()

                if game.hasProgress {
                    Button {
                        onContinue()
                    } label: {
                        VStack(spacing: 4) {
                            Text("Continue Game")
                                .font(.headline)
                            Text(GameState.formatted(game.elapsedSeconds))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: 240)
                        .padding()
                        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }

                Button("Start Game") {
                    onStart()
                }
                .font(.title.bold())
                .padding(.horizontal, 48)
                .padding(.vertical, 20)
                .buttonStyle(.borderedProminent)
                .tint(palette.accent)
                .controlSize(.large)

                Spacer()
            }
        }
        .background(palette.background.ignoresSafeArea())
        .sheet(isPresented: $showSettings) {
            SettingsView(theme: theme)
        }
    }
}

#Preview {
    StartView(theme: ThemeManager(), game: GameState(), onStart: {}, onContinue: {})
}
