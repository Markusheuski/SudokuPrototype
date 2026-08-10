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
        let isFilled = game.mode == .classic && game.placedCount(of: number) == 9
        let isActiveNote = isNoted && game.isPencilMode

        return Button {
            game.enter(value: number)
        } label: {
            Text("\(number)")
                .font(.title2.weight(.medium))
                .monospacedDigit()
                .strikethrough(isExcluded)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundColor(padTextColor(isFilled: isFilled, isExcluded: isExcluded, isActiveNote: isActiveNote))
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                        .fill(isActiveNote ? palette.accent : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                        .stroke(palette.border, lineWidth: 0.5)
                )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(game.selected == nil || isExcluded || isFilled)
    }

    private func padTextColor(isFilled: Bool, isExcluded: Bool, isActiveNote: Bool) -> Color {
        if isFilled { return .secondary }
        if isExcluded { return .red.opacity(0.5) }
        if isActiveNote { return .white }
        return .primary
    }

    private var pencilButton: some View {
        Button {
            game.togglePencilMode()
        } label: {
            Image(systemName: "pencil")
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundColor(game.isPencilMode ? .white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                        .fill(game.isPencilMode ? palette.accent : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                        .stroke(palette.border, lineWidth: 0.5)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var clearButton: some View {
        Button {
            game.clearSelected()
        } label: {
            Image(systemName: "delete.left")
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundColor(.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                        .stroke(palette.border, lineWidth: 0.5)
                )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(game.selected == nil)
    }
}
