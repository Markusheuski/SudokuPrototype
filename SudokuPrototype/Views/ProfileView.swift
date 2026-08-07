import SwiftUI

struct ProfileView: View {
    @ObservedObject var stats: PlayerStats
    @Environment(\.dismiss) private var dismiss
    let onStartGame: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if stats.gamesPlayed == 0 {
                    emptyState
                } else {
                    statsList
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No games played yet")
                .font(.headline)

            Text("Finish your first puzzle to start tracking stats.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Start Game") {
                dismiss()
                onStartGame()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statsList: some View {
        Form {
            Section {
                HStack {
                    Text("Games Played")
                    Spacer()
                    Text("\(stats.gamesPlayed)")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack(spacing: 12) {
                    streakBlock(title: "Current Streak", value: stats.currentStreak)
                    streakBlock(title: "Best Streak", value: stats.bestStreak)
                }
            }

            Section("Best Time") {
                ForEach(Difficulty.allCases) { difficulty in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(difficulty.displayName)
                            Spacer()
                            if let seconds = stats.bestTime[difficulty] {
                                Text(GameState.formatted(seconds))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("—")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let wins = stats.wins[difficulty], wins > 0 {
                            HStack(spacing: 6) {
                                Text("\(wins) win\(wins == 1 ? "" : "s")")
                                if let avg = stats.averageTime(for: difficulty) {
                                    Text("· avg \(GameState.formatted(avg))")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Accuracy") {
                HStack {
                    Text("Flawless Wins")
                    Spacer()
                    if let percentage = overallFlawlessPercentage {
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
                    Text(String(format: "%.1f", stats.averageMistakes()))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var overallFlawlessPercentage: Int? {
        let totalWins = stats.wins.values.reduce(0, +)
        guard totalWins > 0 else { return nil }
        let totalFlawless = stats.flawlessWins.values.reduce(0, +)
        return Int((Double(totalFlawless) / Double(totalWins)) * 100)
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
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProfileView(stats: PlayerStats.shared, onStartGame: {})
}
