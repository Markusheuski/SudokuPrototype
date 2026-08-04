import Foundation

final class PlayerStats: ObservableObject {
    static let shared = PlayerStats()

    @Published var gamesPlayed: Int
    @Published var currentStreak: Int
    @Published var bestStreak: Int
    @Published var bestTime: [Difficulty: Int]
    @Published var unlockedDifficulties: Set<Difficulty>

    private static let storageKey = "sudoku.playerStats"

    private init() {
        if let snapshot = PlayerStats.loadSnapshot() {
            gamesPlayed = snapshot.gamesPlayed
            currentStreak = snapshot.currentStreak
            bestStreak = snapshot.bestStreak
            bestTime = snapshot.bestTime
            unlockedDifficulties = snapshot.unlockedDifficulties
        } else {
            gamesPlayed = 0
            currentStreak = 0
            bestStreak = 0
            bestTime = [:]
            unlockedDifficulties = [.easy]
        }
    }

    func recordWin(difficulty: Difficulty, elapsedSeconds: Int) {
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

        persist()
    }

    func recordLoss() {
        gamesPlayed += 1
        currentStreak = 0
        persist()
    }

    private struct Snapshot: Codable {
        var gamesPlayed: Int
        var currentStreak: Int
        var bestStreak: Int
        var bestTime: [Difficulty: Int]
        var unlockedDifficulties: Set<Difficulty>

        init(
            gamesPlayed: Int,
            currentStreak: Int,
            bestStreak: Int,
            bestTime: [Difficulty: Int],
            unlockedDifficulties: Set<Difficulty>
        ) {
            self.gamesPlayed = gamesPlayed
            self.currentStreak = currentStreak
            self.bestStreak = bestStreak
            self.bestTime = bestTime
            self.unlockedDifficulties = unlockedDifficulties
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
        }
    }

    private func persist() {
        let snapshot = Snapshot(
            gamesPlayed: gamesPlayed,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            bestTime: bestTime,
            unlockedDifficulties: unlockedDifficulties
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func loadSnapshot() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
