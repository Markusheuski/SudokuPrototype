import SwiftUI

struct NumberPadView: View {
    @ObservedObject var game: GameState

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

        return Button {
            game.enter(value: number)
        } label: {
            Text("\(number)")
                .font(.title2)
                .strikethrough(isExcluded)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(isNoted && game.isPencilMode ? Color.accentColor : nil)
        .foregroundColor(isExcluded ? Color.red.opacity(0.5) : nil)
        .disabled(game.selected == nil || isExcluded)
    }

    private var pencilButton: some View {
        Button {
            game.togglePencilMode()
        } label: {
            Image(systemName: "pencil")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(game.isPencilMode ? Color.accentColor : nil)
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
