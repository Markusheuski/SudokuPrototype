import Foundation

/// Хранит состояние игры и правила ввода/проверки.
final class GameState: ObservableObject {
    @Published var board: [[Int]]
    @Published var selected: (row: Int, col: Int)? = nil
    @Published var isSolved = false

    private(set) var solution: [[Int]]
    private(set) var givenMask: [[Bool]] // true = клетка была дана изначально (не редактируется)

    private let clues: Int

    init(clues: Int = 32) {
        self.clues = clues
        let generated = SudokuGenerator.generatePuzzle(clues: clues)
        board = generated.puzzle
        solution = generated.solution
        givenMask = generated.puzzle.map { row in row.map { $0 != 0 } }
    }

    func reset() {
        let generated = SudokuGenerator.generatePuzzle(clues: clues)
        board = generated.puzzle
        solution = generated.solution
        givenMask = generated.puzzle.map { row in row.map { $0 != 0 } }
        selected = nil
        isSolved = false
    }

    func select(row: Int, col: Int) {
        guard !givenMask[row][col] else { return }
        selected = (row, col)
    }

    func enter(value: Int) {
        guard let cell = selected, !givenMask[cell.row][cell.col] else { return }
        board[cell.row][cell.col] = value
        checkSolved()
    }

    func clearSelected() {
        guard let cell = selected, !givenMask[cell.row][cell.col] else { return }
        board[cell.row][cell.col] = 0
    }

    func isCellWrong(row: Int, col: Int) -> Bool {
        let value = board[row][col]
        return value != 0 && value != solution[row][col]
    }

    private func checkSolved() {
        isSolved = board == solution
    }
}
