import SwiftUI

struct StartView: View {
    @ObservedObject var theme: ThemeManager
    let onStart: () -> Void

    var body: some View {
        ZStack {
            VStack {
                Text("Судоку")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 24)
                Spacer()
            }

            VStack {
                Spacer()
                Button("Начать игру") {
                    onStart()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Spacer()
            }

            VStack {
                HStack {
                    Spacer()
                    ThemeToggleButton(theme: theme)
                }
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    StartView(theme: ThemeManager()) {}
}
