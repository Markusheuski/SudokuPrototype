import SwiftUI

struct NumberPadView: View {
    @ObservedObject var game: GameState

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { number in
                    numberButton(number)
                }
            }
            HStack(spacing: 8) {
                ForEach(6...9, id: \.self) { number in
                    numberButton(number)
                }
                clearButton
            }
        }
    }

    private func numberButton(_ number: Int) -> some View {
        Button {
            game.enter(value: number)
        } label: {
            Text("\(number)")
                .font(.title2)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .disabled(game.selected == nil)
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
