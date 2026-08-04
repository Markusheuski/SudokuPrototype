import SwiftUI

struct StartView: View {
    @ObservedObject var theme: ThemeManager
    let onStart: () -> Void

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Sudoku")
                        .font(.system(size: 40, weight: .bold))
                    Spacer()
                    ThemeToggleButton(theme: theme)
                }
                .padding()
                Spacer()
            }

            VStack {
                Spacer()
                Button("Start Game") {
                    onStart()
                }
                .font(.title2.bold())
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Spacer()
            }
        }
    }
}

#Preview {
    StartView(theme: ThemeManager()) {}
}
