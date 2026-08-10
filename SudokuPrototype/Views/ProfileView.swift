import SwiftUI

struct ProfileView: View {
    @ObservedObject var stats: PlayerStats
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: GameMode = .classic
    let onStartGame: (GameMode) -> Void

    /// Hard-coded illustrative numbers for the empty-state preview —
    /// intentionally never derived from `stats`, so they can't drift into
    /// showing real data by accident.
    private static let demoData = ProfileDisplayData(
        gamesPlayed: 12,
        currentStreak: 3,
        bestStreak: 5,
        bestTime: [.easy: 178, .medium: 312],
        wins: [.easy: 6, .medium: 3],
        averageTime: [.easy: 205, .medium: 340],
        flawlessPercentage: 44,
        averageMistakes: 0.8
    )

    private var currentModeStats: ModeStats {
        selectedMode == .classic ? stats.classic : stats.freestyle
    }

    private var liveData: ProfileDisplayData {
        let modeStats = currentModeStats
        var averages: [Difficulty: Int] = [:]
        for difficulty in Difficulty.allCases {
            if let avg = stats.averageTime(for: difficulty, mode: selectedMode) {
                averages[difficulty] = avg
            }
        }
        return ProfileDisplayData(
            gamesPlayed: modeStats.gamesPlayed,
            currentStreak: modeStats.currentStreak,
            bestStreak: modeStats.bestStreak,
            bestTime: modeStats.bestTime,
            wins: modeStats.wins,
            averageTime: averages,
            flawlessPercentage: overallFlawlessPercentage,
            averageMistakes: stats.averageMistakes(mode: selectedMode)
        )
    }

    private var overallFlawlessPercentage: Int? {
        let totalWins = currentModeStats.wins.values.reduce(0, +)
        guard totalWins > 0 else { return nil }
        let totalFlawless = currentModeStats.flawlessWins.values.reduce(0, +)
        return Int((Double(totalFlawless) / Double(totalWins)) * 100)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                    .padding()

                Group {
                    if currentModeStats.gamesPlayed == 0 {
                        emptyState
                    } else {
                        statsForm(liveData, mode: selectedMode)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
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
                        .padding(.vertical, 10)
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

    private var emptyState: some View {
        ZStack {
            statsForm(Self.demoData, mode: selectedMode)
                .opacity(0.3)
                .allowsHitTesting(false)

            emptyStateCard
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No games played yet")
                .font(.headline)

            Text("Finish your first puzzle to start tracking stats like these.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Start Game") {
                dismiss()
                onStartGame(selectedMode)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: 300)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge).fill(.thickMaterial)
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge).fill(Color.black.opacity(0.12))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, 32)
    }

    private func statsForm(_ data: ProfileDisplayData, mode: GameMode) -> some View {
        Form {
            Section {
                HStack {
                    Text("Games Played")
                    Spacer()
                    Text("\(data.gamesPlayed)")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack(spacing: 12) {
                    streakBlock(title: "Current Streak", value: data.currentStreak)
                    streakBlock(title: "Best Streak", value: data.bestStreak)
                }
            }

            Section("Best Time") {
                ForEach(Difficulty.allCases) { difficulty in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(difficulty.displayName)
                            Spacer()
                            if let seconds = data.bestTime[difficulty] {
                                Text(GameState.formatted(seconds))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("—")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let wins = data.wins[difficulty], wins > 0 {
                            HStack(spacing: 6) {
                                Text("\(wins) win\(wins == 1 ? "" : "s")")
                                if let avg = data.averageTime[difficulty] {
                                    Text("· avg \(GameState.formatted(avg))")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if mode == .classic {
                Section("Accuracy") {
                    HStack {
                        Text("Flawless Wins")
                        Spacer()
                        if let percentage = data.flawlessPercentage {
                            Text("\(percentage)%")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—")
                                .foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Text("Avg. Mistakes per Game")
                        Spacer()
                        Text(String(format: "%.1f", data.averageMistakes))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func streakBlock(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
    }
}

private struct ProfileDisplayData {
    var gamesPlayed: Int
    var currentStreak: Int
    var bestStreak: Int
    var bestTime: [Difficulty: Int]
    var wins: [Difficulty: Int]
    var averageTime: [Difficulty: Int]
    var flawlessPercentage: Int?
    var averageMistakes: Double
}

#Preview {
    ProfileView(stats: PlayerStats.shared, onStartGame: { _ in })
}
