import Foundation

/// Хранит состояние игры и правила ввода/проверки.
final class GameState: ObservableObject {
    @Published var board: [[Int]]
    @Published var notes: [[Set<Int>]]
    @Published var selected: (row: Int, col: Int)? = nil
    @Published var isSolved = false
    @Published var isGameOver = false
    @Published var mistakes = 0
    @Published var isPencilMode = false
    @Published var isPaused = false

    private(set) var solution: [[Int]]
    private(set) var givenMask: [[Bool]] // true = клетка была дана изначально (не редактируется)
    private(set) var excludedDigits: [[Set<Int>]] // цифры, уже опробованные и оказавшиеся неверными для клетки
    private(set) var revealedMask: [[Bool]] // клетки, дорисованные решением после проигрыша

    /// Deliberately NOT @Published: it changes every second while the timer
    /// runs, and BoardView/NumberPadView also hold this same GameState as an
    /// @ObservedObject — broadcasting a per-second change would force them
    /// to re-layout every second too. The one place that needs a live
    /// per-second UI update (ContentView's timer label) polls this via a
    /// TimelineView instead of relying on Combine notification.
    var elapsedSeconds = 0

    var maxMistakes: Int { difficulty.maxMistakes }
    private(set) var difficulty: Difficulty
    private(set) var mode: GameMode
    private var timer: Timer?

    var hasProgress: Bool {
        elapsedSeconds > 0 && !isSolved && !isGameOver
    }

    init(difficulty: Difficulty = .medium, mode: GameMode = .classic) {
        self.difficulty = difficulty
        self.mode = mode
        if let snapshot = GameState.loadSnapshot(), !snapshot.isSolved, !snapshot.isGameOver {
            self.difficulty = snapshot.difficulty
            self.mode = snapshot.mode
            board = snapshot.board
            solution = snapshot.solution
            givenMask = snapshot.givenMask
            notes = snapshot.notes
            excludedDigits = snapshot.excludedDigits
            revealedMask = snapshot.revealedMask
            mistakes = snapshot.mistakes
            isPencilMode = snapshot.isPencilMode
            isPaused = snapshot.isPaused
            elapsedSeconds = snapshot.elapsedSeconds
            if let r = snapshot.selectedRow, let c = snapshot.selectedCol {
                selected = (r, c)
            }
        } else {
            let generated = SudokuGenerator.generatePuzzle(clues: difficulty.clueCount)
            board = generated.puzzle
            solution = generated.solution
            givenMask = generated.puzzle.map { row in row.map { $0 != 0 } }
            notes = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
            excludedDigits = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
            revealedMask = Array(repeating: Array(repeating: false, count: 9), count: 9)
        }
    }

    deinit {
        timer?.invalidate()
    }

    func reset() {
        reset(difficulty: difficulty, mode: mode)
    }

    func reset(difficulty newDifficulty: Difficulty, mode newMode: GameMode) {
        difficulty = newDifficulty
        mode = newMode
        let generated = SudokuGenerator.generatePuzzle(clues: newDifficulty.clueCount)
        board = generated.puzzle
        solution = generated.solution
        givenMask = generated.puzzle.map { row in row.map { $0 != 0 } }
        notes = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
        excludedDigits = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
        revealedMask = Array(repeating: Array(repeating: false, count: 9), count: 9)
        selected = nil
        isSolved = false
        isGameOver = false
        mistakes = 0
        isPencilMode = false
        isPaused = false
        elapsedSeconds = 0
        stopTimer()
        startTimer()
        persist()
    }

    func select(row: Int, col: Int) {
        guard !isGameOver, !isPaused else { return }
        selected = (row, col)
        HapticManager.shared.cellSelected()
        persist()
    }

    func togglePencilMode() {
        isPencilMode.toggle()
        HapticManager.shared.pencilModeToggled()
        persist()
    }

    func placedCount(of value: Int) -> Int {
        board.reduce(0) { total, row in
            total + row.filter { $0 == value }.count
        }
    }

    func enter(value: Int) {
        guard let cell = selected, !givenMask[cell.row][cell.col], !isGameOver, !isPaused else { return }

        if isPencilMode {
            if notes[cell.row][cell.col].contains(value) {
                notes[cell.row][cell.col].remove(value)
            } else {
                notes[cell.row][cell.col].insert(value)
            }
            persist()
            return
        }

        switch mode {
        case .classic:
            guard board[cell.row][cell.col] != solution[cell.row][cell.col] else { return }
            guard !excludedDigits[cell.row][cell.col].contains(value) else { return }
            if value == solution[cell.row][cell.col] {
                board[cell.row][cell.col] = value
                notes[cell.row][cell.col].removeAll()
                clearNoteFromPeers(row: cell.row, col: cell.col, value: value)
                HapticManager.shared.correctEntry()
                checkSolved()
            } else {
                excludedDigits[cell.row][cell.col].insert(value)
                mistakes += 1
                HapticManager.shared.wrongEntry()
                if mistakes >= maxMistakes {
                    triggerGameOver()
                }
            }
        case .freestyle:
            // No live correctness check: accept whatever the player enters,
            // freely overwritable. Resolution only happens via an explicit
            // Check (see checkFreestyleSolution()), not on every entry.
            board[cell.row][cell.col] = value
            notes[cell.row][cell.col].removeAll()
            HapticManager.shared.correctEntry()
        }

        persist()
    }

    func clearSelected() {
        guard let cell = selected, !givenMask[cell.row][cell.col], !isGameOver, !isPaused else { return }
        if isPencilMode {
            notes[cell.row][cell.col].removeAll()
        } else {
            board[cell.row][cell.col] = 0
        }
        persist()
    }

    func togglePause() {
        guard !isSolved, !isGameOver else { return }
        isPaused.toggle()
        if isPaused {
            stopTimer()
        } else {
            startTimer()
        }
        persist()
    }

    func startTimer() {
        guard !isPaused, !isSolved, !isGameOver else { return }
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    static func formatted(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func tick() {
        elapsedSeconds += 1
        persist()
    }

    /// Removes `value` from the pencil notes of every other cell sharing
    /// the row, column, or 3x3 block with (row, col) — called right after
    /// a correct Classic entry, not retroactively on other actions.
    private func clearNoteFromPeers(row: Int, col: Int, value: Int) {
        for r in 0..<9 {
            for c in 0..<9 where (r, c) != (row, col) {
                let sameRowOrCol = r == row || c == col
                let sameBlock = r / 3 == row / 3 && c / 3 == col / 3
                if sameRowOrCol || sameBlock {
                    notes[r][c].remove(value)
                }
            }
        }
    }

    /// Overwrites every non-given cell that doesn't already match the
    /// solution (empty or wrong) with the correct value. Covers both
    /// Classic (cells are only ever empty or right, never wrong) and
    /// Freestyle (cells can be wrong too, since nothing blocks bad entries).
    private func revealSolution() {
        for r in 0..<9 {
            for c in 0..<9 where !givenMask[r][c] && board[r][c] != solution[r][c] {
                board[r][c] = solution[r][c]
                revealedMask[r][c] = true
            }
        }
        selected = nil
    }

    private func triggerGameOver() {
        revealSolution()
        isGameOver = true
        stopTimer()
        HapticManager.shared.gameOver()
        PlayerStats.shared.recordLoss(mode: mode, mistakes: mistakes)
    }

    private func checkSolved() {
        isSolved = board == solution
        if isSolved {
            stopTimer()
            HapticManager.shared.win()
            PlayerStats.shared.recordWin(mode: mode, difficulty: difficulty, elapsedSeconds: elapsedSeconds, mistakes: mistakes)
        }
    }

    var isBoardFull: Bool {
        board.allSatisfy { row in !row.contains(0) }
    }

    /// Freestyle's explicit resolution step — nothing here happens
    /// automatically on entry, only when the player taps Check.
    func checkFreestyleSolution() {
        guard mode == .freestyle, !isGameOver, !isSolved else { return }

        if board == solution {
            isSolved = true
            stopTimer()
            HapticManager.shared.win()
            PlayerStats.shared.recordWin(mode: .freestyle, difficulty: difficulty, elapsedSeconds: elapsedSeconds, mistakes: mistakes)
        } else {
            revealSolution()
            isGameOver = true
            stopTimer()
            HapticManager.shared.gameOver()
            PlayerStats.shared.recordLoss(mode: .freestyle, mistakes: mistakes)
        }
        persist()
    }

    // MARK: - Persistence

    private static let storageKey = "sudoku.savedGame"

    private struct Snapshot: Codable {
        var difficulty: Difficulty
        var mode: GameMode
        var board: [[Int]]
        var solution: [[Int]]
        var givenMask: [[Bool]]
        var notes: [[Set<Int>]]
        var excludedDigits: [[Set<Int>]]
        var revealedMask: [[Bool]]
        var mistakes: Int
        var isSolved: Bool
        var isGameOver: Bool
        var isPencilMode: Bool
        var isPaused: Bool
        var elapsedSeconds: Int
        var selectedRow: Int?
        var selectedCol: Int?

        init(
            difficulty: Difficulty,
            mode: GameMode,
            board: [[Int]],
            solution: [[Int]],
            givenMask: [[Bool]],
            notes: [[Set<Int>]],
            excludedDigits: [[Set<Int>]],
            revealedMask: [[Bool]],
            mistakes: Int,
            isSolved: Bool,
            isGameOver: Bool,
            isPencilMode: Bool,
            isPaused: Bool,
            elapsedSeconds: Int,
            selectedRow: Int?,
            selectedCol: Int?
        ) {
            self.difficulty = difficulty
            self.mode = mode
            self.board = board
            self.solution = solution
            self.givenMask = givenMask
            self.notes = notes
            self.excludedDigits = excludedDigits
            self.revealedMask = revealedMask
            self.mistakes = mistakes
            self.isSolved = isSolved
            self.isGameOver = isGameOver
            self.isPencilMode = isPencilMode
            self.isPaused = isPaused
            self.elapsedSeconds = elapsedSeconds
            self.selectedRow = selectedRow
            self.selectedCol = selectedCol
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
            // Saves from before game modes existed predate this key.
            mode = try container.decodeIfPresent(GameMode.self, forKey: .mode) ?? .classic
            board = try container.decode([[Int]].self, forKey: .board)
            solution = try container.decode([[Int]].self, forKey: .solution)
            givenMask = try container.decode([[Bool]].self, forKey: .givenMask)
            notes = try container.decode([[Set<Int>]].self, forKey: .notes)
            excludedDigits = try container.decode([[Set<Int>]].self, forKey: .excludedDigits)
            revealedMask = try container.decode([[Bool]].self, forKey: .revealedMask)
            mistakes = try container.decode(Int.self, forKey: .mistakes)
            isSolved = try container.decode(Bool.self, forKey: .isSolved)
            isGameOver = try container.decode(Bool.self, forKey: .isGameOver)
            isPencilMode = try container.decode(Bool.self, forKey: .isPencilMode)
            isPaused = try container.decode(Bool.self, forKey: .isPaused)
            elapsedSeconds = try container.decode(Int.self, forKey: .elapsedSeconds)
            selectedRow = try container.decodeIfPresent(Int.self, forKey: .selectedRow)
            selectedCol = try container.decodeIfPresent(Int.self, forKey: .selectedCol)
        }
    }

    private func persist() {
        let snapshot = Snapshot(
            difficulty: difficulty,
            mode: mode,
            board: board,
            solution: solution,
            givenMask: givenMask,
            notes: notes,
            excludedDigits: excludedDigits,
            revealedMask: revealedMask,
            mistakes: mistakes,
            isSolved: isSolved,
            isGameOver: isGameOver,
            isPencilMode: isPencilMode,
            isPaused: isPaused,
            elapsedSeconds: elapsedSeconds,
            selectedRow: selected?.row,
            selectedCol: selected?.col
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func loadSnapshot() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}
