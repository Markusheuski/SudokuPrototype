import SwiftUI

struct NumberPadView: View {
    @ObservedObject var game: GameState
    @Environment(\.palette) private var palette

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...9, id: \.self) { number in
                    numberButton(number)
                }
            }

            HStack(spacing: 8) {
                pencilButton
                clearButton
            }
        }
    }

    private func numberButton(_ number: Int) -> some View {
        let isExcluded = game.selected.map { game.excludedDigits[$0.row][$0.col].contains(number) } ?? false
        let isNoted = game.selected.map { game.notes[$0.row][$0.col].contains(number) } ?? false
        let isFilled = game.placedCount(of: number) == 9

        return Button {
            game.enter(value: number)
        } label: {
            Text("\(number)")
                .font(.title2)
                .strikethrough(isExcluded)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(isNoted && game.isPencilMode ? palette.accent : nil)
        .foregroundColor(isFilled ? Color.secondary : (isExcluded ? Color.red.opacity(0.5) : nil))
        .disabled(game.selected == nil || isExcluded || isFilled)
    }

    private var pencilButton: some View {
        Button {
            game.togglePencilMode()
        } label: {
            Image(systemName: "pencil")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(game.isPencilMode ? palette.accent : nil)
    }

    private var clearButton: some View {
        Button {
            game.clearSelected()
        } label: {
            Image(systemName: "delete.left")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .disabled(game.selected == nil)
    }
}
