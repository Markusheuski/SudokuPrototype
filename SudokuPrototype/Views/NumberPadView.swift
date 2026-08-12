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
        let isEnabled = game.selected != nil && !isExcluded && !isFilled

        return PadButton(isEnabled: isEnabled) {
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
    }

    private func padTextColor(isFilled: Bool, isExcluded: Bool, isActiveNote: Bool) -> Color {
        if isFilled { return .secondary }
        if isExcluded { return .red.opacity(0.5) }
        if isActiveNote { return .white }
        return .primary
    }

    private var pencilButton: some View {
        PadButton(isEnabled: true) {
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
    }

    private var clearButton: some View {
        PadButton(isEnabled: game.selected != nil) {
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
    }
}

/// A tap target styled like a `Button` but driven by a raw `DragGesture`
/// instead of SwiftUI's `Button`/`ButtonStyle` machinery — the same
/// approach BoardView's cells use via `.onTapGesture`, which has never
/// dropped a tap on device. The `Button` + `.disabled(...)` + custom
/// `ButtonStyle` combo these pad buttons used to use did, intermittently,
/// with zero visual response, which lines up with a known SwiftUI quirk:
/// a `Button`'s gesture recognizer can get rebuilt (and briefly miss a
/// touch) when its `.disabled(...)` predicate is recomputed on every
/// parent redraw — and NumberPadView redraws on every `@Published` change
/// to the shared GameState (select, enter, pencil toggle, mistakes...).
private struct PadButton<Label: View>: View {
    let isEnabled: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isPressed = false

    var body: some View {
        label()
            .frame(maxWidth: .infinity, minHeight: 44)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if isEnabled { isPressed = true }
                    }
                    .onEnded { _ in
                        if isPressed && isEnabled { action() }
                        isPressed = false
                    }
            )
    }
}
