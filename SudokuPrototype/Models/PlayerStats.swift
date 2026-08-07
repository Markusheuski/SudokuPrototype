import Foundation

final class PlayerStats: ObservableObject {
    static let shared = PlayerStats()

    @Published var gamesPlayed: Int
    @Published var currentStreak: Int
    @Published var bestStreak: Int
    @Published var bestTime: [Difficulty: Int]
    @Published var unlockedDifficulties: Set<Difficulty>
    @Published var wins: [Difficulty: Int]
    @Published var totalTime: [Difficulty: Int]
    @Published var totalMistakes: Int
    @Published var flawlessWins: [Difficulty: Int]

    private static let storageKey = "sudoku.playerStats"

    private init() {
        if let snapshot = PlayerStats.loadSnapshot() {
            gamesPlayed = snapshot.gamesPlayed
            currentStreak = snapshot.currentStreak
            bestStreak = snapshot.bestStreak
            bestTime = snapshot.bestTime
            unlockedDifficulties = snapshot.unlockedDifficulties
            wins = snapshot.wins
            totalTime = snapshot.totalTime
            totalMistakes = snapshot.totalMistakes
            flawlessWins = snapshot.flawlessWins
        } else {
            gamesPlayed = 0
            currentStreak = 0
            bestStreak = 0
            bestTime = [:]
            unlockedDifficulties = [.easy]
            wins = [:]
            totalTime = [:]
            totalMistakes = 0
            flawlessWins = [:]
        }
    }

    func recordWin(difficulty: Difficulty, elapsedSeconds: Int, mistakes: Int) {
        gamesPlayed += 1
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)

        let isFirstWinOnDifficulty = bestTime[difficulty] == nil
        if let existing = bestTime[difficulty] {
            bestTime[difficulty] = min(existing, elapsedSeconds)
        } else {
            bestTime[difficulty] = elapsedSeconds
        }

        if isFirstWinOnDifficulty, let next = difficulty.next {
            unlockedDifficulties.insert(next)
        }

        wins[difficulty, default: 0] += 1
        totalTime[difficulty, default: 0] += elapsedSeconds
        totalMistakes += mistakes
        if mistakes == 0 {
            flawlessWins[difficulty, default: 0] += 1
        }

        persist()
    }

    func recordLoss(mistakes: Int) {
        gamesPlayed += 1
        currentStreak = 0
        totalMistakes += mistakes
        persist()
    }

    func averageTime(for difficulty: Difficulty) -> Int? {
        guard let w = wins[difficulty], w > 0 else { return nil }
        return (totalTime[difficulty] ?? 0) / w
    }

    func averageMistakes() -> Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(totalMistakes) / Double(gamesPlayed)
    }

    func flawlessWinPercentage(for difficulty: Difficulty) -> Int? {
        guard let w = wins[difficulty], w > 0 else { return nil }
        return Int((Double(flawlessWins[difficulty] ?? 0) / Double(w)) * 100)
    }

    private struct Snapshot: Codable {
        var gamesPlayed: Int
        var currentStreak: Int
        var bestStreak: Int
        var bestTime: [Difficulty: Int]
        var unlockedDifficulties: Set<Difficulty>
        var wins: [Difficulty: Int]
        var totalTime: [Difficulty: Int]
        var totalMistakes: Int
        var flawlessWins: [Difficulty: Int]

        init(
            gamesPlayed: Int,
            currentStreak: Int,
            bestStreak: Int,
            bestTime: [Difficulty: Int],
            unlockedDifficulties: Set<Difficulty>,
            wins: [Difficulty: Int],
            totalTime: [Difficulty: Int],
            totalMistakes: Int,
            flawlessWins: [Difficulty: Int]
        ) {
            self.gamesPlayed = gamesPlayed
            self.currentStreak = currentStreak
            self.bestStreak = bestStreak
            self.bestTime = bestTime
            self.unlockedDifficulties = unlockedDifficulties
            self.wins = wins
            self.totalTime = totalTime
            self.totalMistakes = totalMistakes
            self.flawlessWins = flawlessWins
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            gamesPlayed = try container.decode(Int.self, forKey: .gamesPlayed)
            currentStreak = try container.decode(Int.self, forKey: .currentStreak)
            bestStreak = try container.decode(Int.self, forKey: .bestStreak)
            bestTime = try container.decode([Difficulty: Int].self, forKey: .bestTime)
            if let unlocked = try container.decodeIfPresent(Set<Difficulty>.self, forKey: .unlockedDifficulties) {
                unlockedDifficulties = unlocked
            } else {
                // Migrating from before difficulty unlocking existed: unlock
                // whatever was already beaten, plus one level past that,
                // instead of relocking progress the player already has.
                var unlocked: Set<Difficulty> = [.easy]
                for difficulty in Difficulty.allCases where bestTime[difficulty] != nil {
                    unlocked.insert(difficulty)
                    if let next = difficulty.next {
                        unlocked.insert(next)
                    }
                }
                unlockedDifficulties = unlocked
            }
            // Migrating from before win/mistake breakdowns existed: default
            // to empty/zero rather than failing to decode and losing every
            // other stat (games played, streaks, best times, unlocks).
            wins = try container.decodeIfPresent([Difficulty: Int].self, forKey: .wins) ?? [:]
            totalTime = try container.decodeIfPresent([Difficulty: Int].self, forKey: .totalTime) ?? [:]
            totalMistakes = try container.decodeIfPresent(Int.self, forKey: .totalMistakes) ?? 0
            flawlessWins = try container.decodeIfPresent([Difficulty: Int].self, forKey: .flawlessWins) ?? [:]
        }
    }

    private func persist() {
        let snapshot = Snapshot(
            gamesPlayed: gamesPlayed,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            bestTime: bestTime,
            unlockedDifficulties: unlockedDifficulties,
            wins: wins,
            totalTime: totalTime,
            totalMistakes: totalMistakes,
            flawlessWins: flawlessWins
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func loadSnapshot() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
