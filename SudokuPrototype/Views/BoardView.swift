import SwiftUI

/// How a cell's background should read relative to the currently selected cell.
/// Shared between the real board and any decorative mini-board (e.g. the
/// theme preview in Settings) so both stay visually in sync automatically.
enum CellHighlight {
    case none, peer, sameValue, selected

    var opacity: Double {
        switch self {
        case .none: return 0
        case .peer: return 0.08
        case .sameValue: return 0.22
        case .selected: return 0.35
        }
    }
}

/// Shared grid-line styling so any sudoku-style grid (real board or a
/// decorative mini-board) draws lines identically.
enum GridLineStyle {
    static func color(thick: Bool) -> Color {
        Color.primary.opacity(thick ? 0.8 : 0.25)
    }

    static func width(thick: Bool) -> CGFloat {
        thick ? 2 : 0.5
    }
}

/// Draws a square NxN grid of lines. Pass `blockSize: 0` to disable the
/// thicker block-separator lines (e.g. for a grid too small to have blocks).
struct SudokuGridLines: View {
    let size: CGFloat
    let cellCount: Int
    let blockSize: Int

    var body: some View {
        let cell = size / CGFloat(cellCount)
        ZStack {
            ForEach(0...cellCount, id: \.self) { i in
                let thick = blockSize > 0 && i % blockSize == 0 && i != 0 && i != cellCount

                Path { path in
                    path.move(to: CGPoint(x: 0, y: CGFloat(i) * cell))
                    path.addLine(to: CGPoint(x: size, y: CGFloat(i) * cell))
                }
                .stroke(GridLineStyle.color(thick: thick), lineWidth: GridLineStyle.width(thick: thick))

                Path { path in
                    path.move(to: CGPoint(x: CGFloat(i) * cell, y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(i) * cell, y: size))
                }
                .stroke(GridLineStyle.color(thick: thick), lineWidth: GridLineStyle.width(thick: thick))
            }
        }
    }
}

struct BoardView: View {
    @ObservedObject var game: GameState
    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cellSize = size / 9

            VStack(spacing: 0) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<9, id: \.self) { col in
                            cellView(row: row, col: col, cellSize: cellSize)
                        }
                    }
                }
            }
            .frame(width: size, height: size)
            .overlay(SudokuGridLines(size: size, cellCount: 9, blockSize: 3))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func cellView(row: Int, col: Int, cellSize: CGFloat) -> some View {
        let value = game.board[row][col]
        let isGiven = game.givenMask[row][col]
        let isRevealed = game.revealedMask[row][col]
        let isSelected = game.selected.map { $0.row == row && $0.col == col } ?? false
        let cellNotes = game.notes[row][col]

        ZStack {
            if value != 0 {
                Text("\(value)")
                    .font(.system(size: cellSize * 0.5, weight: isGiven ? .bold : .regular))
                    .foregroundColor(isGiven || isRevealed ? palette.given : palette.accent)
            } else if !cellNotes.isEmpty {
                NotesGridView(notes: cellNotes, cellSize: cellSize)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .background(palette.accent.opacity(highlight(row: row, col: col, isSelected: isSelected).opacity))
        .contentShape(Rectangle())
        .onTapGesture { game.select(row: row, col: col) }
    }

    private func highlight(row: Int, col: Int, isSelected: Bool) -> CellHighlight {
        if isSelected { return .selected }
        guard let sel = game.selected else { return .none }

        let selectedValue = game.board[sel.row][sel.col]
        if selectedValue != 0 && game.board[row][col] == selectedValue {
            return .sameValue
        }

        let sameRowOrCol = sel.row == row || sel.col == col
        let sameBlock = sel.row / 3 == row / 3 && sel.col / 3 == col / 3
        if sameRowOrCol || sameBlock {
            return .peer
        }

        return .none
    }
}

private struct NotesGridView: View {
    let notes: Set<Int>
    let cellSize: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(1...3, id: \.self) { col in
                        let n = row * 3 + col
                        Text(notes.contains(n) ? "\(n)" : "")
                            .font(.system(size: cellSize * 0.18))
                            .foregroundColor(.secondary)
                            .frame(width: cellSize / 3, height: cellSize / 3)
                    }
                }
            }
        }
    }
}

/// A small, static, non-interactive sudoku-style grid for decorative use
/// (e.g. the theme preview in Settings) that reuses the real board's exact
/// visual language: same grid-line style, same highlight opacities, same
/// given/accent text treatment.
struct MiniBoardPreview: View {
    struct Cell {
        let value: Int
        let isAccent: Bool
        let highlight: CellHighlight

        init(_ value: Int, isAccent: Bool = false, highlight: CellHighlight = .none) {
            self.value = value
            self.isAccent = isAccent
            self.highlight = highlight
        }
    }

    let cells: [[Cell]]
    let palette: Palette

    private var count: Int { cells.count }

    var body: some View {
        GeometryReader { geo in
            let boardSize = min(geo.size.width, geo.size.height)
            let cellSize = boardSize / CGFloat(count)

            VStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<count, id: \.self) { col in
                            let cell = cells[row][col]
                            Text(cell.value == 0 ? "" : "\(cell.value)")
                                .font(.system(size: cellSize * 0.5, weight: cell.isAccent ? .regular : .bold))
                                .foregroundColor(cell.isAccent ? palette.accent : palette.given)
                                .frame(width: cellSize, height: cellSize)
                                .background(palette.accent.opacity(cell.highlight.opacity))
                        }
                    }
                }
            }
            .frame(width: boardSize, height: boardSize)
            .overlay(SudokuGridLines(size: boardSize, cellCount: count, blockSize: 0))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
