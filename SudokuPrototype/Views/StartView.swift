import SwiftUI

struct StartView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var game: GameState
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var stats = PlayerStats.shared
    @State private var showSettings = false
    @State private var showProfile = false
    @State private var lockedHintText: String?
    @AppStorage("selectedDifficulty") private var selectedDifficulty: Difficulty = .medium
    @AppStorage("selectedGameMode") private var selectedMode: GameMode = .classic
    let onStart: (Difficulty, GameMode) -> Void
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
                            Text("\(game.difficulty.displayName) · \(game.mode.displayName) · \(GameState.formatted(game.elapsedSeconds))")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: controlWidth)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge)
                                .fill(palette.surfaceElevated)
                                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }

                difficultyPicker
                    .frame(width: controlWidth)

                Text(lockedHintText ?? " ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(lockedHintText == nil ? 0 : 1)
                    .frame(width: controlWidth, height: 16)

                modePicker
                    .frame(width: controlWidth)

                Text(selectedMode == .classic
                    ? "Tracks mistakes — counts toward your stats."
                    : "No error limit — has its own separate stats.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(width: controlWidth)

                Button("Start Game") {
                    onStart(selectedDifficulty, selectedMode)
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
            SettingsView(theme: theme, game: game)
                .environment(\.colorScheme, colorScheme)
                .environment(\.palette, palette)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(stats: PlayerStats.shared) { mode in
                selectedMode = mode
                onStart(selectedDifficulty, mode)
            }
            .environment(\.colorScheme, colorScheme)
            .environment(\.palette, palette)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(GameMode.allCases) { mode in
                let isSelected = mode == selectedMode
                Button {
                    selectedMode = mode
                } label: {
                    Text(mode.displayName)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isSelected ? palette.accent : Color.clear,
                            in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
    }

    private var difficultyPicker: some View {
        HStack(spacing: 4) {
            ForEach(Difficulty.allCases) { difficulty in
                let isSelected = difficulty == selectedDifficulty
                let isUnlocked = stats.unlockedDifficulties.contains(difficulty)
                Button {
                    selectDifficulty(difficulty)
                } label: {
                    HStack(spacing: 3) {
                        Text(difficulty.displayName)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        if !isUnlocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        isSelected ? palette.accent : Color.clear,
                        in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                    )
                    .opacity(isUnlocked ? 1 : 0.4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
    }

    private func selectDifficulty(_ difficulty: Difficulty) {
        guard stats.unlockedDifficulties.contains(difficulty) else {
            guard let prerequisite = difficulty.previous else { return }
            withAnimation {
                lockedHintText = "Beat \(prerequisite.displayName) to unlock \(difficulty.displayName)"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    lockedHintText = nil
                }
            }
            return
        }
        selectedDifficulty = difficulty
    }
}

#Preview {
    StartView(theme: ThemeManager(), game: GameState(), onStart: { _, _ in }, onContinue: {})
}
