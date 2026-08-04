import Foundation

final class PlayerStats: ObservableObject {
    static let shared = PlayerStats()

    @Published var gamesPlayed: Int
    @Published var currentStreak: Int
    @Published var bestStreak: Int
    @Published var bestTime: [Difficulty: Int]

    private static let storageKey = "sudoku.playerStats"

    private init() {
        if let snapshot = PlayerStats.loadSnapshot() {
            gamesPlayed = snapshot.gamesPlayed
            currentStreak = snapshot.currentStreak
            bestStreak = snapshot.bestStreak
            bestTime = snapshot.bestTime
        } else {
            gamesPlayed = 0
            currentStreak = 0
            bestStreak = 0
            bestTime = [:]
        }
    }

    func recordWin(difficulty: Difficulty, elapsedSeconds: Int) {
        gamesPlayed += 1
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)
        if let existing = bestTime[difficulty] {
            bestTime[difficulty] = min(existing, elapsedSeconds)
        } else {
            bestTime[difficulty] = elapsedSeconds
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
    }

    private func persist() {
        let snapshot = Snapshot(
            gamesPlayed: gamesPlayed,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            bestTime: bestTime
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func loadSnapshot() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
