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

    private(set) var solution: [[Int]]
    private(set) var givenMask: [[Bool]] // true = клетка была дана изначально (не редактируется)
    private(set) var excludedDigits: [[Set<Int>]] // цифры, уже опробованные и оказавшиеся неверными для клетки
    private(set) var revealedMask: [[Bool]] // клетки, дорисованные решением после проигрыша

    let maxMistakes = 3
    private let clues: Int

    init(clues: Int = 32) {
        self.clues = clues
        let generated = SudokuGenerator.generatePuzzle(clues: clues)
        board = generated.puzzle
        solution = generated.solution
        givenMask = generated.puzzle.map { row in row.map { $0 != 0 } }
        notes = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
        excludedDigits = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
        revealedMask = Array(repeating: Array(repeating: false, count: 9), count: 9)
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
    }

    func select(row: Int, col: Int) {
        guard !givenMask[row][col], !isGameOver else { return }
        selected = (row, col)
    }

    func togglePencilMode() {
        isPencilMode.toggle()
    }

    func enter(value: Int) {
        guard let cell = selected, !givenMask[cell.row][cell.col], !isGameOver else { return }
        guard !excludedDigits[cell.row][cell.col].contains(value) else { return }

        if isPencilMode {
            if notes[cell.row][cell.col].contains(value) {
                notes[cell.row][cell.col].remove(value)
            } else {
                notes[cell.row][cell.col].insert(value)
            }
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
    }

    func clearSelected() {
        guard let cell = selected, !givenMask[cell.row][cell.col], !isGameOver else { return }
        if isPencilMode {
            notes[cell.row][cell.col].removeAll()
        } else {
            board[cell.row][cell.col] = 0
        }
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
    }

    private func checkSolved() {
        isSolved = board == solution
    }
}
