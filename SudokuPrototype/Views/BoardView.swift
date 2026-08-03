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
        let isSelected = game.selected.map { $0.row == row && $0.col == col } ?? false
        let isWrong = game.isCellWrong(row: row, col: col)

        Text(value == 0 ? "" : "\(value)")
            .font(.system(size: cellSize * 0.5, weight: isGiven ? .bold : .regular))
            .foregroundColor(isWrong ? .red : (isGiven ? .primary : .blue))
            .frame(width: cellSize, height: cellSize)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { game.select(row: row, col: col) }
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
