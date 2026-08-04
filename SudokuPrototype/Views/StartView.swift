import SwiftUI

struct StartView: View {
    @ObservedObject var theme: ThemeManager
    let onStart: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 32) {
                Spacer()

                Text("Судоку")
                    .font(.system(size: 48, weight: .bold))

                Button("Начать игру") {
                    onStart()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()
            }

            ThemeToggleButton(theme: theme)
                .padding()
        }
    }
}

#Preview {
    StartView(theme: ThemeManager()) {}
}
