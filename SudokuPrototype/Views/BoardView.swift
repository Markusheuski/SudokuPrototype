import SwiftUI

struct BoardView: View {
    @ObservedObject var game: GameState

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
            .overlay(gridLines(size: size))
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
                    .foregroundColor(isGiven ? .primary : (isRevealed ? .secondary : .blue))
            } else if !cellNotes.isEmpty {
                NotesGridView(notes: cellNotes, cellSize: cellSize)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .background(highlightColor(row: row, col: col, isSelected: isSelected))
        .contentShape(Rectangle())
        .onTapGesture { game.select(row: row, col: col) }
    }

    private func highlightColor(row: Int, col: Int, isSelected: Bool) -> Color {
        if isSelected {
            return Color.blue.opacity(0.35)
        }
        guard let sel = game.selected else { return .clear }

        let selectedValue = game.board[sel.row][sel.col]
        if selectedValue != 0 && game.board[row][col] == selectedValue {
            return Color.blue.opacity(0.22)
        }

        let sameRowOrCol = sel.row == row || sel.col == col
        let sameBlock = sel.row / 3 == row / 3 && sel.col / 3 == col / 3
        if sameRowOrCol || sameBlock {
            return Color.blue.opacity(0.08)
        }

        return .clear
    }

    private func gridLines(size: CGFloat) -> some View {
        let cell = size / 9
        return ZStack {
            ForEach(0...9, id: \.self) { i in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: CGFloat(i) * cell))
                    path.addLine(to: CGPoint(x: size, y: CGFloat(i) * cell))
                }
                .stroke(Color.primary.opacity(i % 3 == 0 ? 0.8 : 0.25), lineWidth: i % 3 == 0 ? 2 : 0.5)

                Path { path in
                    path.move(to: CGPoint(x: CGFloat(i) * cell, y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(i) * cell, y: size))
                }
                .stroke(Color.primary.opacity(i % 3 == 0 ? 0.8 : 0.25), lineWidth: i % 3 == 0 ? 2 : 0.5)
            }
        }
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
