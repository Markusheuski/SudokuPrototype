import Foundation

/// Генерирует полностью решённую судоку-сетку методом бэктрекинга,
/// затем убирает часть клеток, чтобы получить головоломку.
enum SudokuGenerator {

    /// 0 = пустая клетка
    static func generatePuzzle(clues: Int = 32) -> (puzzle: [[Int]], solution: [[Int]]) {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fill(&grid)
        let solution = grid

        var puzzle = solution
        var positions = (0..<81).map { ($0 / 9, $0 % 9) }
        positions.shuffle()

        let cellsToRemove = 81 - clues
        for i in 0..<min(cellsToRemove, positions.count) {
            let (r, c) = positions[i]
            puzzle[r][c] = 0
        }

        return (puzzle, solution)
    }

    private static func fill(_ grid: inout [[Int]]) -> Bool {
        guard let (row, col) = firstEmpty(grid) else { return true }

        for value in (1...9).shuffled() {
            if isValid(grid, row: row, col: col, value: value) {
                grid[row][col] = value
                if fill(&grid) { return true }
                grid[row][col] = 0
            }
        }
        return false
    }

    private static func firstEmpty(_ grid: [[Int]]) -> (Int, Int)? {
        for r in 0..<9 {
            for c in 0..<9 where grid[r][c] == 0 {
                return (r, c)
            }
        }
        return nil
    }

    static func isValid(_ grid: [[Int]], row: Int, col: Int, value: Int) -> Bool {
        for i in 0..<9 {
            if grid[row][i] == value { return false }
            if grid[i][col] == value { return false }
        }
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if grid[r][c] == value { return false }
            }
        }
        return true
    }
}
