import SwiftUI

struct StartView: View {
    @ObservedObject var theme: ThemeManager
    let onStart: () -> Void

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("SUDOKU")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .tracking(2)
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
                .font(.title.bold())
                .padding(.horizontal, 48)
                .padding(.vertical, 20)
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
