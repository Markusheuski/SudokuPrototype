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
    @Published var elapsedSeconds = 0

    private(set) var solution: [[Int]]
    private(set) var givenMask: [[Bool]] // true = клетка была дана изначально (не редактируется)
    private(set) var excludedDigits: [[Set<Int>]] // цифры, уже опробованные и оказавшиеся неверными для клетки
    private(set) var revealedMask: [[Bool]] // клетки, дорисованные решением после проигрыша

    let maxMistakes = 2
    private let clues: Int
    private var timer: Timer?

    var hasProgress: Bool {
        elapsedSeconds > 0 && !isSolved && !isGameOver
    }

    init(clues: Int = 32) {
        self.clues = clues
        if let snapshot = GameState.loadSnapshot(), !snapshot.isSolved, !snapshot.isGameOver {
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
            let generated = SudokuGenerator.generatePuzzle(clues: clues)
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
        let generated = SudokuGenerator.generatePuzzle(clues: clues)
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
        persist()
    }

    func select(row: Int, col: Int) {
        guard !isGameOver, !isPaused else { return }
        selected = (row, col)
        persist()
    }

    func togglePencilMode() {
        isPencilMode.toggle()
        persist()
    }

    func placedCount(of value: Int) -> Int {
        board.reduce(0) { total, row in
            total + row.filter { $0 == value }.count
        }
    }

    func enter(value: Int) {
        guard let cell = selected, !givenMask[cell.row][cell.col], !isGameOver, !isPaused else { return }
        guard !excludedDigits[cell.row][cell.col].contains(value) else { return }

        if isPencilMode {
            if notes[cell.row][cell.col].contains(value) {
                notes[cell.row][cell.col].remove(value)
            } else {
                notes[cell.row][cell.col].insert(value)
            }
            persist()
            return
        }

        if value == solution[cell.row][cell.col] {
            board[cell.row][cell.col] = value
            notes[cell.row][cell.col].removeAll()
            checkSolved()
        } else {
            excludedDigits[cell.row][cell.col].insert(value)
            mistakes += 1
            if mistakes >= maxMistakes {
                triggerGameOver()
            }
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

    private func triggerGameOver() {
        for r in 0..<9 {
            for c in 0..<9 where board[r][c] == 0 {
                board[r][c] = solution[r][c]
                revealedMask[r][c] = true
            }
        }
        selected = nil
        isGameOver = true
        stopTimer()
    }

    private func checkSolved() {
        isSolved = board == solution
        if isSolved {
            stopTimer()
        }
    }

    // MARK: - Persistence

    private static let storageKey = "sudoku.savedGame"

    private struct Snapshot: Codable {
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
    }

    private func persist() {
        let snapshot = Snapshot(
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
