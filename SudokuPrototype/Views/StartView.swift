import SwiftUI

struct StartView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var game: GameState
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSettings = false
    @State private var showProfile = false
    @AppStorage("selectedDifficulty") private var selectedDifficulty: Difficulty = .medium
    let onStart: (Difficulty) -> Void
    let onContinue: () -> Void

    private let controlWidth: CGFloat = 300

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("SUDOKU")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .tracking(2)
                    Spacer()
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
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
                            Text("\(game.difficulty.displayName) · \(GameState.formatted(game.elapsedSeconds))")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: controlWidth)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }

                difficultyPicker
                    .frame(width: controlWidth)

                Button("Start Game") {
                    onStart(selectedDifficulty)
                }
                .font(.title.bold())
                .frame(width: controlWidth)
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
                .environment(\.colorScheme, colorScheme)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(stats: PlayerStats.shared) {
                onStart(selectedDifficulty)
            }
            .environment(\.colorScheme, colorScheme)
        }
    }

    private var difficultyPicker: some View {
        HStack(spacing: 4) {
            ForEach(Difficulty.allCases) { difficulty in
                let isSelected = difficulty == selectedDifficulty
                Button {
                    selectedDifficulty = difficulty
                } label: {
                    Text(difficulty.displayName)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isSelected ? palette.accent : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    StartView(theme: ThemeManager(), game: GameState(), onStart: { _ in }, onContinue: {})
}
