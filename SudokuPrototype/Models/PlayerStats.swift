import Foundation

struct ModeStats: Codable {
    var gamesPlayed = 0
    var wins: [Difficulty: Int] = [:]
    var bestTime: [Difficulty: Int] = [:]
    var totalTime: [Difficulty: Int] = [:]
    var currentStreak = 0
    var bestStreak = 0
    var flawlessWins: [Difficulty: Int] = [:] // not applicable to freestyle, left empty
    var totalMistakes = 0 // not applicable to freestyle, left at 0
}

final class PlayerStats: ObservableObject {
    static let shared = PlayerStats()

    @Published var classic: ModeStats
    @Published var freestyle: ModeStats
    @Published var unlockedDifficulties: Set<Difficulty>

    private static let storageKey = "sudoku.playerStats"

    private init() {
        if let snapshot = PlayerStats.loadSnapshot() {
            classic = snapshot.classic
            freestyle = snapshot.freestyle
            unlockedDifficulties = snapshot.unlockedDifficulties
        } else {
            classic = ModeStats()
            freestyle = ModeStats()
            unlockedDifficulties = [.easy, .medium]
        }
    }

    func recordWin(mode: GameMode, difficulty: Difficulty, elapsedSeconds: Int, mistakes: Int) {
        let isFirstWinOnDifficulty = classic.bestTime[difficulty] == nil && freestyle.bestTime[difficulty] == nil

        switch mode {
        case .classic:
            classic.gamesPlayed += 1
            classic.currentStreak += 1
            classic.bestStreak = max(classic.bestStreak, classic.currentStreak)
            if let existing = classic.bestTime[difficulty] {
                classic.bestTime[difficulty] = min(existing, elapsedSeconds)
            } else {
                classic.bestTime[difficulty] = elapsedSeconds
            }
            classic.wins[difficulty, default: 0] += 1
            classic.totalTime[difficulty, default: 0] += elapsedSeconds
            classic.totalMistakes += mistakes
            if mistakes == 0 {
                classic.flawlessWins[difficulty, default: 0] += 1
            }
        case .freestyle:
            freestyle.gamesPlayed += 1
            freestyle.currentStreak += 1
            freestyle.bestStreak = max(freestyle.bestStreak, freestyle.currentStreak)
            if let existing = freestyle.bestTime[difficulty] {
                freestyle.bestTime[difficulty] = min(existing, elapsedSeconds)
            } else {
                freestyle.bestTime[difficulty] = elapsedSeconds
            }
            freestyle.wins[difficulty, default: 0] += 1
            freestyle.totalTime[difficulty, default: 0] += elapsedSeconds
        }

        if isFirstWinOnDifficulty, let next = difficulty.next {
            unlockedDifficulties.insert(next)
        }

        persist()
    }

    func recordLoss(mode: GameMode, mistakes: Int) {
        switch mode {
        case .classic:
            classic.gamesPlayed += 1
            classic.currentStreak = 0
            classic.totalMistakes += mistakes
        case .freestyle:
            freestyle.gamesPlayed += 1
            freestyle.currentStreak = 0
        }
        persist()
    }

    func averageTime(for difficulty: Difficulty, mode: GameMode) -> Int? {
        let stats = mode == .classic ? classic : freestyle
        guard let w = stats.wins[difficulty], w > 0 else { return nil }
        return (stats.totalTime[difficulty] ?? 0) / w
    }

    func averageMistakes(mode: GameMode) -> Double {
        let stats = mode == .classic ? classic : freestyle
        guard stats.gamesPlayed > 0 else { return 0 }
        return Double(stats.totalMistakes) / Double(stats.gamesPlayed)
    }

    func flawlessWinPercentage(for difficulty: Difficulty, mode: GameMode) -> Int? {
        let stats = mode == .classic ? classic : freestyle
        guard let w = stats.wins[difficulty], w > 0 else { return nil }
        return Int((Double(stats.flawlessWins[difficulty] ?? 0) / Double(w)) * 100)
    }

    func resetAll() {
        classic = ModeStats()
        freestyle = ModeStats()
        unlockedDifficulties = [.easy, .medium]
        persist()
    }

    private struct Snapshot: Codable {
        var classic: ModeStats
        var freestyle: ModeStats
        var unlockedDifficulties: Set<Difficulty>

        init(classic: ModeStats, freestyle: ModeStats, unlockedDifficulties: Set<Difficulty>) {
            self.classic = classic
            self.freestyle = freestyle
            self.unlockedDifficulties = unlockedDifficulties
        }

        /// Pre-game-modes flat schema, kept only to migrate old saves.
        private enum LegacyCodingKeys: String, CodingKey {
            case gamesPlayed, currentStreak, bestStreak, bestTime
            case wins, totalTime, totalMistakes, flawlessWins
            case unlockedDifficulties
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let decodedClassic = try container.decodeIfPresent(ModeStats.self, forKey: .classic) {
                classic = decodedClassic
                freestyle = try container.decodeIfPresent(ModeStats.self, forKey: .freestyle) ?? ModeStats()
                unlockedDifficulties = try container.decodeIfPresent(Set<Difficulty>.self, forKey: .unlockedDifficulties)
                    ?? [.easy, .medium]
                return
            }

            // Migrating from before game modes existed: every past game was
            // effectively Classic, so fold the old flat fields in there and
            // start Freestyle from zero.
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            var migratedClassic = ModeStats()
            migratedClassic.gamesPlayed = try legacy.decodeIfPresent(Int.self, forKey: .gamesPlayed) ?? 0
            migratedClassic.currentStreak = try legacy.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
            migratedClassic.bestStreak = try legacy.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
            migratedClassic.bestTime = try legacy.decodeIfPresent([Difficulty: Int].self, forKey: .bestTime) ?? [:]
            migratedClassic.wins = try legacy.decodeIfPresent([Difficulty: Int].self, forKey: .wins) ?? [:]
            migratedClassic.totalTime = try legacy.decodeIfPresent([Difficulty: Int].self, forKey: .totalTime) ?? [:]
            migratedClassic.totalMistakes = try legacy.decodeIfPresent(Int.self, forKey: .totalMistakes) ?? 0
            migratedClassic.flawlessWins = try legacy.decodeIfPresent([Difficulty: Int].self, forKey: .flawlessWins) ?? [:]

            classic = migratedClassic
            freestyle = ModeStats()

            if let unlocked = try legacy.decodeIfPresent(Set<Difficulty>.self, forKey: .unlockedDifficulties) {
                unlockedDifficulties = unlocked.union([.easy, .medium])
            } else {
                var unlocked: Set<Difficulty> = [.easy, .medium]
                for difficulty in Difficulty.allCases where migratedClassic.bestTime[difficulty] != nil {
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
        let snapshot = Snapshot(classic: classic, freestyle: freestyle, unlockedDifficulties: unlockedDifficulties)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func loadSnapshot() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
